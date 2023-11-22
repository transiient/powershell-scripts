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

Write-Output $DatastoreMounts

Sleep 5s

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

    # Write-Output "**MOVE OPERATION (what if)**" "Path: ds_templates:/VMDK_Removed/${_PSDriveName}/$_ZombiePath" "Destination: ${_PSDriveName}:/$_ZombiePath" 
    Move-Item -Path "ds_templates:/VMDK_Removed/${_PSDriveName}/$_ZombiePath" -Destination "${_PSDriveName}:/$_ZombiePath"
}

UnmountAllDatastores

Exit