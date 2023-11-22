param (
    [Parameter(Mandatory=$true)]
        [string]$Path,
    [Parameter(Mandatory=$true)]
        [string]$CsvDir
)

$DateNow = Get-Date
$Path = (Resolve-Path $Path).ProviderPath
$PathSplit = $Path.Split('\')
if ((Resolve-Path $Path).ProviderPath.StartsWith("\\")) {
    $CsvName = ("Export-{0}-{1}.csv" -f $PathSplit[2], $PathSplit[3]) # UNC path (network share)
}
Else {
    $CsvName = ("Export-{0}-{1}.csv" -f $PathSplit[1], $PathSplit[2]) # Local
}

If (Test-Path -Path "${CsvDir}\${CsvName}" -PathType Leaf) {
    # Exists
    Write-Warning "${CsvDir}\${CsvName} already exists - skipping."
} Else {
    try {
        # don't -Recurse, just go somewhat-deep:
        $Children = (Get-ChildItem -Path "$Path\*\*\*","$Path\*\*","$Path\*" | Select-Object -Property LastAccessTime,LastWriteTime,FullName,PSIsContainer, @{N='Owner';E={$_.GetAccessControl().Owner}})
    } catch [UnauthorizedAccessException] {
        Write-Error -Message "Access denied: ${_.Path}"
    }

    try {
        $(Foreach ($Child in $Children) {
            $SplitName = $Child.FullName.Split('\')

            $ExportTable = [ordered]@{
                "6MonthWrite" = $false;
                "6MonthAccess" = $false;
                "LastWriteTime" = $Child.LastWriteTime;
                "LastAccessTime" = $Child.LastAccessTime;
                "Owner" = $Child.Owner;
                "IsDirectory" = $Child.PSIsContainer;
                "FullName" = $Child.FullName;
            }

            # Check last 6 months
            If ($Child.LastAccessTime -gt $DateNow.AddMonths(-6)) {
                $ExportTable["6MonthAccess"] = $true;
            }
            If ($Child.LastWriteTime -gt $DateNow.AddMonths(-6)) {
                $ExportTable["6MonthWrite"] = $true;
            }

            # Add each name portion as a new column
            For ($p = 0; $p -lt $SplitName.Length + 1; $p++) {
                $ExportTable.Add("Path$p", $SplitName[$p])
            }

            New-Object psobject -Property $ExportTable
        }) | Export-Csv -Path "${CsvDir}\${CsvName}" -NoTypeInformation

        Write-Output "Written CSV to: ${CsvDir}\${CsvName}"
    } catch {
        Write-Error -Message "Error: ${_.Message}"
    }
}

