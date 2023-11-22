Write-Host "Add devices to MIPPilotDevices`n`n"

function PromptADComputer {
    Write-Host "Enter the computer name below (EG: 1023456X) or press Ctrl+C to exit."
    $ADComputerName = Read-Host -Prompt "Computer Name"

    $ADComputer = Get-ADComputer -Filter {Name -eq $ADComputerName}

    return ($ADComputer)
}

function AddGroupMember {
    param (
        $ADComputer
    )

    Add-ADGroupMember -WhatIf -Identity MIPPilotDevices -Members $ADComputer

    Write-Host "[Success]`tAdded member $($ADComputer.Name) to MIPPilotDevices group.`n`n"
}

while ($true) {
    $ADComputer = PromptADComputer
    AddGroupMember($ADComputer)
}