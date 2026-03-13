@echo off
title ZeroHub Listener
cd /d "%~dp0"

:: Install dependencies if needed
if not exist "node_modules\" (
    echo Installing dependencies...
    call npm install
    if errorlevel 1 (
        echo.
        echo ERROR: npm install failed. Make sure Node.js is installed.
        echo Download from: https://nodejs.org
        pause
        exit /b 1
    )
    echo.
)

:: Start the application
echo Starting ZeroHub Listener...
echo This window can be minimized. The app runs in the system tray.
call npx electron .
pause
