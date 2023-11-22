param (
    # $SubscriptionName - Azure Subscription name
    [string]$SubscriptionName = ""
)

If ($SubscriptionName -ne "") {
    Write-Output ("Azure Subscription set to: " + (Set-AzContext -Subscription $SubscriptionName).Subscription.Name)
}

$AutoAccounts = Get-AzAutomationAccount

$Runbooks = @()

Foreach ($AutoAccount in $AutoAccounts) {
    $Runbooks += Get-AzAutomationRunbook -ResourceGroupName $AutoAccount.ResourceGroupName -AutomationAccountName $AutoAccount.AutomationAccountName
}

$Runbooks | Export-Csv -NoClobber -NoTypeInformation "Runbooks_$($SubscriptionName).csv"