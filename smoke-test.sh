#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "$ROOT/install.sh" "$ROOT"/bin/orca-{kimi,terra,init,supervise-ui} "$ROOT/bin/dsh-orca"
python3 - "$ROOT/bin/orca-supervisor" "$ROOT/bin/orca-progress" "$ROOT/bin/orca-dashboard" <<'PY'
from pathlib import Path
import os
import sys
from tempfile import TemporaryDirectory

path = Path(sys.argv[1])
for script in sys.argv[1:]:
    compile(Path(script).read_text(), script, "exec")
namespace = {"__name__": "smoke_test"}
exec(compile(path.read_text(), str(path), "exec"), namespace)
assert namespace["orca_cli_name"]() == "orca-ide"
prompt = namespace["coordinator_prompt"]("run_smoke", "/project", "smoke", "")
assert "/project/.orca/progress/run_smoke.json" in prompt
assert "Dashboard failure alone is not" in prompt
os.environ["ORCA_CLI_COMMAND"] = "custom-orca"
assert namespace["orca_cli_name"]() == "custom-orca"
del os.environ["ORCA_CLI_COMMAND"]
with TemporaryDirectory() as directory:
    lock_path = Path(directory) / "supervisor.lock"
    lock = namespace["acquire_lock"](lock_path, "smoke")
    try:
        namespace["acquire_lock"](lock_path, "smoke")
    except SystemExit:
        pass
    else:
        raise AssertionError("duplicate supervisor lock was accepted")
    lock.close()
PY

temporary_project="$(mktemp -d)"
trap 'rm -rf "$temporary_project"' EXIT
printf '%s\n' '{"nodes":[{"id":"setup","label":"Setup"}]}' >"$temporary_project/plan.json"
"$ROOT/bin/orca-progress" init --run smoke --project "$temporary_project" --title Smoke --plan-file "$temporary_project/plan.json" >/dev/null
"$ROOT/bin/orca-progress" patch --run smoke --project "$temporary_project" --node setup --status completed --summary done >/dev/null
"$ROOT/bin/orca-dashboard" --run smoke --project "$temporary_project" --self-test

test -x "$ROOT/install.sh"
test -x "$ROOT/smoke-test.sh"
test -x "$ROOT/bin/orca-supervisor"
test -x "$ROOT/bin/orca-progress"
test -x "$ROOT/bin/orca-dashboard"
test -x "$ROOT/bin/orca-supervise-ui"

if grep -RIEq '/home/[^/]+|/Users/[^/]+|gh[pousr]_[[:alnum:]]{20,}|sk-[[:alnum:]_-]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*[^$<[:space:]]+' \
  "$ROOT/bin" "$ROOT/windows" "$ROOT/skill" "$ROOT/README.md" "$ROOT/install.ps1"; then
  echo 'FAIL: possible personal path or secret found' >&2
  exit 1
fi

echo 'SMOKE_TEST: PASS'
