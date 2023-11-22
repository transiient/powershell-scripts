param (
    [string]$CsvFilePath = "C:\Temp\Get-LocalShareConnections.csv"
)

$Today = (Get-Date -Format o)

$ShareAccessData = Get-WmiObject Win32_ServerConnection | Select-Object ShareName,ComputerName,UserName,Path,NumberOfFiles

foreach ($_SAD in $ShareAccessData) {
    $_SAD | Add-Member -MemberType NoteProperty -Name DateTime -Value "$Today"
}

$ShareAccessData | Export-Csv -NoTypeInformation -NoClobber -Append $CsvFilePath
