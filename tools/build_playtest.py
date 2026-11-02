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
import zipfile

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / 'build'
SOURCE = BUILD / 'playtest-ci-source'
OUTPUT = BUILD / 'AdriaticUprising_Playtest_Win64'
ZIP = BUILD / 'AdriaticUprising_Playtest_Win64.zip'
EXE = 'AdriaticUprising_Playtest.exe'
TESTS = ('ship_status', 'upgrade_toggle', 'weapon_system', 'destruction', 'reactive_armor', 'campaign_save')
PLAYTEST_USER_DIR = 'AdriaticUprising/Playtest'


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


def run_godot(godot, label, *args):
    result = subprocess.run([godot, '--headless', '--path', str(SOURCE),
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
    run_godot(godot, 'import', '--editor', '--quit')
    for name in TESTS:
        output = run_godot(godot, name, '--script', f'res://tests/{name}_test.gd')
        assert re.search(r'QA: \d+ checks, 0 failures', output), f'No passing summary: {name}'
    # Only copied test files in this script's fixed staging folder are removed.
    shutil.rmtree(tests)
    run_godot(godot, 'export', '--export-release', 'Windows Desktop', str(OUTPUT / EXE))
    assert (OUTPUT / EXE).stat().st_size > 0


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
    """Run external QA scripts against the real exported pack, never ship them."""
    assert os.environ.get('GITHUB_ACTIONS') == 'true', 'Requires disposable GitHub runner'
    with tempfile.TemporaryDirectory(prefix='adriatic-save-qa-') as temp:
        destination = Path(temp)
        for file in OUTPUT.iterdir():
            shutil.copy2(file, destination / file.name)
        for phase in ('all', 'write', 'read'):
            profile = destination / ('all-profile' if phase == 'all' else 'restart-profile')
            log = destination / f'{phase}.log'
            result = subprocess.run([
                str(destination / EXE), '--headless', '--log-file', str(log),
                '--script', str(ROOT / 'tests/campaign_save_test.gd'), '--',
                f'--save-test-dir={profile}', f'--phase={phase}'], cwd=destination,
                capture_output=True, timeout=120)
            result.check_returncode()
            text = log.read_text(encoding='utf-8')
            (BUILD / f'playtest-exported-save-{phase}.log').write_text(text, encoding='utf-8')
            assert re.search(r'CAMPAIGN SAVE QA: \d+ checks, 0 failures', text), text
            assert not re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:|FAIL:', text), text
    print('Exported EXE: fresh save, confirmation/cancel, Continue and process restart passed.')


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
