#################################
# Archive Orphaned VMware Disks #
#                               #
# github.com/transiient         #
#################################

param (
    [string]$RvToolsCsvFile,
    [string]$VCenterServerUri
)

if ($VCenterServerUri -ne "") {
    Connect-ViServer -Server $VCenterServerUri
}

# Filter Zombie disks from CSV
$RvtCsv = Import-Csv -Path $RvToolsCsvFile
$Zombies = $RvtCsv | Where-Object "Message type" -eq "Zombie"

$DatastoreMountPoints = @(
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol01"
        PSDriveName = "ds_prodvol01"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol02"
        PSDriveName = "ds_prodvol02"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol03"
        PSDriveName = "ds_prodvol03"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol04"
        PSDriveName = "ds_prodvol04"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol05"
        PSDriveName = "ds_prodvol05"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol06"
        PSDriveName = "ds_prodvol06"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Prodvol08"
        PSDriveName = "ds_prodvol08"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMware_Prodvol09"
        PSDriveName = "ds_prodvol09"
    }
    [hashtable]@{
        DatastoreName = "HPE_VMWare_Templates"
        PSDriveName = "ds_templates"
    }
)

$ExceptionFiles = @(
    "chppac2022w"
    "CHPPROOT01W"
    "CHVDSERVEAP01L"
    "LEAWEBIIS01W Mig Test"
    "CHPDC05W"
    "CHAZMIGLNX01W"
    "CHPAZMIG01W"
    "Windows 10 V2004 Template V1"
    "CHPFMGTEST01L"
    "PRD-SRV-RAS-04-OLD"
    "CH-HWYS2"
)

class DatastoreMap {
    [string]$Name
    [string]$MountPoint
    [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.Datastore]$Datastore
    [System.Management.Automation.PSDriveInfo]$PSDrive

    DatastoreMap(
        [string]$Name,
        [string]$MountPoint
    ) {
        $this.Name = $Name
        $this.MountPoint = $MountPoint
    }

    [System.Management.Automation.PSDriveInfo]MountDatastore() {
        Write-Output "Mounting Datastore"
        Write-Output $this.Name

        $_Datastore = Get-Datastore -Name $this.Name
        $_DatastorePSDrive = ($_Datastore | New-DatastoreDrive -Name $this.MountPoint)

        $this.Datastore = $_Datastore
        $this.PSDrive = $_DatastorePSDrive

        return $this.PSDrive
    }

    [VMware.VimAutomation.ViCore.Types.V1.DatastoreManagement.Datastore]GetDatastore() {
        return $this.Datastore
    }

    [System.Management.Automation.PSDriveInfo]GetPSDrive() {
        return $this.PSDrive
    }

    [void]UnmountDatastore() {
        Remove-PSDrive $this.PSDrive
    }
}

# Unmount All Datastores
function UnmountAllDatastores {
    Remove-PSDrive "ds_prod*"
    Remove-PSDrive "ds_templates"
}

# Mount Datastores
function MountDatastores {
    [System.Collections.ArrayList]$DatastoreMounts = @()

    Foreach ($DatastoreMapping in $DatastoreMountPoints) {
        $_DS = [DatastoreMap]::New(
            $DatastoreMapping.DatastoreName,
            $DatastoreMapping.PSDriveName
        )

        $_DS.MountDatastore()

        $DatastoreMounts.Add($_DS)
    }

    return $DatastoreMounts
}

UnmountAllDatastores

$DatastoreMounts = (MountDatastores)

Write-Output "Iterating Zombie entries..."

Foreach ($Zombie in $Zombies) {
    $Zombie.Name -Match '\[(.*?)\]\s(.*)' | Out-Null

    $_ZombieDatastore = $matches[1]
    $_ZombiePath = $matches[2]

    Write-Output "`tCurrent: [$_ZombieDatastore] $_ZombiePath"

    [hashtable]$_ZombieMountedDatastore = $null
    Foreach ($DatastoreMapping in $DatastoreMountPoints) {
        If ($DatastoreMapping.DatastoreName -eq $_ZombieDatastore) {
            $_ZombieMountedDatastore = $DatastoreMapping
        }
    }
    If ($_ZombieDatastore -eq "") {
        Throw("Datastore not found.")
    }

    $_PSDriveName = $_ZombieMountedDatastore.PSDriveName

    # Check exceptions list
    $IsInExceptions = $false
    Foreach ($ExceptionItem in $ExceptionFiles) {
        If ($_ZombiePath -Like "*$ExceptionItem*") {
            $IsInExceptions = $true

            Continue
        }
    }

    If ($IsInExceptions -eq $true) {
        Write-Warning "Skipping ${_PSDriveName}:/$_ZombiePath as it's included in the Exceptions List."
    }
    Else {
        # Full original path of the Zombie file
        # $_ZombieFullPath = "${_PSDriveName}/$_ZombiePath"
        # Name of the directory the original Zombie file is located in, relative to Datastore, and not including filename
        $_DirName = $_ZombiePath.Substring(0, $_ZombiePath.LastIndexOf('/'))

        Write-Output "Testing directory: ds_templates:/VMDK_Removed/${_PSDriveName}/$_DirName"

        If (!(Test-Path "ds_templates:/VMDK_Removed/${_PSDriveName}/$_DirName")) {
            Write-Warning "Directory doesn't exist. Creating ds_templates:/VMDK_Removed/${_PSDriveName}/$_DirName ..."
            New-Item -ItemType Directory -Force -Path "ds_templates:/VMDK_Removed/${_PSDriveName}/$_DirName"
        }

        Move-Item -Path "${_PSDriveName}:/$_ZombiePath" -Destination "ds_templates:/VMDK_Removed/${_PSDriveName}/$_ZombiePath"
    }
}

UnmountAllDatastores

Exit