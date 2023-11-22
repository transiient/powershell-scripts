###
##
## Get Azure Orphaned Backup Items
## github.com/transiient 
##
## To run against all your Azure Subscriptions, you can use:
## > Foreach ($Sub in Get-AzSubscription) { .\Get-AzureOrphanedBackupItems.ps1 -SubscriptionName $Sub.Name }
## Subscription names are always automatically appended to the OutputCsv filename, along with datetime
##
###

param (
    # $SubscriptionName - Azure Subscription name
    [string]$SubscriptionName = "",
    # $Days - the number of days before a Backup Item is considered an orphan 
    [Int32]$Days = 60,
    # $OutputCsv - the path for the output CSV file (overwrite by default)
    [string]$OutputCsv = "./AzureOrphanedBackupItems.csv"
)

If ($SubscriptionName -ne "") {
    Write-Output ("Azure Subscription set to: " + (Set-AzContext -Subscription $SubscriptionName).Subscription.Name)
}

$OrphanDate = (Get-Date).AddDays(-$Days)
$SubscriptionName = (Get-AzContext).Subscription.Name

# Avoid possible OutputCsv file name conflicts when looping over all subscriptions
Start-Sleep -Seconds 1

$OutputCsvDirName  = [io.path]::GetDirectoryName($OutputCsv)
$OutputCsvFileName = [io.path]::GetFileNameWithoutExtension($OutputCsv)
$OutputCsvFinalPath = "$OutputCsvDirName\$OutputCsvFileName" + "_" + $SubscriptionName + "_" + (Get-Date -Format "yyyy-MM-dd_HHmmss") + ".csv"

If ((Test-Path $OutputCsvDirName) -eq $false) {
    Write-Output "OutputCsv path does not exist. Creating it..."

    try {
        New-Item -ItemType Directory -Path $OutputCsvDirName -Force
    } catch {
        Write-Error "Could not create OutputCsv directory. Please create it manually and re-run, or change the target directory. Exiting..."
        Exit 1
    }
}

$RecoveryServicesVaults = Get-AzRecoveryServicesVault
$OrphanedBackupItems = [System.Collections.ArrayList]@()

foreach ($_RSV in $RecoveryServicesVaults) {
    Write-Output ("Currently scanning " + $_RSV.Name + "...")

    Set-AzRecoveryServicesVaultContext -Vault $_RSV

    $BackupContainers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM

    foreach ($_Container in $BackupContainers) {
        $BackupItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -Container $_Container | Select-Object Name, ProtectionState, LatestRecoveryPoint

        $FriendlyName = $_Container.FriendlyName
        $BackupItemName = $BackupItem.Name
        $BackupItemProtectionState = $BackupItem.ProtectionState
        $BackupItemLatestRecoveryPoint = $BackupItem.LatestRecoveryPoint
        
        If ($BackupItem.ProtectionState -ne "Protected" -and $BackupItem.ProtectionState -ne "ProtectionStopped") {
            Write-Warning "`tThe ProtectionState of $FriendlyName is unusual ($BackupItemProtectionState). Adding anyway..."

            $OrphanedBackupItems.Add([ordered]@{
                SubscriptionName = $SubscriptionName
                RecoveryServicesVaultName = $_RSV.Name
                ContainerName = $FriendlyName
                BackupItemName = $BackupItemName
                ProtectionState = $BackupItemProtectionState
                LatestRecoveryPoint = ""
            }) | Out-Null
        }

        If ($null -eq $BackupItem.LatestRecoveryPoint) {
            Write-Warning "`t$FriendlyName : VM has never had a recovery point created. Its ProtectionState is: $BackupItemProtectionState."
        }

        If (
            ($null -ne $BackupItem.LatestRecoveryPoint) -and
            (Get-Date $BackupItem.LatestRecoveryPoint -Format "MM/dd/yyyy hh:mm:dd") -lt $OrphanDate
        ) {
            # Out-Null suppresses the index output of the Add method
            $OrphanedBackupItems.Add([ordered]@{
                SubscriptionName = $SubscriptionName
                RecoveryServicesVaultName = $_RSV.Name
                ContainerName = $FriendlyName
                BackupItemName = $BackupItemName
                ProtectionState = $BackupItemProtectionState
                LatestRecoveryPoint = $BackupItemLatestRecoveryPoint
            }) | Out-Null

            If ($BackupItemProtectionState -eq "Protected") {
                Write-Output "`t$FriendlyName : VM is Protected. Its latest recovery point is over $Days days ago ($BackupItemLatestRecoveryPoint)"
            }
            Elseif ($BackupItemProtectionState -eq "ProtectionStopped") {
                Write-Output "`t$FriendlyName : Protection is Stopped. Its latest recovery point is over $Days days ago ($BackupItemLatestRecoveryPoint)"
            }
            Else {
                Write-Output "`t$FriendlyName : Protection is Stopped. Its latest recovery point is over $Days days ago ($BackupItemLatestRecoveryPoint)"
            }
        }
    }
}

Write-Output ("A total of " + $OrphanedBackupItems.Count + " orphaned backup items were found.")

Write-Output "Exporting CSV file to $OutputCsvFinalPath..."
$OrphanedBackupItems | Export-Csv -NoTypeInformation -NoClobber -Path $OutputCsvFinalPath -Force