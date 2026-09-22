#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash -n "$ROOT/install.sh" "$ROOT"/bin/orca-{kimi,terra,init,supervise-ui} "$ROOT/bin/dsh-orca"
python3 - "$ROOT/bin/orca-supervisor" "$ROOT/bin/orca-progress" "$ROOT/bin/orca-dashboard" "$ROOT/bin/orca-role-config" "$ROOT/bin/orca-dsh-executor" "$ROOT/bin/orca-claude-reviewer" <<'PY'
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import types
from types import SimpleNamespace

path = Path(sys.argv[1])
for script in sys.argv[1:]:
    compile(Path(script).read_text(), script, "exec")

fake_msvcrt = types.ModuleType("msvcrt")
fake_msvcrt.LK_NBLCK = 1
fake_msvcrt.locking = lambda *args: None
real_os_name = os.name
sys.modules["msvcrt"] = fake_msvcrt
os.name = "nt"
try:
    windows_namespace = {"__name__": "windows_import_test"}
    exec(compile(path.read_text(), str(path), "exec"), windows_namespace)
finally:
    os.name = real_os_name
    del sys.modules["msvcrt"]
assert "fcntl" not in windows_namespace
assert windows_namespace["msvcrt"] is fake_msvcrt

namespace = {"__name__": "smoke_test"}
exec(compile(path.read_text(), str(path), "exec"), namespace)
assert namespace["orca_cli_name"]() == "orca-ide"
prompt = namespace["coordinator_prompt"](
    "run_smoke",
    "/project",
    "ORCA_EVENT",
    "contract_version: test\nfrozen_routing: claude -> dsh",
)
assert "/project/.orca/progress/run_smoke.json" in prompt
assert "Dashboard failure alone is" in prompt and "not Run failure" in prompt
assert "SAME_RUN_RECOVERY and FINALIZATION_INTERRUPTED" in prompt
assert "frozen_routing: claude -> dsh" in prompt
assert "untrusted data" in prompt
command = namespace["kimi_command"]("packet")
for flag in (
    "--strict-mcp-config",
    "--disable-slash-commands",
    "--no-chrome",
    "--no-session-persistence",
):
    assert flag in command

responses = iter((
    '{"result":{"run":{"id":"run_smoke","status":"active"}}}',
    '{"result":{"tasks":[{"id":"task_1","status":"active"}]}}',
    '{"result":{"workers":[{"dispatch_id":"ctx_1","terminal_state":"active"}]}}',
))
real_run = namespace["subprocess"].run
namespace["subprocess"].run = lambda *args, **kwargs: SimpleNamespace(
    returncode=0,
    stdout=next(responses),
    stderr="",
)
with tempfile.TemporaryDirectory() as project:
    packet = namespace["coordinator_packet"](
        "run_smoke",
        project,
        "ORCA_EVENT",
        "worker_done",
        {"executor": "claude", "reviewer": "dsh", "source": "snapshot"},
    )
namespace["subprocess"].run = real_run
for expected in ("task_1", "ctx_1", "worker_done", "manifest: missing"):
    assert expected in packet

with tempfile.TemporaryDirectory() as directory:
    lock_path = Path(directory) / "supervisor.lock"
    with lock_path.open("w+") as first, lock_path.open("r+") as second:
        assert namespace["acquire_supervisor_lock"](first)
        assert not namespace["acquire_supervisor_lock"](second)

class FakeMsvcrt:
    LK_NBLCK = 1
    calls = []

    @classmethod
    def locking(cls, *args):
        cls.calls.append(args)

real_os_name = namespace["os"].name
namespace["msvcrt"] = FakeMsvcrt
namespace["os"].name = "nt"
try:
    with tempfile.TemporaryFile(mode="w+") as lock_file:
        assert namespace["acquire_supervisor_lock"](lock_file)
finally:
    namespace["os"].name = real_os_name
assert FakeMsvcrt.calls

os.environ["ORCA_CLI_COMMAND"] = "custom-orca"
assert namespace["orca_cli_name"]() == "custom-orca"
del os.environ["ORCA_CLI_COMMAND"]

supervisor_source = path.read_text()

assert 'supervisor-v1.1.lock' in supervisor_source
assert 'fcntl.LOCK_EX | fcntl.LOCK_NB' in supervisor_source
assert 'msvcrt.LK_NBLCK' in supervisor_source
assert 'if args.recovery_kick:' in supervisor_source
assert 'if not args.no_initial_kick:' not in supervisor_source
assert '--recovery-kick' in supervisor_source
assert '--strict-mcp-config' in Path(sys.argv[1]).with_name("orca-kimi").read_text()
assert 'cmd = kimi_command(bootstrap)' in supervisor_source
assert 'prompt_path.unlink()' in supervisor_source
assert 'cwd=state_dir' in supervisor_source
windows_ui = path.parents[1] / "windows" / "orca-supervise-ui.ps1"
assert '--check-binding' in windows_ui.read_text()
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
test -x "$ROOT/bin/orca-role-config"
test -x "$ROOT/bin/orca-dsh-executor"
test -x "$ROOT/bin/orca-claude-reviewer"
test -f "$ROOT/windows/orca-role-config.cmd"
test -f "$ROOT/windows/orca-dsh-executor.cmd"
test -f "$ROOT/windows/orca-claude-reviewer.cmd"

if grep -RIEq '/home/[^/]+|/Users/[^/]+|gh[pousr]_[[:alnum:]]{20,}|sk-[[:alnum:]_-]{20,}|AKIA[0-9A-Z]{16}|(api[_-]?key|token|secret|password)[[:space:]]*[:=][[:space:]]*[^$<[:space:]]+' \
  "$ROOT/bin" "$ROOT/windows" "$ROOT/skill" "$ROOT/README.md" "$ROOT/install.ps1"; then
  echo 'FAIL: possible personal path or secret found' >&2
  exit 1
fi

echo 'SMOKE_TEST: PASS'
