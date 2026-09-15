#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "$ROOT/install.sh" "$ROOT"/bin/orca-{kimi,terra,init} "$ROOT/bin/dsh-orca"
python3 - "$ROOT/bin/orca-supervisor" <<'PY'
from pathlib import Path
import sys
compile(Path(sys.argv[1]).read_text(), sys.argv[1], "exec")
PY

test -x "$ROOT/install.sh"
test -x "$ROOT/smoke-test.sh"
test -x "$ROOT/bin/orca-supervisor"

if grep -RIEq '/home/[^/]+|/Users/[^/]+|gh[pousr]_[[:alnum:]]{20,}|sk-[[:alnum:]_-]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*[^$<[:space:]]+' \
  "$ROOT/bin" "$ROOT/skill" "$ROOT/README.md"; then
  echo 'FAIL: possible personal path or secret found' >&2
  exit 1
fi

echo 'SMOKE_TEST: PASS'
