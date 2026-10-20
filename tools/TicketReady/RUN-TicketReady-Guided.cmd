@echo off
setlocal
title TicketReady - Guided Support Report
echo.
echo TicketReady v0.2 - Guided Windows support report
echo Offline, read-only and saved to Documents\TicketReady Reports.
echo.
echo Choose the problem you are investigating:
echo   1. General Windows issue
echo   2. Slow computer
echo   3. Low disk space / storage
echo   4. Network connection
echo   5. Windows updates
echo.
choice /C 12345 /N /M "Choose 1-5: "
if errorlevel 5 set "ISSUE=Updates"&goto run
if errorlevel 4 set "ISSUE=Network"&goto run
if errorlevel 3 set "ISSUE=Storage"&goto run
if errorlevel 2 set "ISSUE=SlowPC"&goto run
set "ISSUE=General"
:run
echo.
echo Running local checks for: %ISSUE%
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TicketReady.ps1" -Issue "%ISSUE%"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo Report could not be completed. Exit code: %RESULT%
if "%RESULT%"=="0" echo Your reports are in Documents\TicketReady Reports.
pause
exit /b %RESULT%
