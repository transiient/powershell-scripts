If ((Test-Path -Path "C:\Temp") -eq $false) {
    New-Item -ItemType Directory -Path "C:\Temp"
}

Copy-Item -Path "\\ch-fs9\ITSC_Data\Drivers\Win10_64Bit\Lenovo\ThinkPad USB 3.0 Basic Ultra Pro Dock\Setup.exe" -Destination "C:\Temp\Setup.exe"

$app = Get-WmiObject -Class Win32_Product -Filter "Name = 'DisplayLink Graphics Driver'"
$app.Uninstall()

Start-Process -Verb RunAs C:\Temp\Setup.exe | Out-Null

Exit 0