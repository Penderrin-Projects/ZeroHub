# ZeroHub - Windows Installer
# Sets up the USB/IP listener, notifications, scheduled task, and tray app
param(
    [string]$PiIP
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      ZeroHub Windows Installer           ║" -ForegroundColor Cyan
Write-Host "║   USB/IP Auto-Attach Listener Setup      ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check for admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Host "ERROR: This installer must be run as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator', then try again." -ForegroundColor Yellow
    pause
    exit 1
}

# Check for usbip-win2
$USBIP_EXE = "C:\Program Files\USBip\usbip.exe"
if (-not (Test-Path $USBIP_EXE)) {
    Write-Host "ERROR: usbip-win2 is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install usbip-win2 first:" -ForegroundColor Yellow
    Write-Host "  1. Go to: https://github.com/cezuni/usbip-win2/releases"
    Write-Host "  2. Download the latest usbip-win2_vX.X.X.X.msi"
    Write-Host "  3. Install it"
    Write-Host "  4. Run this installer again"
    Write-Host ""
    pause
    exit 1
}

# Get Pi IP
if (-not $PiIP) {
    Write-Host "Enter the IP address of your Raspberry Pi:" -ForegroundColor Yellow
    $PiIP = Read-Host "Pi IP"
}

if (-not $PiIP -or $PiIP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Host "ERROR: Invalid IP address." -ForegroundColor Red
    pause
    exit 1
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallDir = "$env:USERPROFILE\Documents\ZeroHub"
$UserHome = $env:USERPROFILE

Write-Host ""
Write-Host "Installing with Pi target: $PiIP" -ForegroundColor Green
Write-Host "Install directory: $InstallDir" -ForegroundColor Green
Write-Host ""

# [1/5] Create install directory and copy files
Write-Host "[1/5] Installing files..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null

# Copy listener script with Pi IP filled in
$listenerContent = Get-Content "$ScriptDir\zerohub-listener.ps1.template" -Raw
$listenerContent = $listenerContent.Replace("__PI_IP__", $PiIP)
# Fix SYSTEM path resolution - store the installing user's home
$listenerContent = $listenerContent -replace '\$UserHome = \(Get-ItemProperty.*?\n.*?\n.*?\n.*?\}', "`$UserHome = `"$UserHome`""
Set-Content "$InstallDir\zerohub-listener.ps1" $listenerContent

# Copy notification files
Copy-Item "$ScriptDir\zerohub-notify.ps1" "$InstallDir\zerohub-notify.ps1" -Force
Copy-Item "$ScriptDir\zerohub-notify.vbs" "$InstallDir\zerohub-notify.vbs" -Force
Write-Host "  ✓ Files installed to $InstallDir" -ForegroundColor Green

# [2/5] Save config for tray app
Write-Host "[2/5] Saving configuration..." -ForegroundColor Cyan
$configDir = "$env:APPDATA\zerohub-listener"
New-Item -ItemType Directory -Path $configDir -Force | Out-Null
@{ piIP = $PiIP } | ConvertTo-Json | Set-Content "$configDir\config.json"

# Store user home in registry for SYSTEM context
New-Item -Path "HKLM:\SOFTWARE\ZeroHub" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\ZeroHub" -Name "UserHome" -Value $UserHome
Write-Host "  ✓ Configuration saved" -ForegroundColor Green

# [3/5] Create scheduled task (runs at boot as SYSTEM, before login)
Write-Host "[3/5] Creating startup service..." -ForegroundColor Cyan
$taskName = "ZeroHub Listener Service"
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$InstallDir\zerohub-listener.ps1`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -User "SYSTEM" -RunLevel Highest -Description "ZeroHub USB/IP listener - runs at boot before login" | Out-Null
Write-Host "  ✓ Scheduled task created (runs at boot)" -ForegroundColor Green

# [4/5] Install tray app
Write-Host "[4/5] Installing tray app..." -ForegroundColor Cyan
$trayDir = "$ScriptDir\tray-app"
$trayExeDir = "C:\Program Files\ZeroHub"
New-Item -ItemType Directory -Path $trayExeDir -Force | Out-Null

if (Test-Path "$trayDir\package.json") {
    # Check if node is available
    $nodeAvailable = $false
    try { node --version | Out-Null; $nodeAvailable = $true } catch {}

    if ($nodeAvailable) {
        Write-Host "  Building tray app..." -ForegroundColor Yellow
        Push-Location $trayDir
        if (-not (Test-Path "node_modules")) { npm install --silent 2>&1 | Out-Null }
        npx electron-builder --win portable 2>&1 | Out-Null
        Pop-Location

        $exePath = Get-ChildItem "$trayDir\dist\*.exe" | Select-Object -First 1
        if ($exePath) {
            Copy-Item $exePath.FullName "$trayExeDir\ZeroHub Listener.exe" -Force
            Write-Host "  ✓ Tray app built and installed" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Build succeeded but no EXE found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Node.js not found — checking for pre-built EXE..." -ForegroundColor Yellow
        # Check if user downloaded the EXE from GitHub releases
        $prebuilt = Get-ChildItem "$ScriptDir\..","$ScriptDir","$trayExeDir","$env:USERPROFILE\Downloads" -Filter "ZeroHub*Listener*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($prebuilt) {
            Copy-Item $prebuilt.FullName "$trayExeDir\ZeroHub Listener.exe" -Force
            Write-Host "  ✓ Found and installed $($prebuilt.Name)" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ Tray app not found" -ForegroundColor Yellow
            Write-Host "    Download ZeroHub.Listener.exe from:" -ForegroundColor Yellow
            Write-Host "    https://github.com/Penderrin-Projects/ZeroHub/releases/latest" -ForegroundColor Cyan
            Write-Host "    Place it in: $trayExeDir" -ForegroundColor Yellow
        }
    }
} elseif (Test-Path "$trayExeDir\ZeroHub Listener.exe") {
    Write-Host "  ✓ Tray app already installed" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Tray app not found — download from GitHub releases" -ForegroundColor Yellow
}

# [5/5] Create startup shortcut for tray app
Write-Host "[5/5] Creating login startup shortcut..." -ForegroundColor Cyan
if (Test-Path "$trayExeDir\ZeroHub Listener.exe") {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ZeroHub Listener.lnk")
    $shortcut.TargetPath = "$trayExeDir\ZeroHub Listener.exe"
    $shortcut.Save()
    Write-Host "  ✓ Tray app will start at login" -ForegroundColor Green
}

# Start the service now
Write-Host ""
Write-Host "Starting ZeroHub listener..." -ForegroundColor Cyan
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 2

$taskState = (Get-ScheduledTask -TaskName $taskName).State
if ($taskState -eq "Running") {
    Write-Host "  ✓ Listener is running!" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Listener may not have started ($taskState)" -ForegroundColor Yellow
}

# Launch tray app
if (Test-Path "$trayExeDir\ZeroHub Listener.exe") {
    Start-Process "$trayExeDir\ZeroHub Listener.exe"
    Write-Host "  ✓ Tray app launched" -ForegroundColor Green
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        Installation Complete!            ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Pi IP:    $PiIP" -ForegroundColor Green
Write-Host "  Log:      $UserHome\zerohub-listener.log"
Write-Host "  Tray:     Look for the blue Z icon in your system tray"
Write-Host ""
Write-Host "Your USB devices on the Pi will now appear on this PC automatically!" -ForegroundColor Green
Write-Host ""
pause
