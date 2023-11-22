# Variables
$scriptPath = $MyInvocation.MyCommand.Definition
$langMode = $ExecutionContext.SessionState.LanguageMode

# Check if correct language mode enabled
# Usually, an incorrect language mode means the script is NOT elevated, so we will try to relaunch anyway...
If ($langMode -eq "ConstrainedLanguage") {
    Write-Warning "This script is running in Constrained Language mode, so it cannot check for elevated permissions."
    Write-Information "Usually, this means the script is not elevated."
    Write-Information "Attempting to relaunch as an elevated process..."

    Start-Process -Verb RunAs powershell.exe -ArgumentList "& '$($scriptPath)'"
    exit 0
}

# Check if elevated
#$oIdent = [Security.Principal.WindowsIdentity]::GetCurrent()
#$oPrincipal = New-Object Security.Principal.WindowsPrincipal($oIdent)
#If (!$oPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator )){
#    Write-Warning "This script must run in an elevated process to enable applications to be started correctly."
#    Write-Information "Attempting to relaunch as an elevated process..."
#    Write-Information "If this doesn't work, please relaunch from a PowerShell (Admin) session."
#
#    Start-Process -Verb RunAs powershell.exe -ArgumentList "& '$($scriptPath)'"
#    exit 0
#}

# Start an administrator PowerShell session
Start-Process -Verb RunAs powershell

# Start AD Users and Computers
Start-Process -Verb RunAs $env:SystemRoot\system32\dsa.msc

# Start MECM
# Note: Sometimes this will not be the correct file path, as the config manager will be in a different location
#       If this is the case, just update the path below.
Start-Process -Verb RunAs "C:\Program Files (x86)\ConfigMgr Console\bin\Microsoft.ConfigurationManagement.exe"

# Exit this session
exit 0