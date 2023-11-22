####
#### Remove Device from AD and SCCM
####
##   USAGE:
##   A1.     Run script without asset tag
##              $ .\Remove-Device-From-AD-SCCM.ps1
##   A2.     When prompted, enter an asset ID (without trailing X)
##   A3.     Confirm removals from AD and SCCM
##               SCCM will prompt you twice for each device. The first prompt is to enter the deletion phase of a query.
##               The second prompt is to delete the object contained inside the query. Confirm it both times.
##               It will only delete ONE device for each two prompts. If in doubt, double-check the asset tags and device names when confirming.
####
##   ALTERNATIVE USAGE:
##   B1.     Run script with an asset ID
##              $ .\Remove-Device-From-AD-SCCM.ps1 1021021
##   B2.     Confirm removals from AD and SCCM (read above warnings)
####
#### github.com/transiient
####

# Variables
$scriptPath = $MyInvocation.MyCommand.Definition
$langMode = $ExecutionContext.SessionState.LanguageMode

# Check if correct language mode enabled
# Usually, an incorrect language mode means the script is NOT elevated, so we will try to relaunch anyway...
If ($langMode -eq "ConstrainedLanguage") {
    Write-Warning "This script is running in Constrained Language mode. Relaunching with elevated permissions..."

    Start-Process -Verb RunAs powershell.exe -ArgumentList "& '$($scriptPath)'"
    exit 0
}

#### BEGIN
Write-Output "Preparing..."

Write-Information "Importing SCCM module..."
Import-Module 'C:\Program Files (x86)\ConfigMgr Console\bin\ConfigurationManager.psd1' -ErrorVariable SCCMModuleGetError
if ($SCCMModuleGetError) {
    Write-Output "SCCM module appears to be unavailable. Exiting..."
    Exit 1
}

Write-Information "ConfigurationManager module version: $((Get-Module -Name ConfigurationManager).Version)"

# Connect to site
Write-Information "Connecting to site..."
New-PSDrive -Name "P01" -PSProvider "CMSite" -Root "sccm-central" -Description "Primary SCCM site" -ErrorAction SilentlyContinue -ErrorVariable PSDriveGetError
if ($PSDriveGetError) {
    Write-Error "The necessary preperation steps have failed.`nThe connection may already exist, or you don't have the correct permissions to initiate it."
    Write-Output "$PSDriveGetError"
    Write-Output "`n`nTry starting a new PowerShell session as an Administrator, then re-run this script. Exiting..."
    Exit 1
}

Set-Location P01:
Write-Information "Site Information: $(Get-CMSite)"

Write-Output "Initialisation complete."

timeout /T 1
cls

Write-Output "`n`n`nRemove a Computer from AD and SCCM.`n`n`n"
Write-Output "This script does what you would normally do inside AD and SCCM consoles, but faster."
Write-Output "It also removes duplicate (-X and -non-X) devices from both systems."
Write-Output "`n`nTip: Provide an asset tag as an argument to automatically launch. EG: `n`t> Remove.ps1 1021234"

Write-Output "`n"
if ($args[0]) {
    Write-Output "An asset tag was provided - skipping user input."
    $XAssetTag = $args[0]
} else {
    Write-Output "Enter the Computer asset tag below. Do not include any characters at the end of the string.`n"
    $XAssetTag = Read-Host "Enter the Computer asset tag"
}

# Though this only removes ONE Computer (asset tag), there might be multiple computers with the same tag.
# EG:
#   - 1021234
#   - 1021234X

function SCCMFindAll {
    param (
        $AssetTag
    )

    # outputs IResultObject
    Get-CMDevice -Name "$AssetTag"
    Get-CMDevice -Name ("$AssetTag" + "X")
}

function SCCMRemoveAsset {
    param (
        $ComputerName
    )

    # Remove one
    Remove-CMDevice -DeviceName "$ComputerName" -Confirm
}

function ADFindAll {
    param (
        $AssetTag
    )

    # This will often spring up errors about not being able to find the Identity. Just ignore it, because we don't care.
    try { Get-ADComputer -Identity "$AssetTag" -ErrorAction SilentlyContinue } catch {}
    try { Get-ADComputer -Identity ("$AssetTag" + "X") -ErrorAction SilentlyContinue } catch {}
}

function ADRemoveObject {
    param (
        $ComputerName
    )

    # Remove one
    Remove-ADComputer -Identity "$ComputerName" -Confirm
}

# Get all matching SCCM entries
$YSCCMDevices = SCCMFindAll($XAssetTag)
# Get all matching AD entries
$YADDevices = ADFindAll($XAssetTag)

# Exit if nothing was found
if ($YSCCMDevices.Count -eq 0 -and $YADDevices.Count -eq 0) {
    Write-Output "No matching devices found for asset tag [$XAssetTag].`nIt is likely that the device you are trying to remove has already been deleted.`n`nExiting..."
    Exit
}

Write-Output "`n`nRemoving devices from SCCM..."
Write-Output "`tPlease confirm each entry before removal."
Write-Output "`n`n`tWARNING: ENSURE DEVICE NAMES ARE CORRECT BEFORE REMOVAL."
Write-Output "`tTHE FOLLOWING OPERATIONS CANNOT BE UNDONE (easily)."
Write-Output "`n`n"

# Traverse SCCM devices and remove
foreach($Device in $YSCCMDevices) {
    SCCMRemoveAsset($Device.Name)
}

Write-Output "`n`nRemoving devices from Active Directory..."
Write-Output "`tPlease confirm each entry before removal."
Write-Output "`n`n`tWARNING: ENSURE DEVICE NAMES ARE CORRECT BEFORE REMOVAL."
Write-Output "`n`n"

# Traverse AD devices and remove
foreach($Device in $YADDevices) {
    ADRemoveObject($Device.Name)
}

Write-Output "Done - $($Device.Name) removed. Exiting..."
Exit