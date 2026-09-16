@echo off
set ORCA_SUPERVISOR_MODE=1
set ORCA_CLI_COMMAND=orca
codex -m gpt-5.6-terra -a never -s danger-full-access %*
