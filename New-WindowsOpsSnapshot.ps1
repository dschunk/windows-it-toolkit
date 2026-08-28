[CmdletBinding()]
param(
    [string]$OutputDirectory=(Join-Path $PWD "WindowsOps-$((Get-Date).ToString('yyyyMMdd-HHmmss'))")
)

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$collectors=[ordered]@{
    SystemInventory='Get-SystemInventory.ps1'
    ServerHealth='Get-ServerHealth.ps1'
    PendingReboot='Get-PendingReboot.ps1'
    ListeningPorts='Get-ListeningPortReport.ps1'
    ScheduledTasks='Get-ScheduledTaskAudit.ps1'
    FirewallExposure='Get-FirewallExposure.ps1'
    WindowsUpdateHistory='Get-WindowsUpdateHistory.ps1'
    SmbShares='Get-SmbShareInventory.ps1'
    BitLocker='Get-BitLockerInventory.ps1'
}

$manifest=[ordered]@{ComputerName=$env:COMPUTERNAME;StartedAt=(Get-Date).ToString('o');Collectors=@()}
foreach($name in $collectors.Keys){
    $scriptPath=Join-Path $PSScriptRoot $collectors[$name]
    $entry=[ordered]@{Name=$name;Script=$collectors[$name];Succeeded=$false;Error=$null}
    try{
        if(-not (Test-Path $scriptPath)){throw "Collector not found: $scriptPath"}
        $data=& $scriptPath
        $data | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $OutputDirectory "$name.json") -Encoding UTF8
        $entry.Succeeded=$true
    }catch{$entry.Error=$_.Exception.GetBaseException().Message}
    $manifest.Collectors+=[pscustomobject]$entry
}
$manifest['CompletedAt']=(Get-Date).ToString('o')
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $OutputDirectory 'manifest.json') -Encoding UTF8
[pscustomobject]@{OutputDirectory=(Resolve-Path $OutputDirectory).Path;Successful=@($manifest.Collectors|Where-Object Succeeded).Count;Failed=@($manifest.Collectors|Where-Object {-not $_.Succeeded}).Count}
