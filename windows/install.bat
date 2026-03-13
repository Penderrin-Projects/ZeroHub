@echo off
title ZeroHub Windows Installer

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo.
echo ============================================
echo   ZeroHub Windows Installer
echo ============================================
echo.

:: Check for usbip-win2
if not exist "C:\Program Files\USBip\usbip.exe" (
    echo ERROR: usbip-win2 is not installed.
    echo.
    echo Please install it first:
    echo   1. Go to: https://github.com/cezuni/usbip-win2/releases
    echo   2. Download the latest .msi file
    echo   3. Install it and restart your PC
    echo   4. Run this installer again
    echo.
    pause
    exit /b 1
)

:: Run the PowerShell installer
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
