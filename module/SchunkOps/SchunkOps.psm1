$publicFunctions = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File

foreach ($function in $publicFunctions) {
    . $function.FullName
}

Export-ModuleMember -Function @(
    'Get-SchunkBitLockerInventory'
    'Get-SchunkEventTriage'
    'Get-SchunkInstalledSoftware'
    'Get-SchunkListeningPort'
    'Get-SchunkPendingReboot'
    'Get-SchunkScheduledTaskAudit'
    'Get-SchunkServerHealth'
    'Get-SchunkWindowsUpdateHistory'
    'Test-SchunkNetworkPath'
    'Test-SchunkTlsEndpoint'
)
