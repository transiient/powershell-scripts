param (
    [Parameter(Mandatory=$true)][string]$ResourceGroupName,
    [Parameter(Mandatory=$true)][string]$SyncServiceName,
    [string]$ExportCsvPath = ""
)

$StorageSyncGroups = Get-AzStorageSyncGroup -ResourceGroupName $ResourceGroupName -StorageSyncServiceName $SyncServiceName

$Objects = foreach ($_SSG in $StorageSyncGroups) {
    $_SSE = Get-AzStorageSyncServerEndpoint -ResourceGroupName $ResourceGroupName -StorageSyncServiceName $SyncServiceName -SyncGroupName $_SSG.SyncGroupName

    New-Object -TypeName PSObject -Property @{
        SyncGroupName = $_SSG.SyncGroupName
        SyncServerName = $_SSE.FriendlyName
        SyncServerLocalPath = $_SSE.ServerLocalPath
        CloudTiering = $_SSE.CloudTiering
    } | Select-Object SyncGroupName,SyncServerName,SyncServerLocalPath,CloudTiering
}

If ($ExportCsvPath -ne "") {
    $Objects | Export-Csv -NoTypeInformation -NoClobber "${ExportCsvPath}"
}
Else {
    $Objects
}