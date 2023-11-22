$ServersList = @(
    "fs-sensitive",
    "fs-central",
    "fs-support",
    "fs-archive"
)

foreach ($Server in $ServersList) {
    $Shares = Invoke-Command -ComputerName $Server -ScriptBlock { Get-SmbShare }

    $(Foreach($Share in $Shares) {
        $ExportTable = [ordered]@{
            "Name" = $Share.Name
            "Path" = $Share.Path
            "Desc" = $Share.Description
        }
    })

    $Shares | Export-Csv -NoTypeInformation ("C:\Temp\SHARES-{0}.csv" -f $Server)
}