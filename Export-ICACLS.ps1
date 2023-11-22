$Drives = Get-PSDrive -PSProvider FileSystem

ForEach ($Drive in $Drives) {
    icacls "$($Drive.Name):\" /save "C:\Temp\icacls.$($Drive.Name).txt" /t /c
}