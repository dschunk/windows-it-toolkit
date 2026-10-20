@echo off
setlocal
title TicketReady - Guided Support Report
echo.
echo TicketReady v0.2.2 - Guided Windows support report
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
if errorlevel 6 goto cancel
if errorlevel 5 goto updates
if errorlevel 4 goto network
if errorlevel 3 goto storage
if errorlevel 2 goto slowpc
goto general
:updates
set "ISSUE=Updates"
goto run
:network
set "ISSUE=Network"
goto run
:storage
set "ISSUE=Storage"
goto run
:slowpc
set "ISSUE=SlowPC"
goto run
:general
set "ISSUE=General"
goto run
:cancel
echo Selection cancelled.
exit /b 1
:run
echo.
echo Running local checks for: %ISSUE%
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0TicketReady.ps1" -Issue "%ISSUE%"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo Report could not be completed. Exit code: %RESULT%
if "%RESULT%"=="0" echo Reports saved under Documents\TicketReady Reports.
pause
exit /b %RESULT%
