"""Build an allowlisted game copy without modifying the project or player saves."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
SOURCE = BUILD / 'playtest-ci-source'
OUTPUT = BUILD / 'AdriaticUprising_Playtest_Win64'
ZIP = BUILD / 'AdriaticUprising_Playtest_Win64.zip'
EXE = 'AdriaticUprising_Playtest.exe'
TESTS = ('ship_status', 'upgrade_toggle', 'weapon_system', 'destruction', 'reactive_armor', 'campaign_save')
PLAYTEST_USER_DIR = 'AdriaticUprising/Playtest'
QA_SOURCE = BUILD / 'playtest-save-qa-source'
QA_OUTPUT = BUILD / 'playtest-save-qa'
QA_EXE = 'AdriaticUprising_SaveQA.exe'


def prepare():
    # Fail instead of mixing older build products with this revision.
    SOURCE.mkdir(parents=True, exist_ok=False)
    OUTPUT.mkdir(parents=True, exist_ok=False)
    for name in ('main.gd', 'main.gd.uid', 'main.tscn', 'export_presets.cfg'):
        shutil.copy2(ROOT / name, SOURCE / name)
    config = (ROOT / 'project.godot').read_text(encoding='utf-8')
    for section in ('autoload', 'editor_plugins'):
        config = re.sub(r'(?ms)^\[' + section + r'\].*?(?=^\[|\Z)', '', config)
    assert 'addons/' not in config, 'Unexpected plugin dependency'
    # Only the export copy changes user://. Never migrate developer campaign data.
    config = re.sub(r'(?m)^config/(?:use_custom_user_dir|custom_user_dir_name)=.*\n?', '', config)
    config = config.replace('[application]', '[application]\n\nconfig/use_custom_user_dir=true\n'
                            f'config/custom_user_dir_name="{PLAYTEST_USER_DIR}"')
    (SOURCE / 'project.godot').write_text(config, encoding='utf-8')
    preset_path = SOURCE / 'export_presets.cfg'
    preset = preset_path.read_text(encoding='utf-8')
    assert 'binary_format/architecture="x86_64"' in preset
    assert 'binary_format/embed_pck=true' in preset
    preset = preset.replace('export_filter="all_resources"',
                            'export_filter="scenes"\nexport_files=PackedStringArray("res://main.tscn")')
    preset = preset.replace('exclude_filter=""',
                            'exclude_filter="tests/*,addons/*,tools/*,build/*,'
                            'campaign_save.cfg,*/campaign_save.cfg,highscores.cfg,*/highscores.cfg,'
                            'controls.cfg,*/controls.cfg"')
    preset = preset.replace('Adriatic Uprising - Croatia campaign', 'Adriatic Uprising - Windows Playtest')
    preset = preset.replace('[preset.0.options]', 'script_export_mode=2\n\n[preset.0.options]')
    preset_path.write_text(preset, encoding='utf-8')
    # Review the allowlist explicitly when assets/dependencies are introduced.
    script = (SOURCE / 'main.gd').read_text(encoding='utf-8')
    assert not re.search(r'res://[^\s"\']+', script), 'Review new game asset dependencies'
    for definition in ('const MAX_LEVEL := 50', 'const CROATIA_FINAL_LEVEL := 25',
                       'const BOSNIA_START_LEVEL := 26', 'const BOSNIA_FINAL_LEVEL := 50'):
        assert definition in script, f'Campaign invariant missing: {definition}'
    assert (ROOT / 'main.gd').read_bytes() == (SOURCE / 'main.gd').read_bytes()


def run_godot(godot, label, *args, project=None):
    result = subprocess.run([godot, '--headless', '--path', str(project or SOURCE),
                             '--log-file', str(BUILD / f'playtest-{label}.log'), *args],
                            capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=240)
    print(result.stdout, end='')
    print(result.stderr, end='')
    result.check_returncode()
    text = result.stdout + result.stderr
    if re.search(r'SCRIPT ERROR:|Parse Error:|FAIL:|^ERROR:', text, re.M):
        raise RuntimeError(f'{label}: Godot reported an error despite exit code 0')
    return text


def build(godot):
    version = subprocess.check_output([godot, '--version'], text=True).strip()
    assert version.startswith('4.7.2.stable.'), version
    prepare()
    tests = SOURCE / 'tests'
    tests.mkdir()
    for name in TESTS:
        shutil.copy2(ROOT / 'tests' / f'{name}_test.gd', tests)
    shutil.copy2(ROOT / 'tests/campaign_save_suite.gd', tests)
    run_godot(godot, 'import', '--editor', '--quit')
    for name in TESTS:
        output = run_godot(godot, name, '--script', f'res://tests/{name}_test.gd')
        assert re.search(r'QA: \d+ checks, 0 failures', output), f'No passing summary: {name}'
    # Only copied test files in this script's fixed staging folder are removed.
    shutil.rmtree(tests)
    run_godot(godot, 'export', '--export-release', 'Windows Desktop', str(OUTPUT / EXE))
    assert (OUTPUT / EXE).stat().st_size > 0
    prepare_save_qa()
    run_godot(godot, 'qa-import', '--editor', '--quit', project=QA_SOURCE)
    run_godot(godot, 'qa-export', '--export-release', 'Windows Desktop',
              str(QA_OUTPUT / QA_EXE), project=QA_SOURCE)
    assert (QA_OUTPUT / QA_EXE).stat().st_size > 0


def prepare_save_qa():
    """Same game and release template, with a test main scene in a separate export."""
    QA_SOURCE.mkdir(parents=True, exist_ok=False)
    QA_OUTPUT.mkdir(parents=True, exist_ok=False)
    for name in ('main.gd', 'main.gd.uid', 'main.tscn', 'project.godot', 'export_presets.cfg'):
        shutil.copy2(SOURCE / name, QA_SOURCE / name)
    tests = QA_SOURCE / 'tests'
    tests.mkdir()
    for name in ('campaign_save_suite.gd', 'campaign_save_qa.tscn'):
        shutil.copy2(ROOT / 'tests' / name, tests / name)
    config_path = QA_SOURCE / 'project.godot'
    config = config_path.read_text(encoding='utf-8').replace(
        'run/main_scene="res://main.tscn"', 'run/main_scene="res://tests/campaign_save_qa.tscn"')
    config = config.replace(f'config/custom_user_dir_name="{PLAYTEST_USER_DIR}"',
                            f'config/custom_user_dir_name="{PLAYTEST_USER_DIR}-SaveQA"')
    config_path.write_text(config, encoding='utf-8')
    preset_path = QA_SOURCE / 'export_presets.cfg'
    preset = preset_path.read_text(encoding='utf-8').replace(
        'export_files=PackedStringArray("res://main.tscn")',
        'export_files=PackedStringArray("res://tests/campaign_save_qa.tscn", "res://main.tscn")')
    preset = preset.replace('exclude_filter="tests/*,', 'exclude_filter="')
    preset_path.write_text(preset, encoding='utf-8')
    assert (QA_SOURCE / 'main.gd').read_bytes() == (SOURCE / 'main.gd').read_bytes()


def smoke():
    # No source files or --path argument. Only CI may use a disposable user profile.
    assert os.environ.get('GITHUB_ACTIONS') == 'true', 'Smoke requires disposable GitHub runner'
    with tempfile.TemporaryDirectory(prefix='adriatic-playtest-') as temp:
        destination = Path(temp)
        for file in OUTPUT.iterdir():
            shutil.copy2(file, destination / file.name)
        log = destination / 'launch.log'
        result = subprocess.run([str(destination / EXE), '--headless', '--quit-after', '120',
                                 '--log-file', str(log)], cwd=destination,
                                capture_output=True, timeout=120)
        result.check_returncode()
        text = log.read_text(encoding='utf-8')
        assert 'Godot Engine v4.7.2.stable.' in text, 'Engine startup not confirmed'
        assert not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:', text), text
        (BUILD / 'playtest-launch.log').write_text(text, encoding='utf-8')
    print('Clean headless EXE startup passed; interactive testing still required.')


def verify_saves():
    """Run the compiled QA main scene; release templates ignore external --script."""
    destination = BUILD / 'playtest-save-qa-runs' / uuid.uuid4().hex
    destination.mkdir(parents=True, exist_ok=False)
    # Retain profiles and logs, including on timeout, for diagnosis. Never distribute them.
    for file in QA_OUTPUT.iterdir():
        shutil.copy2(file, destination / file.name)
    for phase, count in (('all', 67), ('write', 1), ('read', 2)):
        profile = destination / ('all-profile' if phase == 'all' else 'restart-profile')
        log = destination / f'{phase}.log'
        stdout = stderr = b''
        try:
            result = subprocess.run([
                str(destination / QA_EXE), '--headless', '--max-fps', '60', '--quit-after', '1800',
                '--log-file', str(log), '--',
                f'--save-test-dir={profile}', f'--phase={phase}'], cwd=destination,
                capture_output=True, timeout=120)
            stdout, stderr = result.stdout, result.stderr
            result.check_returncode()
        except subprocess.TimeoutExpired as error:
            stdout, stderr = error.stdout or b'', error.stderr or b''
            raise RuntimeError(f'Save QA {phase} timed out; diagnostics: {destination}') from error
        finally:
            (destination / f'{phase}-stdout.log').write_bytes(stdout)
            (destination / f'{phase}-stderr.log').write_bytes(stderr)
            text = log.read_text(encoding='utf-8') if log.exists() else ''
            (BUILD / f'playtest-exported-save-{phase}.log').write_text(text, encoding='utf-8')
            print(text, end='', flush=True)
        if not log.exists():
            raise RuntimeError(f'Save QA {phase} did not create a log: {destination}')
        completion = f'CAMPAIGN SAVE QA COMPLETE: phase={phase} checks={count} failures=0'
        if (f'CAMPAIGN SAVE QA BEGIN: phase={phase}' not in text
                or completion not in text
                or re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:|FAIL:', text)):
            raise RuntimeError(f'Save QA {phase} failed or never completed; diagnostics: {destination}')
    print('Release QA scene: fresh New Game, cancel/confirm, Continue and process restart passed.')


def package():
    expected = {EXE, 'README.txt'}
    pck = OUTPUT / 'AdriaticUprising_Playtest.pck'
    if pck.exists():
        expected.add(pck.name)
    shutil.copy2(ROOT / 'packaging' / 'playtest-README.txt', OUTPUT / 'README.txt')
    with (OUTPUT / 'README.txt').open('a', encoding='utf-8') as readme:
        readme.write('\nBuild commit: ' + os.environ.get('GITHUB_SHA', 'local-validation') + '\n')
    actual = {file.name for file in OUTPUT.iterdir()}
    assert actual == expected, f'Unexpected distribution files: {actual ^ expected}'
    executable = (OUTPUT / EXE).read_bytes()
    assert executable[:2] == b'MZ', 'Not a Windows executable'
    offset = struct.unpack_from('<I', executable, 0x3c)[0]
    assert executable[offset:offset + 4] == b'PE\0\0'
    assert struct.unpack_from('<H', executable, offset + 4)[0] == 0x8664, 'Not x86_64'
    with zipfile.ZipFile(ZIP, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in sorted(expected):
            archive.write(OUTPUT / name, name)
    with zipfile.ZipFile(ZIP) as archive:
        assert set(archive.namelist()) == expected
        assert archive.testzip() is None
    print(f'{ZIP}: {ZIP.stat().st_size} bytes; SHA256 {hashlib.sha256(ZIP.read_bytes()).hexdigest()}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('prepare', 'build', 'smoke', 'verify-saves', 'package'))
    parser.add_argument('--godot')
    args = parser.parse_args()
    if args.action == 'build':
        if not args.godot:
            parser.error('build requires --godot')
        build(args.godot)
    else:
        globals()[args.action.replace('-', '_')]()
