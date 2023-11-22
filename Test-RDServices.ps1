$Svc_RDConnectionBroker = Get-Service -Name Tssdis
$Svc_RDGateway = Get-Service -Name TSGateway

$LogFilePath = "C:\Temp\RDSServiceStatus.txt"
function Write-Log {
    param (
        [string]$MessageString
    )

    Write-Output "[$(Get-Date)] $MessageString" | Out-File -Append $LogFilePath
}

If ($Svc_RDConnectionBroker.Status -ne "Running") {
    # Start Tssdis service

    Start-Service -Name Tssdis

    Write-Log -MessageString "Tssdis was stopped. It has been started."
} Else {
    Write-Log -MessageString "Tssdis was running. Nothing to do."
}

If ($Svc_RDGateway.Status -ne "Running") {
    # Start TSGateway service

    Start-Service -Name TSGateway
    
    Write-Log -MessageString "TSGateway was stopped. It has been started."
} Else {
    Write-Log -MessageString "TSGateway was running. Nothing to do."
}