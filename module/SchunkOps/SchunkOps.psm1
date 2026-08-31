$publicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File

foreach ($function in $publicFunctions) {
    . $function.FullName
}

Export-ModuleMember -Function @(
    'Compare-SchunkIncidentBundle'
    'Get-SchunkAccountLockoutTrace'
    'Get-SchunkADReplicationHealth'
    'Get-SchunkBitLockerInventory'
    'Get-SchunkClusterHealth'
    'Get-SchunkDhcpDnsConsistency'
    'Get-SchunkDiskPressure'
    'Get-SchunkDomainTrustStatus'
    'Get-SchunkEndpointTriage'
    'Get-SchunkEventTriage'
    'Get-SchunkFleetHealth'
    'Get-SchunkGpoChangeAudit'
    'Get-SchunkInstalledSoftware'
    'Get-SchunkKerberosSpnAudit'
    'Get-SchunkListeningPort'
    'Get-SchunkLocalAdministrator'
    'Get-SchunkLogonFailure'
    'Get-SchunkPendingReboot'
    'Get-SchunkScheduledTaskAudit'
    'Get-SchunkServerHealth'
    'Get-SchunkServiceFailure'
    'Get-SchunkVSphereInventory'
    'Get-SchunkWindowsUpdateHistory'
    'New-SchunkIncidentBundle'
    'Test-SchunkCertificateChain'
    'Test-SchunkDnsClient'
    'Test-SchunkNetworkPath'
    'Test-SchunkTlsEndpoint'
)
