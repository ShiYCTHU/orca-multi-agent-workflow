@echo off
python "%~dp0orca-claude-reviewer.py" %*
exit /b %ERRORLEVEL%
