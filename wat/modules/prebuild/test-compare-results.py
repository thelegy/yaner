import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("compare-results.py")
spec = importlib.util.spec_from_file_location("compare_results", SCRIPT)
compare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compare)


def report(**hosts):
    return {
        "version": 1,
        "status": "complete",
        "hosts": {host: {"status": status} for host, status in hosts.items()},
    }


class CompareResultsTest(unittest.TestCase):
    def test_regression_policy(self):
        success = report(a="success", b="success")
        mixed = report(a="success", b="build-failed")
        for current, previous, allowed in [
            (success, None, True),
            (mixed, None, False),
            (mixed, mixed, True),
            (success, mixed, True),
            (mixed, success, False),
            (report(a="success"), mixed, False),
            (report(a="success", b="build-failed", c="success"), mixed, True),
        ]:
            with self.subTest(current=current, previous=previous):
                self.assertEqual(compare.allows_update(current, previous), allowed)

    def test_invalid_reports(self):
        for value in [
            {}, [], report(), report(a="incomplete"), report(a="unknown"),
            {**report(a="success"), "status": "incomplete"},
            {**report(a="success"), "version": 2},
        ]:
            with self.subTest(value=value), self.assertRaises(ValueError):
                compare.load_report(json.dumps(value))

    def test_transient_reasons_do_not_affect_comparison(self):
        value = report(a="build-failed")
        value["hosts"]["a"]["reason"] = "transient log path"
        self.assertEqual(compare.load_report(json.dumps(value)), report(a="build-failed"))

    def test_cli_migration_and_failure_codes(self):
        with tempfile.TemporaryDirectory() as directory:
            current = Path(directory) / "current.json"
            previous = Path(directory) / "previous.json"

            def run():
                return subprocess.run(
                    [sys.executable, str(SCRIPT), str(current), str(previous)],
                    capture_output=True, text=True,
                )

            previous.write_text("0 SUCCESS old-target\n")
            current.write_text(json.dumps(report(a="success")))
            result = run()
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), report(a="success"))
            current.write_text(json.dumps(report(a="build-failed")))
            self.assertEqual(run().returncode, 1)
            previous.write_text(current.read_text())
            self.assertEqual(run().returncode, 0)
            current.write_text("{")
            self.assertEqual(run().returncode, 2)
            current.unlink()
            self.assertEqual(run().returncode, 2)


if __name__ == "__main__":
    unittest.main()
