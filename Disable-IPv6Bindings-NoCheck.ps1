$EnableTest = $false

# List network adapter bindings
$EnabledBindings = (Get-NetAdapterBinding | Where-Object {
    ($_.ComponentID -eq 'ms_tcpip6') -and
    ($_.Enabled -eq $true)
})

# Write existing bindings to a CSV file in case a restore is required
if (!(Test-Path -Path "C:\Temp")) {
    mkdir "C:\Temp"
}

$EnabledBindings | Export-Csv -NoClobber -Path "C:\Temp\EnabledBindings.csv"

# Disable IPv6 binding for all adapters
function DisableIPv6 {
    Foreach ($_Binding in $EnabledBindings) {
        $_BindingName = $_Binding.Name

        Write-Information "Disabling ms_tcpip6 binding on adapter $_BindingName..."
        Disable-NetAdapterBinding -Name $_BindingName -ComponentID 'ms_tcpip6'
    }
}

# Enable IPv6 binding for all adapters
function EnableIPv6 {
    Foreach ($_Binding in $EnabledBindings) {
        $_BindingName = $_Binding.Name

        Write-Information "Enabling ms_tcpip6 binding on adapter $_BindingName..."
        Enable-NetAdapterBinding -Name $_BindingName -ComponentID 'ms_tcpip6'
    }
}

# Disable IPv6 bindings
DisableIPv6

If ($EnableTest -eq $true) {
    Write-Output "IPv6 Bindings removed from all adapters. Now sleeping for 120 seconds."
    Write-Output "Once the timer expires, any changes made to the system will automatically REVERT."
    Write-Output "TO KEEP CHANGES, press Ctrl+C NOW to exit."

    Start-Sleep -Seconds 120

    Write-Output "No input detected. Reverting changes..."

    EnableIPv6

    Write-Output "Reverted changes. Waiting for user input..."

    Pause
}

Exit 0