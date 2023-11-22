if ($false -eq [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")) {
    Write-Output "Run this script as an administrator, otherwise OneDrive cannot be uninstalled."
    pause
    exit
}

# Copy installer to a location we can run it from
cp "\\fs-central\OneDriveSetup.exe" "C:\Program Files\OneDriveSetup.exe"

# Locate existing OneDrive installation and uninstall it
Write-Output "Uninstalling OneDrive..."
taskkill /F /IM "OneDrive.exe"
& "C:\Windows\SysWOW64\OneDriveSetup.exe" /Uninstall /AllUsers

Write-Output "Waiting 30 seconds for OneDrive to uninstall..."
Sleep -Seconds 30

cls

# Invoke OneDrive installer
Write-Output "Installing OneDrive..."
Invoke-Item "C:\Program Files\OneDriveSetup.exe"
Sleep -Seconds 2

cls

Write-Output "Once OneDrive appears in the status bar, please sign in."
Write-Output "Press Enter to exit."
Read-Host -Prompt ":>"
exit