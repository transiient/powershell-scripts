###
##
## Remove Azure Orphaned Backup Items
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
    [string]$OutputCsv = "./AzureRemovedOrphanedBackupItems.csv",
    # $RemoveStopped - remove protection points older than 60d for ProtectionStopped Backup Items
    [System.Boolean]$RemoveStopped = $true
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
        $BackupItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -Container $_Container

        $FriendlyName = $_Container.FriendlyName
        $ResourceGroupName = $_Container.ResourceGroupName
        $BackupItemName = $BackupItem.Name
        $BackupItemProtectionState = $BackupItem.ProtectionState
        $BackupItemLatestRecoveryPoint = $BackupItem.LatestRecoveryPoint

        If (
            ($null -ne $BackupItem.LatestRecoveryPoint) -and
            (Get-Date $BackupItem.LatestRecoveryPoint -Format "MM/dd/yyyy hh:mm:dd") -lt $OrphanDate
        ) {
            Write-Output "$FriendlyName : Latest recovery point is $BackupItemLatestRecoveryPoint"

            $OrphanedBackupItems.Add([ordered]@{
                SubscriptionName = $SubscriptionName
                RecoveryServicesVaultName = $_RSV.Name
                ContainerResourceGroupName = $ResourceGroupName
                ContainerName = $FriendlyName
                BackupItemName = $BackupItemName
                PreviousProtectionState = $BackupItemProtectionState
            }) | Out-Null

            If ($BackupItemProtectionState -eq "Protected") {
                Write-Output "`t$FriendlyName : Protection was enabled. Stopping protection and removing recovery points..."

                Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -RemoveRecoveryPoints
            }
            Elseif ($BackupItemProtectionState -eq "ProtectionStopped") {
                If ($RemoveStopped -eq $false) {
                    Write-Output "`t$FriendlyName : Protection was Stopped. Keeping old recovery points - RemoveStopped is False"
                }
                Else {
                    Write-Output "`t$FriendlyName : Protection was Stopped. Removing old recovery points..."

                    Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -RemoveRecoveryPoints
                }
            }
            Else {
                Write-Warning "`t$FriendlyName : ProtectionState was $BackupItemProtectionState. Stopping protection..."

                Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -RemoveRecoveryPoints
            }
    
            # Warn user if the protected Resource still exists.
            If (Get-AzResource -ResourceGroupName $ResourceGroupName -Name $FriendlyName -ErrorAction SilentlyContinue) {
                Write-Warning "`tA resource named $FriendlyName in Resource Group $ResourceGroupName still exists.`nThis backup item may have had its protection disabled. Please enable it again if required."
            }
        }

        If ($null -eq $BackupItem.LatestRecoveryPoint) {
            Write-Warning "`t$FriendlyName : VM has no recovery points. Its ProtectionState was: $BackupItemProtectionState. Stopping protection..."

            Disable-AzRecoveryServicesBackupProtection -Item $BackupItem -RemoveRecoveryPoints
        }
    }
}

Write-Output ("A total of " + $OrphanedBackupItems.Count + " orphaned backup items were deleted.")

Write-Output "Exporting CSV file to $OutputCsvFinalPath..."
$OrphanedBackupItems | Export-Csv -NoTypeInformation -NoClobber -Path $OutputCsvFinalPath -Force