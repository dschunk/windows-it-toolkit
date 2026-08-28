$publicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File

foreach ($function in $publicFunctions) {
    . $function.FullName
}

Export-ModuleMember -Function @(
    'Compare-SchunkIncidentBundle'
    'Get-SchunkBitLockerInventory'
    'Get-SchunkEventTriage'
    'Get-SchunkInstalledSoftware'
    'Get-SchunkListeningPort'
    'Get-SchunkLogonFailure'
    'Get-SchunkPendingReboot'
    'Get-SchunkScheduledTaskAudit'
    'Get-SchunkServerHealth'
    'Get-SchunkServiceFailure'
    'Get-SchunkWindowsUpdateHistory'
    'New-SchunkIncidentBundle'
    'Test-SchunkNetworkPath'
    'Test-SchunkTlsEndpoint'
)
