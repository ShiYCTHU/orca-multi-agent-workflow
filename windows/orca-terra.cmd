@echo off
set ORCA_SUPERVISOR_MODE=1
codex -m gpt-5.6-terra -a never -s danger-full-access %*
