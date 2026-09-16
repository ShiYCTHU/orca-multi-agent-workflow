#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "$ROOT/install.sh" "$ROOT"/bin/orca-{kimi,terra,init} "$ROOT/bin/dsh-orca"
python3 - "$ROOT/bin/orca-supervisor" <<'PY'
from pathlib import Path
import sys
from tempfile import TemporaryDirectory

path = Path(sys.argv[1])
namespace = {"__name__": "smoke_test"}
exec(compile(path.read_text(), str(path), "exec"), namespace)
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

test -x "$ROOT/install.sh"
test -x "$ROOT/smoke-test.sh"
test -x "$ROOT/bin/orca-supervisor"

if grep -RIEq '/home/[^/]+|/Users/[^/]+|gh[pousr]_[[:alnum:]]{20,}|sk-[[:alnum:]_-]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*[^$<[:space:]]+' \
  "$ROOT/bin" "$ROOT/windows" "$ROOT/skill" "$ROOT/README.md" "$ROOT/install.ps1"; then
  echo 'FAIL: possible personal path or secret found' >&2
  exit 1
fi

echo 'SMOKE_TEST: PASS'
