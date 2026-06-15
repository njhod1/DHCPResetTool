Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#------------------------------------------------------------
# Helper: Show dialog
#------------------------------------------------------------
function Show-Dialog($message, $title, $buttonType) {
    [System.Windows.Forms.MessageBox]::Show($message, $title, $buttonType)
}

#------------------------------------------------------------
# Helper: Get IP state (DHCP or actual IP)
#------------------------------------------------------------
function Get-IPState($adapterName) {
    $ip = Get-NetIPAddress -InterfaceAlias $adapterName -ErrorAction SilentlyContinue
    if ($ip) { return $ip.IPAddress }
    return "DHCP"
}

#------------------------------------------------------------
# GUI Setup
#------------------------------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "DHCP Reset Tool"
$form.Size = New-Object System.Drawing.Size(500,400)
$form.StartPosition = "CenterScreen"

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20,20)
$listBox.Size = New-Object System.Drawing.Size(440,200)
$listBox.SelectionMode = "MultiExtended"
$form.Controls.Add($listBox)

# Load adapters (Wi-Fi excluded)
$adapters = Get-NetAdapter |
    Where-Object {
        $_.Status -eq "Up" -and
        $_.InterfaceDescription -notmatch "Virtual|VPN|Bluetooth|Wi-Fi|Wireless"
    }

foreach ($a in $adapters) { [void]$listBox.Items.Add($a.Name) }

# Reset button
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Text = "Reset Selected Adapters"
$resetButton.Location = New-Object System.Drawing.Point(20,240)
$resetButton.Size = New-Object System.Drawing.Size(200,40)
$form.Controls.Add($resetButton)

# View Log button
$logButton = New-Object System.Windows.Forms.Button
$logButton.Text = "View Log"
$logButton.Location = New-Object System.Drawing.Point(260,240)
$logButton.Size = New-Object System.Drawing.Size(200,40)
$form.Controls.Add($logButton)

#------------------------------------------------------------
# RESET BUTTON HANDLER
#------------------------------------------------------------
$resetButton.Add_Click({

    $selectedAdapters = $listBox.SelectedItems
    if ($selectedAdapters.Count -eq 0) {
        Show-Dialog "Please select at least one adapter." "No Selection" "OK" | Out-Null
        return
    }

    #--------------------------------------------------------
    # BUILD CONFIRMATION DIALOG
    #--------------------------------------------------------
    $confirmMessage = "You are about to reset the following adapters:`n`n"

    foreach ($adapterName in $selectedAdapters) {
        $current = Get-IPState $adapterName

        $confirmMessage += $adapterName + "`n"
        $confirmMessage += "  Current = " + $current + "`n"
        $confirmMessage += "  After   = DHCP`n`n"
    }

    $confirmMessage += "Proceed with reset"

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $confirmMessage,
        "Confirm Reset",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    #--------------------------------------------------------
    # LOG FILE SETUP
    #--------------------------------------------------------
    $logPath = "C:\Tools\DHCPResetTool\ResetLog.txt"
    Add-Content -Path $logPath -Value ("----- " + (Get-Date) + " -----")

    #--------------------------------------------------------
    # PERFORM RESET + LOGGING
    #--------------------------------------------------------
    foreach ($adapterName in $selectedAdapters) {
        try {
            Add-Content -Path $logPath -Value ("Resetting adapter: " + $adapterName)

            Set-NetIPInterface -InterfaceAlias $adapterName -Dhcp Enabled -ErrorAction Stop
            Add-Content -Path $logPath -Value "  DHCP enabled."

            Remove-NetIPAddress -InterfaceAlias $adapterName -Confirm:$false -ErrorAction SilentlyContinue
            Add-Content -Path $logPath -Value "  Existing IP addresses removed."

            Add-Content -Path $logPath -Value "  Reset successful.`n"
        }
        catch {
            Add-Content -Path $logPath -Value ("  ERROR: " + $_ + "`n")
        }
    }

    Show-Dialog "Reset complete." "Done" "OK" | Out-Null
})

#------------------------------------------------------------
# VIEW LOG BUTTON HANDLER
#------------------------------------------------------------
$logButton.Add_Click({
    $logPath = "C:\Tools\DHCPResetTool\ResetLog.txt"

    if (-not (Test-Path $logPath)) {
        Show-Dialog "No log file found." "Log Missing" "OK" | Out-Null
        return
    }

    $logForm = New-Object System.Windows.Forms.Form
    $logForm.Text = "DHCP Reset Log"
    $logForm.Size = New-Object System.Drawing.Size(600,400)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.ReadOnly = $true
    $textBox.ScrollBars = "Vertical"
    $textBox.Dock = "Fill"
    $textBox.Text = Get-Content $logPath -Raw

    $logForm.Controls.Add($textBox)
    [void]$logForm.ShowDialog()
})

#------------------------------------------------------------
# RUN GUI
#------------------------------------------------------------
$form.Topmost = $true
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()
