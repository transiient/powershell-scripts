$ServersList = @(
    "fs-sensitive",
    "fs-central",
    "fs-support",
    "fs-archive"
)

Foreach ($Server in $ServersList) {
    $Shares = Invoke-Command -ComputerName $Server -ScriptBlock { Get-SmbShare }

    Foreach ($Share in $Shares) {
        write-output "${Share.Name}"
        If ($Share.Description -eq "") {

            Write-Output ("Scanning \\{0}\{1} ..." -f $Server, $Share.Name)
            ./Get-LastAccessData.ps1 -Path ("\\{0}\{1}" -f $Server, $Share.Name) -CsvDir "C:\Temp\_LastFSAccess"
        }
    }
}