# ZeroHub - Windows Uninstaller
$ErrorActionPreference = "SilentlyContinue"

# Check for admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "This uninstaller must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host ""
Write-Host "ZeroHub Windows Uninstaller" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host ""

# Stop and remove scheduled task
Write-Host "Stopping service..." -ForegroundColor Yellow
Stop-ScheduledTask -TaskName "ZeroHub Listener Service" -ErrorAction SilentlyContinue
Get-Process powershell | Where-Object { $_.CommandLine -match "usbip-listener" } | Stop-Process -Force -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "ZeroHub Listener Service" -Confirm:$false -ErrorAction SilentlyContinue
# Also clean up old task name if present
Unregister-ScheduledTask -TaskName "USBip Auto-Attach Listener" -Confirm:$false -ErrorAction SilentlyContinue
Write-Host "  ✓ Service stopped and removed" -ForegroundColor Green

# Stop tray app
Write-Host "Stopping tray app..." -ForegroundColor Yellow
Get-Process electron -ErrorAction SilentlyContinue | Stop-Process -Force
Get-Process "ZeroHub*" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "  ✓ Tray app stopped" -ForegroundColor Green

# Remove startup shortcut
Write-Host "Removing startup shortcut..." -ForegroundColor Yellow
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ZeroHub Listener.lnk" -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ Startup shortcut removed" -ForegroundColor Green

# Remove files
Write-Host "Removing files..." -ForegroundColor Yellow
Remove-Item "$env:USERPROFILE\Documents\ZeroHub" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files\ZeroHub" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\zerohub-listener" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "HKLM:\SOFTWARE\ZeroHub" -Force -ErrorAction SilentlyContinue
Write-Host "  ✓ Files removed" -ForegroundColor Green

# Detach all USB/IP devices
Write-Host "Detaching USB/IP devices..." -ForegroundColor Yellow
$USBIP_EXE = "C:\Program Files\USBip\usbip.exe"
if (Test-Path $USBIP_EXE) {
    $output = & $USBIP_EXE port 2>&1
    $output | ForEach-Object {
        if ($_ -match 'Port\s+(\d+):') {
            & $USBIP_EXE detach -p $matches[1] 2>&1 | Out-Null
        }
    }
}
Write-Host "  ✓ Devices detached" -ForegroundColor Green

# Remove log
Remove-Item "$env:USERPROFILE\zerohub-listener.log" -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "ZeroHub has been uninstalled." -ForegroundColor Green
Write-Host ""
Write-Host "Note: usbip-win2 driver was NOT removed. To remove it:" -ForegroundColor Yellow
Write-Host "  Go to Settings > Apps > Installed apps > usbip-win2 > Uninstall" -ForegroundColor Yellow
Write-Host ""
pause
