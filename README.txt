============================================================
DHCP Reset Tool - Field Deployment Package
Developer: What The Dev
Copyright © 2026
============================================================

ABOUT THIS TOOL
---------------
This utility provides a safe and user-friendly way to reset
Ethernet network adapters to DHCP. It includes:

- Multi-select adapter GUI
- Before/after IP logging
- DHCP detection ("DHCP" shown instead of IP)
- Log viewer GUI
- DryRun mode for safe testing
- Desktop shortcuts for quick access

This tool is intended for field technicians who need a fast,
repeatable way to reset network adapters on Windows laptops.


INSTALLATION
------------
1. Copy the entire "DHCPResetTool" folder to the laptop.
2. Run: Install_DHCPResetTool.bat
3. The installer will:
   - Create C:\Tools\DHCPResetTool\
   - Copy the tool files
   - Create desktop shortcuts:
       • DHCP Reset Adapters
       • DHCP Reset Log Viewer


USAGE
-----
DHCP Reset Adapters:
    Launches the main GUI. Select one or more adapters to reset.

DHCP Reset Log Viewer:
    Opens the log file in a scrollable window.

Logs are stored at:
    C:\Tools\DHCPResetTool\ResetLog.txt


UPDATING THE TOOL
-----------------
To update the tool on a laptop:
- Replace Reset-Ethernet-DHCP-GUI.ps1 in:
      C:\Tools\DHCPResetTool\
OR
- Re-run Install_DHCPResetTool.bat


DISCLAIMER
----------
This tool is provided "as is" without warranty of any kind.
What The Dev assumes no responsibility for any damage,
data loss, or network disruption resulting from use or misuse.

By using this tool, you agree that you are solely responsible
for verifying that DHCP resets are appropriate for your
environment and device.


SUPPORT
-------
For updates or issues, contact your internal support team
or the developer: What The Dev
============================================================
