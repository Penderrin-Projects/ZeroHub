# ZeroHub - Windows Client Installer
# Run this as Administrator in PowerShell

param(
    [string]$PiIP
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        ZeroHub Windows Installer         ║" -ForegroundColor Cyan
Write-Host "║   Free USB/IP Auto-Attach Client         ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Please run this script as Administrator." -ForegroundColor Red
    Write-Host "Right-click PowerShell > 'Run as Administrator', then try again." -ForegroundColor Yellow
    exit 1
}

# Get Pi IP
if (-not $PiIP) {
    $PiIP = Read-Host "Enter your Raspberry Pi's IP address"
}
if ($PiIP -notmatch '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
    Write-Host "ERROR: Invalid IP address format." -ForegroundColor Red
    exit 1
}

$ListenPort = 3241
$InstallDir = "$env:USERPROFILE\Documents\ZeroHub"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Installing with Pi target: $PiIP" -ForegroundColor Green
Write-Host ""

# Step 1: Check for / install usbip-win2
Write-Host "[1/5] Checking for usbip-win2 driver..." -ForegroundColor Cyan
$usbipExe = "C:\Program Files\USBip\usbip.exe"
if (-not (Test-Path $usbipExe)) {
    Write-Host "  usbip-win2 is not installed. Downloading latest release..." -ForegroundColor Yellow
    try {
        # Query GitHub API for latest release
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/vadimgrn/usbip-win2/releases/latest" -UseBasicParsing
        $msiAsset = $releaseInfo.assets | Where-Object { $_.name -like "*x64*.msi" -or $_.name -like "*.msi" } | Select-Object -First 1

        if (-not $msiAsset) {
            # Fallback: try all releases if "latest" has no MSI
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/vadimgrn/usbip-win2/releases?per_page=5" -UseBasicParsing
            foreach ($rel in $releases) {
                $msiAsset = $rel.assets | Where-Object { $_.name -like "*.msi" } | Select-Object -First 1
                if ($msiAsset) { break }
            }
        }

        if (-not $msiAsset) {
            Write-Host "  Could not find an MSI installer in the latest releases." -ForegroundColor Red
            Write-Host "  Please install manually from: https://github.com/vadimgrn/usbip-win2/releases" -ForegroundColor Yellow
            exit 1
        }

        $msiUrl = $msiAsset.browser_download_url
        $msiName = $msiAsset.name
        $msiPath = Join-Path $env:TEMP $msiName
        Write-Host "  Downloading $msiName..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing

        Write-Host "  Installing usbip-win2 (this may take a moment)..." -ForegroundColor Yellow
        Write-Host "  NOTE: Your USB devices may briefly disconnect during driver installation." -ForegroundColor Yellow
        $process = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /quiet /norestart" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "  MSI installer returned exit code $($process.ExitCode)." -ForegroundColor Yellow
            Write-Host "  Trying interactive install..." -ForegroundColor Yellow
            Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`"" -Wait
        }

        # Clean up
        Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

        if (-not (Test-Path $usbipExe)) {
            Write-Host "  ERROR: usbip-win2 installation did not complete successfully." -ForegroundColor Red
            Write-Host "  Please install manually from: https://github.com/vadimgrn/usbip-win2/releases" -ForegroundColor Yellow
            exit 1
        }
        Write-Host "  OK - usbip-win2 installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Failed to download usbip-win2: $_" -ForegroundColor Red
        Write-Host "  Please install manually from: https://github.com/vadimgrn/usbip-win2/releases" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "  OK - usbip-win2 already installed" -ForegroundColor Green
}

# Step 2: Create install directory and listener script
Write-Host "[2/5] Installing listener script..." -ForegroundColor Cyan
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$templatePath = Join-Path $ScriptDir "zerohub-listener.ps1.template"
if (-not (Test-Path $templatePath)) {
    Write-Host "  ERROR: Template file not found at $templatePath" -ForegroundColor Red
    exit 1
}
$listenerContent = (Get-Content $templatePath -Raw) -replace "__PI_IP__", $PiIP
$listenerPath = Join-Path $InstallDir "zerohub-listener.ps1"
Set-Content -Path $listenerPath -Value $listenerContent -Encoding UTF8
Write-Host "  OK - Listener script installed to $listenerPath" -ForegroundColor Green

# Copy notification scripts
$notifyPs1 = Join-Path $ScriptDir "zerohub-notify.ps1"
$notifyVbs = Join-Path $ScriptDir "zerohub-notify.vbs"
if (Test-Path $notifyPs1) {
    Copy-Item $notifyPs1 -Destination (Join-Path $InstallDir "zerohub-notify.ps1") -Force
    Write-Host "  OK - Notification popup script installed" -ForegroundColor Green
}
if (Test-Path $notifyVbs) {
    Copy-Item $notifyVbs -Destination (Join-Path $InstallDir "zerohub-notify.vbs") -Force
    Write-Host "  OK - Notification launcher installed" -ForegroundColor Green
}

# Step 3: Create hidden launcher (VBS wrapper)
Write-Host "[3/5] Creating hidden launcher..." -ForegroundColor Cyan
$vbsContent = "CreateObject(""Wscript.Shell"").Run ""powershell.exe -NoProfile -ExecutionPolicy Bypass -File $listenerPath"", 0, False"
$vbsPath = Join-Path $InstallDir "zerohub-listener-hidden.vbs"
Set-Content -Path $vbsPath -Value $vbsContent -Encoding ASCII
Write-Host "  OK - Hidden launcher created" -ForegroundColor Green

# Step 4: Create scheduled task
Write-Host "[4/5] Creating startup task..." -ForegroundColor Cyan
$taskName = "ZeroHub Auto-Attach Listener"

# Remove existing task if present
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $vbsPath
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -RunLevel Highest -LogonType Interactive

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
Write-Host "  OK - Scheduled task created (runs at login)" -ForegroundColor Green

# Step 5: Create firewall rule
Write-Host "[5/5] Configuring firewall..." -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName "ZeroHub Listener" -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "ZeroHub Listener" -Direction Inbound -Protocol TCP -LocalPort $ListenPort -Action Allow | Out-Null
Write-Host "  OK - Firewall rule created (TCP $ListenPort inbound)" -ForegroundColor Green

# Start the listener now
Write-Host ""
Write-Host "Starting listener..." -ForegroundColor Cyan
Start-ScheduledTask -TaskName $taskName
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "╔══════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║          Installation Complete!           ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Pi target:     $PiIP" -ForegroundColor Green
Write-Host "  Listen port:   $ListenPort" -ForegroundColor Green
Write-Host "  Install dir:   $InstallDir" -ForegroundColor Green
Write-Host "  Log file:      $env:USERPROFILE\zerohub-listener.log" -ForegroundColor Green
Write-Host ""
Write-Host "Plug a USB device into your Pi — it will appear on this PC automatically!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Yellow
Write-Host "  & '$usbipExe' port                  # List attached devices"
Write-Host "  & '$usbipExe' list -r $PiIP    # List available devices on Pi"
Write-Host "  Get-Content ~\zerohub-listener.log -Tail 20  # View log"
Write-Host ""
