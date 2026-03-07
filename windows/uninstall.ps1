# ZeroHub - Windows Uninstaller
# Run as Administrator

$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "Uninstalling ZeroHub..." -ForegroundColor Cyan
Write-Host ""

# Stop listener processes
Write-Host "Stopping listener..." -ForegroundColor Yellow
Get-Process powershell | Where-Object {
    try {
        $_.CommandLine -like "*zerohub-listener*" -or $_.CommandLine -like "*usbip-listener*"
    } catch { $false }
} | Stop-Process -Force 2>$null

# Remove scheduled task
Write-Host "Removing scheduled task..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName "ZeroHub Auto-Attach Listener" -Confirm:$false 2>$null
Unregister-ScheduledTask -TaskName "USBip Auto-Attach Listener" -Confirm:$false 2>$null

# Remove firewall rule
Write-Host "Removing firewall rule..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "ZeroHub Listener" 2>$null
Remove-NetFirewallRule -DisplayName "USBipListener" 2>$null

# Detach all USB/IP devices
Write-Host "Detaching USB/IP devices..." -ForegroundColor Yellow
$usbipExe = "C:\Program Files\USBip\usbip.exe"
if (Test-Path $usbipExe) {
    & $usbipExe detach --all 2>$null
}

# Remove install directory
$installDir = "$env:USERPROFILE\Documents\ZeroHub"
if (Test-Path $installDir) {
    Write-Host "Removing install directory..." -ForegroundColor Yellow
    Remove-Item -Path $installDir -Recurse -Force
}

Write-Host ""
Write-Host "ZeroHub uninstalled successfully." -ForegroundColor Green
Write-Host "Note: usbip-win2 was not removed. Uninstall it separately if desired." -ForegroundColor Yellow
Write-Host ""
