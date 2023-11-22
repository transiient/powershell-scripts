$myShell = New-Object -ComObject Wscript.Shell
$minutes = 99999
Add-Type -AssemblyName System.Windows.Forms
for ($i = 0; $i -lt $minutes; $i++) {
Start-Sleep -Seconds 30
$Pos = [System.Windows.Forms.Cursor]::Position
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point((($Pos.X) + 1), $Pos.Y)
$myShell.sendkeys("{F13}")
}