$EnableTest = $true

# List network adapter bindings
$EnabledBindings = (Get-NetAdapterBinding | Where-Object {
    ($_.ComponentID -eq 'ms_tcpip6') -and 
    ($_.Enabled -eq $true)
})

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

# Test network connection to ensure same results afterwards
$TNCPreResultInternet = (Test-NetConnection google.com -Port 443).TcpTestSucceeded
$TNCPreResultDC = (Test-NetConnection 172.30.1.10 -Port 88).TcpTestSucceeded

If (
    ($TNCPreResultInternet -eq $false) -and ($TNCPreResultDC -eq $false)
) {
    Write-Error "Both TCP Tests failed. There would be no check for whether changes need to be reverted. Exiting..."
    Exit 1
}

# Disable IPv6 bindings
DisableIPv6

# Test network connection, following change
$TNCPostResultInternet = (Test-NetConnection google.com -Port 443).TcpTestSucceeded
$TNCPostResultDC = (Test-NetConnection 172.30.1.10 -Port 88).TcpTestSucceeded

If (
    ($TNCPreResultInternet -ne $TNCPostResultInternet) -or
    ($TNCPreResultDC -ne $TNCPostResultDC)
) {
    Write-Warning "A TCP test result has changed. Reverting changes..."

    EnableIPv6

    Write-Warning "Reverted changes. Exiting..."
    Exit 1
}

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