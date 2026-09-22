@echo off
set ORCA_SUPERVISOR_MODE=1
set ORCA_CLI_COMMAND=orca
claude --model opus --dangerously-skip-permissions --strict-mcp-config --no-chrome %*
