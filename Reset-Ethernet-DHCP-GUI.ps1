# ------------------------------------------------------------
# DHCP Reset Utility - Multi-Adapter GUI Edition
# Developer: What The Dev
# Copyright © 2026 What The Dev
#
# DISCLAIMER:
# This tool is provided "as is" without warranty of any kind.
# What The Dev assumes no responsibility for any damage,
# data loss, misconfiguration, or network disruption resulting
# from the use or misuse of this software.
#
# By using this tool, you agree that you are solely responsible
# for verifying network settings and ensuring that DHCP resets
# are appropriate for your environment.
# ------------------------------------------------------------

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# -----------------------------
# CONFIGURATION
# -----------------------------
$DryRun = $true   # Set to $false for real use

# -----------------------------
# GUI Helper Functions
# -----------------------------
function Show-Dialog($message, $title, $buttons) {
    return [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons)
}

function Show-LogViewer($logPath) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Reset Log Viewer"
    $form.Width = 800
    $form.Height = 600

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Multiline = $true
    $textbox.ReadOnly = $true
    $textbox.ScrollBars = "Vertical"
    $textbox.Dock = "Fill"

    if (Test-Path $logPath) {
        $textbox.Text = Get-Content $logPath -Raw
    }
    else {
        $textbox.Text = "No log file found."
    }

    $form.Controls.Add($textbox)
    $form.ShowDialog() | Out-Null
}

# -----------------------------
# MAIN MENU GUI
# -----------------------------
$menu = New-Object System.Windows.Forms.Form
$menu.Text = "DHCP Reset Tool"
$menu.Width = 300
$menu.Height = 200

$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "Reset Adapters"
$btnReset.Width = 240
$btnReset.Height = 40
$btnReset.Top = 20
$btnReset.Left = 20

$btnViewLog = New-Object System.Windows.Forms.Button
$btnViewLog.Text = "View Log Only"
$btnViewLog.Width = 240
$btnViewLog.Height = 40
$btnViewLog.Top = 80
$btnViewLog.Left = 20

$menu.Controls.Add($btnReset)
$menu.Controls.Add($btnViewLog)

# -----------------------------
# LOG PATH
# -----------------------------
$logPath = "$PSScriptRoot\ResetLog.txt"

# -----------------------------
# VIEW LOG BUTTON HANDLER
# -----------------------------
$btnViewLog.Add_Click({
    Show-LogViewer $logPath
})

# -----------------------------
# RESET BUTTON HANDLER
# -----------------------------
$btnReset.Add_Click({

    # Operator initials
    $initials = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Enter your initials:",
        "Operator Initials",
        ""
    )

    if ($initials -eq "") { 
        Show-Dialog "Cancelled." "Cancelled" "OK" | Out-Null
        return
    }

    # Get adapters (exclude Wi-Fi)
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notmatch "Wi-Fi" }

    if ($adapters.Count -eq 0) {
        Show-Dialog "No active Ethernet adapters found." "No Adapters" "OK" | Out-Null
        return
    }

    # -----------------------------
    # MULTI-SELECT GUI
    # -----------------------------
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select Adapters"
    $form.Width = 400
    $form.Height = 350

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Select one or more adapters to reset:"
    $label.AutoSize = $true
    $label.Top = 20
    $label.Left = 20

    $listbox = New-Object System.Windows.Forms.ListBox
    $listbox.Top = 50
    $listbox.Left = 20
    $listbox.Width = 330
    $listbox.Height = 200
    $listbox.SelectionMode = "MultiExtended"

    foreach ($a in $adapters) {
        $listbox.Items.Add($a.Name) | Out-Null
    }

    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Text = "OK"
    $buttonOK.Top = 260
    $buttonOK.Left = 20
    $buttonOK.Add_Click({
        if ($listbox.SelectedItems.Count -gt 0) {
            $form.Tag = $listbox.SelectedItems
            $form.Close()
        }
    })

    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Text = "Cancel"
    $buttonCancel.Top = 260
    $buttonCancel.Left = 120
    $buttonCancel.Add_Click({
        $form.Tag = $null
        $form.Close()
    })

    $form.Controls.Add($label)
    $form.Controls.Add($listbox)
    $form.Controls.Add($buttonOK)
    $form.Controls.Add($buttonCancel)

    $form.ShowDialog() | Out-Null

    $selectedAdapters = $form.Tag

    if (-not $selectedAdapters) {
        Show-Dialog "Cancelled." "Cancelled" "OK" | Out-Null
        return
    }

    # Logging setup
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computer = $env:COMPUTERNAME

    # Function: Get IP or DHCP
    function Get-IPState($adapterName) {
        $ipv4 = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue

        if ($ipv4 -and $ipv4.PrefixOrigin -eq "Dhcp") {
            return "DHCP"
        }
        elseif ($ipv4) {
            return $ipv4.IPAddress
        }
        else {
            return "None"
        }
    }

    # Perform reset on each selected adapter
    $logEntries = @()

    foreach ($adapterName in $selectedAdapters) {

        $before = Get-IPState $adapterName

        if ($DryRun) {
            Write-Host "[DRY RUN] Would reset adapter: $adapterName" -ForegroundColor Yellow
        }
        else {
            netsh interface ip set address name="$adapterName" source=dhcp | Out-Null
            netsh interface ip set dns name="$adapterName" source=dhcp | Out-Null
        }

        $after = if ($DryRun) { $before } else { Get-IPState $adapterName }

        $logEntries += "  Adapter: $adapterName | Before: $before | After: $after"
    }

    if (-not $DryRun) {
        ipconfig /flushdns | Out-Null
        ipconfig /renew | Out-Null
    }

    # Write log
    Add-Content -Path $logPath -Value "$timestamp | Operator: $initials | Computer: $computer | DryRun: $DryRun"
    foreach ($entry in $logEntries) {
        Add-Content -Path $logPath -Value $entry
    }
    Add-Content -Path $logPath -Value ""

    # Ask to view log
    $view = Show-Dialog "Reset complete. View log?" "Done" "YesNo"

    if ($view -eq "Yes") {
        Show-LogViewer $logPath
    }
})

# -----------------------------
# SHOW MAIN MENU
# -----------------------------
$menu.ShowDialog() | Out-Null
