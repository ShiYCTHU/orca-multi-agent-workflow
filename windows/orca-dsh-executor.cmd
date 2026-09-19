@echo off
python "%~dp0orca-dsh-executor.py" %*
exit /b %ERRORLEVEL%
