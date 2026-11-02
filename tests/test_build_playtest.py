"""Failure handling for release save QA; no Godot process or player saves are used."""
import contextlib
import importlib.util
import io
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class SaveHarnessFailures(unittest.TestCase):
    def setUp(self):
        (ROOT / 'build').mkdir(exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=ROOT / 'build')
        self.addCleanup(self.temporary.cleanup)
        spec = importlib.util.spec_from_file_location('playtest', ROOT / 'tools/build_playtest.py')
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)
        self.module.BUILD = Path(self.temporary.name)
        self.module.QA_OUTPUT = self.module.BUILD / 'qa-export'
        self.module.QA_OUTPUT.mkdir()
        (self.module.QA_OUTPUT / self.module.QA_EXE).write_bytes(b'not executed')

    def run_failure(self, callback, exception=RuntimeError):
        with patch.object(self.module.subprocess, 'run', side_effect=callback):
            with contextlib.redirect_stdout(io.StringIO()), self.assertRaises(exception):
                self.module.verify_saves()

    def test_normal_game_exit_zero_is_not_a_test_pass(self):
        def normal_game(command, **kwargs):
            Path(command[command.index('--log-file') + 1]).write_text('Godot Engine v4.7.2.stable\n')
            return subprocess.CompletedProcess(command, 0, b'normal menu', b'')
        self.run_failure(normal_game)
        self.assertIn('Godot Engine', (self.module.BUILD / 'playtest-exported-save-all.log').read_text())

    def test_timeout_retains_engine_log_and_partial_output(self):
        def timeout(command, **kwargs):
            self.assertEqual(kwargs['timeout'], 120)
            Path(command[command.index('--log-file') + 1]).write_text('CAMPAIGN SAVE QA BEGIN: phase=all\n')
            raise subprocess.TimeoutExpired(command, 120, output=b'partial stdout', stderr=b'partial stderr')
        self.run_failure(timeout)
        run = next((self.module.BUILD / 'playtest-save-qa-runs').iterdir())
        self.assertEqual((run / 'all-stdout.log').read_bytes(), b'partial stdout')
        self.assertEqual((run / 'all-stderr.log').read_bytes(), b'partial stderr')
        self.assertIn('BEGIN', (self.module.BUILD / 'playtest-exported-save-all.log').read_text())

    def test_wrong_phase_completion_is_rejected(self):
        def wrong_phase(command, **kwargs):
            Path(command[command.index('--log-file') + 1]).write_text(
                'CAMPAIGN SAVE QA BEGIN: phase=all\n'
                'CAMPAIGN SAVE QA COMPLETE: phase=read checks=2 failures=0\n')
            return subprocess.CompletedProcess(command, 0, b'', b'')
        self.run_failure(wrong_phase)

    def test_nonzero_exit_keeps_diagnostics(self):
        def failed_process(command, **kwargs):
            Path(command[command.index('--log-file') + 1]).write_text('FAIL: checkpoint\n')
            return subprocess.CompletedProcess(command, 1, b'failed test', b'stderr')
        self.run_failure(failed_process, subprocess.CalledProcessError)
        run = next((self.module.BUILD / 'playtest-save-qa-runs').iterdir())
        self.assertEqual((run / 'all-stdout.log').read_bytes(), b'failed test')
        self.assertEqual((run / 'all-stderr.log').read_bytes(), b'stderr')


if __name__ == '__main__':
    unittest.main()
