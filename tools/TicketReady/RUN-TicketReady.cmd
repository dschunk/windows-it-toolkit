@echo off
setlocal
title TicketReady - Windows Support Report
echo.
echo TicketReady - Read-only Windows support report
echo No installer, cloud account, elevation or data upload.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TicketReady.ps1"
set "result=%ERRORLEVEL%"
echo.
if not "%result%"=="0" echo TicketReady could not complete. Code: %result%
if "%result%"=="0" echo Your reports are in Documents\TicketReady Reports.
echo.
pause
exit /b %result%
