@echo off
python "%~dp0orca-role-config.py" %*
exit /b %ERRORLEVEL%
