taskkill /f /im OneDrive.exe
& "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" /uninstall

# Take Ownsership of OneDriveSetup.exe
$ACL = Get-ACL -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe
$Group = New-Object System.Security.Principal.NTAccount("$env:UserName")
$ACL.SetOwner($Group)
Set-Acl -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe -AclObject $ACL

# Assign Full R/W Permissions to $env:UserName (Administrator)
$Acl = Get-Acl "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$env:UserName","FullControl","Allow")
$Acl.SetAccessRule($Ar)
Set-Acl "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" $Acl

# Take Ownsership of OneDrive.ico
$ACL = Get-ACL -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe
$Group = New-Object System.Security.Principal.NTAccount("$env:UserName")
$ACL.SetOwner($Group)
Set-Acl -Path $env:SystemRoot\SysWOW64\OneDriveSetup.exe -AclObject $ACL

# Assign Full R/W Permissions to $env:UserName (Administrator)
$Acl = Get-Acl "$env:SystemRoot\SysWOW64\OneDrive.ico"
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("$env:UserName","FullControl","Allow")
$Acl.SetAccessRule($Ar)
Set-Acl "$env:SystemRoot\SysWOW64\OneDrive.ico" $Acl

REG Delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f
REG Delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f

Remove-Item -Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" -Force -ErrorAction SilentlyContinue
Write-Output "OneDriveSetup.exe Removed"
Remove-Item -Path "$env:SystemRoot\SysWOW64\OneDrive.ico" -Force -ErrorAction SilentlyContinue
Write-Output "OneDrive Icon Removed"
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Write-Output "USERProfile\OneDrive Removed" 
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Write-Output "LocalAppData\Microsoft\OneDrive Removed" 
Remove-Item -Path "$env:ProgramData\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Write-Output "ProgramData\Microsoft OneDrive Removed" 
Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
Write-Output "C:\OneDriveTemp Removed" 