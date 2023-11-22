# Variables
$scriptPath = $MyInvocation.MyCommand.Definition
$langMode = $ExecutionContext.SessionState.LanguageMode

# Check if correct language mode enabled
# Usually, an incorrect language mode means the script is NOT elevated.
If ($langMode -eq "ConstrainedLanguage") {
    Write-Error "This script is running in Constrained Language mode - please launch an elevated PowerShell session and run this script from inside it."

    exit 1
}

Write-Information "Importing SCCM module..."
Import-Module 'C:\Program Files (x86)\ConfigMgr Console\bin\ConfigurationManager.psd1' -ErrorVariable SCCMModuleGetError
if ($SCCMModuleGetError) {
    Write-Error "SCCM module is unavailable. Exiting..."
    Exit 1
}

Write-Information "ConfigurationManager module version: $((Get-Module -Name ConfigurationManager).Version)"

# Connect to site
Write-Information "Connecting to site..."
New-PSDrive -Name "P01" -PSProvider "CMSite" -Root "sccm-central" -Description "Primary SCCM site" -ErrorAction SilentlyContinue -ErrorVariable PSDriveGetError
if ($PSDriveGetError) {
    Write-Error "The necessary preperation steps have failed.`n`tThe connection may already exist, or you don't have the correct permissions to initiate it."
    Write-Output "`n`nStart a new PowerShell session as an Administrator, and re-run this script. Exiting..."
    Exit 1
}

Set-Location P01:
Write-Information "Site Information: $(Get-CMSite)"

Write-Output "Initialisation complete."

Exit 0