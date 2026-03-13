# ZeroHub Notification Helper
# Shows a custom toast-style popup in the bottom-right corner
param(
    [string]$Title = "ZeroHub",
    [string]$Message = "",
    [string]$Type = "Info"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$colors = @{
    "Info"    = @{ bg = [System.Drawing.Color]::FromArgb(30, 30, 30);    accent = [System.Drawing.Color]::FromArgb(0, 150, 255) }
    "Warning" = @{ bg = [System.Drawing.Color]::FromArgb(40, 35, 20);    accent = [System.Drawing.Color]::FromArgb(255, 180, 0) }
    "Error"   = @{ bg = [System.Drawing.Color]::FromArgb(40, 20, 20);    accent = [System.Drawing.Color]::FromArgb(255, 60, 60) }
}
$scheme = $colors[$Type]
if (-not $scheme) { $scheme = $colors["Info"] }

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

# Measure text to determine width
$titleFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$msgFont = New-Object System.Drawing.Font("Segoe UI", 9)
$g = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
$titleWidth = [int]$g.MeasureString($Title, $titleFont).Width
$msgWidth = [int]$g.MeasureString($Message, $msgFont).Width
$g.Dispose()

$contentWidth = [Math]::Max($titleWidth, $msgWidth)
$formWidth = $contentWidth + 34
$formWidth = [Math]::Max($formWidth, 160)
$formWidth = [Math]::Min($formWidth, 400)

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = "None"
$form.StartPosition = "Manual"
$form.TopMost = $true
$form.ShowInTaskbar = $false
$form.BackColor = $scheme.bg
$form.Size = New-Object System.Drawing.Size($formWidth, 72)
$form.Opacity = 0.0
$form.Location = New-Object System.Drawing.Point(($screen.Right - $formWidth - 12), ($screen.Bottom - 84))

$bar = New-Object System.Windows.Forms.Panel
$bar.BackColor = $scheme.accent
$bar.Size = New-Object System.Drawing.Size(3, 72)
$bar.Location = New-Object System.Drawing.Point(0, 0)
$form.Controls.Add($bar)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = $Title
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Font = $titleFont
$lblTitle.Location = New-Object System.Drawing.Point(12, 10)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

$lblMsg = New-Object System.Windows.Forms.Label
$lblMsg.Text = $Message
$lblMsg.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$lblMsg.Font = $msgFont
$lblMsg.Location = New-Object System.Drawing.Point(12, 36)
$lblMsg.AutoSize = $true
$form.Controls.Add($lblMsg)

$fadeIn = New-Object System.Windows.Forms.Timer
$fadeIn.Interval = 15
$fadeIn.Add_Tick({
    if ($form.Opacity -lt 0.95) {
        $form.Opacity += 0.08
    } else {
        $form.Opacity = 0.97
        $fadeIn.Stop()
        $hold.Start()
    }
})

$hold = New-Object System.Windows.Forms.Timer
$hold.Interval = 4000
$hold.Add_Tick({
    $hold.Stop()
    $fadeOut.Start()
})

$fadeOut = New-Object System.Windows.Forms.Timer
$fadeOut.Interval = 15
$fadeOut.Add_Tick({
    if ($form.Opacity -gt 0.05) {
        $form.Opacity -= 0.06
    } else {
        $fadeOut.Stop()
        $form.Close()
    }
})

$form.Add_Shown({ $fadeIn.Start() })
$form.Add_Click({ $form.Close() })

[System.Windows.Forms.Application]::Run($form)

