@echo off
set ORCA_SUPERVISOR_MODE=1
claude --model opus --dangerously-skip-permissions %*
