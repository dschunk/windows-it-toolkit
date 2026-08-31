$publicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File

foreach ($function in $publicFunctions) {
    . $function.FullName
}

Export-ModuleMember -Function @(
    'Compare-SchunkIncidentBundle'
    'Get-SchunkADReplicationHealth'
    'Get-SchunkBitLockerInventory'
    'Get-SchunkDiskPressure'
    'Get-SchunkDomainTrustStatus'
    'Get-SchunkEndpointTriage'
    'Get-SchunkEventTriage'
    'Get-SchunkInstalledSoftware'
    'Get-SchunkListeningPort'
    'Get-SchunkLocalAdministrator'
    'Get-SchunkLogonFailure'
    'Get-SchunkPendingReboot'
    'Get-SchunkScheduledTaskAudit'
    'Get-SchunkServerHealth'
    'Get-SchunkServiceFailure'
    'Get-SchunkWindowsUpdateHistory'
    'New-SchunkIncidentBundle'
    'Test-SchunkDnsClient'
    'Test-SchunkNetworkPath'
    'Test-SchunkTlsEndpoint'
)
