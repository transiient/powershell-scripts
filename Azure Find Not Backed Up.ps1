# Find VMs which aren't backed up by Azure
#
# https://github.com/transiient

param (
    # $SubscriptionName - Azure Subscription name
    [string]$SubscriptionName = ""
)

If ($SubscriptionName -ne "") {
    Write-Output ("Azure Subscription set to: " + (Set-AzContext -Subscription $SubscriptionName).Subscription.Name)
}

$SubscriptionName = (Get-AzContext).Subscription.Name

# Enumerate all VMs in all backup vaults within the subscription
$VMIDs_AllVaults_Active = @()
$VMIDs_AllVaults_Outdated = @()
foreach ($VaultResource in (Get-AzResource -ResourceType "Microsoft.RecoveryServices/vaults")) {
    Write-Output "Searching Vault $($VaultResource.Name)..."

    Get-AzRecoveryServicesVault -Name $VaultResource.Name -ResourceGroupName $VaultResource.ResourceGroupName | Set-AzRecoveryServicesVaultContext

    $VaultContainers = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM"

    Foreach ($VaultContainer in $VaultContainers) {
        # Read whether a backup item exists
        $BackupItem = Get-AzRecoveryServicesBackupItem -Container $VaultContainer -WorkloadType "AzureVM" | Select-Object VirtualMachineId,LatestRecoveryPoint

        # Check its date is within the last 5 days. (LatestRecoveryPoint is DateTime)
        If ($BackupItem.LatestRecoveryPoint -gt (Get-Date).AddDays(-5)) {
            # Add to Active backups list, as the last backup was within the last 5 days
            $VMIDs_AllVaults_Active += $BackupItem.VirtualMachineId
        } Else {
            # Hasn't had a backup in the last 5 days, so add to Outdated list
            $VMIDs_AllVaults_Outdated += $BackupItem.VirtualMachineId
        }

    }
}

# Get all VMs in subscription - don't filter by RSG
$VMs = Get-AzVM

# Log every VM which is not found in All Vaults
Foreach ($VMResource in $VMs) {
    # Check whether VMResource.Id is in $VMIDs_AllVaults_Active...
    $j = 0;
    For ($i=0; $i -lt $VMIDs_AllVaults_Active.Count; $i++) {
        If ($VMResource.Id -eq $VMIDs_AllVaults_Active[$i]) { $j++ }
    }

    # Check if it's in $VMIDs_AllVaults_Outdated...
    $k = 0;
    For ($i=0; $i -lt $VMIDs_AllVaults_Outdated.Count; $i++) {
        If ($VMResource.Id -eq $VMIDs_AllVaults_Outdated[$i]) { $k++ }
    }

    # If it's in neither (neither count increased because they didn't find anything), then assume it has never had a backup
    If ($j -eq 0 -and $k -eq 0) {
        Write-Host "Virtual Machine $($VMResource.Name) - NOT BACKED UP - this VM needs attention, please assess"
        Write-Output "$($VMResource.Name)" >> "C:\Temp\AzureVMsBackupNonExistent-$($SubscriptionName).txt"
    }

    # If it's in Outdated, then it has a backup, but it's old and needs attention
    If ($j -eq 0 -and $k -gt 0) {
        Write-Host "Virtual Machine $($VMResource.Name) - OUTDATED - last backup was over 5 days ago"
        Write-Output "$($VMResource.Name)" >> "C:\Temp\AzureVMsBackupOutdated-$($SubscriptionName).txt"
    }

    # If ($j -gt 0 -and $k -gt 0) {
    #     Write-Host "Virtual Machine $($VMResource.Name) is in a backup vault, and last backed up less than 5 days ago"
    # }
}