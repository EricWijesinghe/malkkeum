"""Release workflow rules that a diff can break silently.

  python -I scripts/release/check_workflows.py          (exit 1 on any violation)

Rules, for every .github/workflows/*.yml:
  1. Third-party actions are pinned to a full 40-character commit SHA (local ./ actions and docker:// excepted).
  2. The file declares a top-level `permissions:` block (default deny per job).
Rules for release.yml only:
  3. Each publishing job (PUBLISH_JOBS) declares an `environment:`, so GitHub's protection rules apply to it.
"""

import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
PUBLISH_JOBS = ("images", "delivery")
USES = re.compile(r"^\s*(?:-\s+)?uses:\s*['\"]?([^\s'\"#]+)")
PINNED = re.compile(r"^[^@\s]+@[0-9a-f]{40}$")
JOB_LINE = re.compile(r"^  ([a-z][a-z0-9-]*):\s*$")


def _jobs(lines):
    """Returns {job name: [lines of that job]} from the `jobs:` block."""
    jobs, current, in_jobs = {}, None, False
    for line in lines:
        if line.startswith("jobs:"):
            in_jobs = True
            continue
        if not in_jobs:
            continue
        if line and not line.startswith((" ", "#")):
            break  # a new top-level key after jobs (none today; keeps the parse honest)
        match = JOB_LINE.match(line)
        if match:
            current = match.group(1)
            jobs[current] = []
        elif current is not None:
            jobs[current].append(line)
    return jobs


def problems(path):
    text = pathlib.Path(path).read_text(encoding="utf-8")
    lines = text.splitlines()
    name = pathlib.Path(path).name
    found = []
    if not any(line.startswith("permissions:") for line in lines):
        found.append(f"{name}: no top-level permissions block")
    for lineno, line in enumerate(lines, 1):
        match = USES.match(line)
        if not match:
            continue
        ref = match.group(1)
        if ref.startswith("./") or ref.startswith("docker://"):
            continue
        if not PINNED.match(ref):
            found.append(f"{name}:{lineno}: action '{ref}' is not pinned to a 40-character commit SHA")
    if name == "release.yml":
        jobs = _jobs(lines)
        for job in PUBLISH_JOBS:
            if job not in jobs:
                found.append(f"{name}: publishing job '{job}' is missing")
            elif not any(re.match(r"^    environment:", line) for line in jobs[job]):
                found.append(f"{name}: publishing job '{job}' declares no environment")
    return found


def main():
    files = sorted((ROOT / ".github" / "workflows").glob("*.yml"))
    if not files:
        print("no workflow files found", file=sys.stderr)
        return 1
    found = []
    for path in files:
        found += problems(path)
    for line in found:
        print(line)
    print(f"checked {len(files)} workflow files: {'OK' if not found else f'{len(found)} problem(s)'}")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
