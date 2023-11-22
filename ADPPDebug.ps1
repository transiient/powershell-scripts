Start-Transcript -Append "C:\Temp\ADPP_Debug.log"

# Current computer name
$ComputerNameCurrent = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName -Name ComputerName
# New computer name
$ComputerNameNew = Get-ItemProperty -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName -Name ComputerName
# They should match

If ($ComputerNameCurrent.ComputerName -eq $ComputerNameNew.ComputerName) {
    Write-Output "Current computer name $($ComputerNameCurrent.ComputerName) matches new name $($ComputerNameNew.ComputerName)"
}

try {
    Get-ItemProperty `
        -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon `
        -Name JoinDomain `
        -ErrorAction SilentlyContinue
    
    if ($?) {
        Write-Output "JoinDomain key exists"
    } else {
        throw $error[0].Exception
    }
} catch {
    Write-Warning "JoinDomain key does not exist"
}

# Take a copy of HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet anyway... (This seems useless)
#Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\ComputerName -Recurse | Export-Clixml "C:\Temp\ADPP_Debug.CurrentControlSet.Control.reg.bak"
#Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Netlogon -Recurse | Export-Clixml "C:\Temp\ADPP_Debug.CurrentControlSet.Services.reg.bak"