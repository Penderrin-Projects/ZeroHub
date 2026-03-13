# ZeroHub - Windows Uninstaller
# Run as Administrator

$ErrorActionPreference = "SilentlyContinue"

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "This uninstaller must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host ""
Write-Host "Uninstalling ZeroHub..." -ForegroundColor Cyan
Write-Host ""

Write-Host "Stopping listener..." -ForegroundColor Yellow
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | ForEach-Object {
    if ($_.CommandLine -match 'usbip-listener|zerohub-listener') { Stop-Process -Id $_.ProcessId -Force }
}
Get-Process "ZeroHub*" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "  Done" -ForegroundColor Green

Write-Host "Removing scheduled tasks..." -ForegroundColor Yellow
Unregister-ScheduledTask -TaskName "ZeroHub Auto-Attach Listener" -Confirm:$false
Unregister-ScheduledTask -TaskName "ZeroHub Listener Service" -Confirm:$false
Unregister-ScheduledTask -TaskName "USBip Auto-Attach Listener" -Confirm:$false
Write-Host "  Done" -ForegroundColor Green

Write-Host "Removing firewall rule..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "ZeroHub Listener"
Remove-NetFirewallRule -DisplayName "USBipListener"
Write-Host "  Done" -ForegroundColor Green

Write-Host "Detaching USB/IP devices..." -ForegroundColor Yellow
$usbipExe = "C:\Program Files\USBip\usbip.exe"
if (Test-Path $usbipExe) { & $usbipExe detach --all 2>&1 | Out-Null }
Write-Host "  Done" -ForegroundColor Green

Write-Host "Removing files..." -ForegroundColor Yellow
# Current locations
Remove-Item "C:\Program Files\ZeroHub" -Recurse -Force
Remove-Item "C:\ProgramData\ZeroHub" -Recurse -Force
# Old locations
Remove-Item "$env:USERPROFILE\Documents\ZeroHub" -Recurse -Force
Remove-Item "$env:USERPROFILE\Documents\usbip-listener.ps1" -Force
Remove-Item "$env:USERPROFILE\Documents\usbip-listener-hidden.vbs" -Force
Remove-Item "$env:USERPROFILE\zerohub-listener.log" -Force
Remove-Item "$env:APPDATA\zerohub-listener" -Recurse -Force
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ZeroHub Listener.lnk" -Force
Remove-Item "HKLM:\SOFTWARE\ZeroHub" -Force
Write-Host "  Done" -ForegroundColor Green

Write-Host ""
Write-Host "ZeroHub uninstalled successfully." -ForegroundColor Green
Write-Host "Note: usbip-win2 was not removed. Uninstall it separately if desired." -ForegroundColor Yellow
Write-Host ""
pause
