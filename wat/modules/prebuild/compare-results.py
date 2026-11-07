"""Compare wat reports; exit 1 for regressions, 2 for an invalid current report."""

import json
import sys
from pathlib import Path


def load_report(text):
    report = json.loads(text)
    if (
        not isinstance(report, dict)
        or type(report.get("version")) is not int
        or report["version"] != 1
        or report.get("status") != "complete"
        or not isinstance(report.get("hosts"), dict)
        or not report["hosts"]
        or any(
            not isinstance(result, dict)
            or result.get("status") not in ("success", "build-failed")
            for result in report["hosts"].values()
        )
    ):
        raise ValueError("expected a complete version 1 wat report")
    # Reasons can contain transient paths and logs. Compare stable outcomes only.
    return {
        "version": 1,
        "status": "complete",
        "hosts": {
            host: {"status": result["status"]}
            for host, result in report["hosts"].items()
        },
    }


def allows_update(current, previous):
    hosts = current["hosts"]
    if previous is None:
        return all(result["status"] == "success" for result in hosts.values())
    return all(
        host in hosts
        and (result["status"] != "success" or hosts[host]["status"] == "success")
        for host, result in previous["hosts"].items()
    )


def main():
    try:
        current = load_report(Path(sys.argv[1]).read_text())
    except (OSError, ValueError) as error:
        print(f"Invalid current build report: {error}", file=sys.stderr)
        return 2
    previous = None
    if len(sys.argv) > 2:
        try:
            previous = load_report(Path(sys.argv[2]).read_text())
        except ValueError:
            print("No compatible baseline; requiring all hosts to succeed", file=sys.stderr)
        except OSError as error:
            print(f"Cannot read baseline report: {error}", file=sys.stderr)
            return 2
    if not allows_update(current, previous):
        print("Build results do not permit an update", file=sys.stderr)
        return 1
    print(json.dumps(current, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    sys.exit(main())
