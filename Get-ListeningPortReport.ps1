[CmdletBinding()]
param(
    [ValidateSet('TCP','UDP','All')][string]$Protocol = 'All',
    [switch]$IncludeLoopback
)

$connections = @()
if ($Protocol -in @('TCP','All')) {
    $connections += Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Select-Object @{n='Protocol';e={'TCP'}},LocalAddress,LocalPort,OwningProcess
}
if ($Protocol -in @('UDP','All')) {
    $connections += Get-NetUDPEndpoint -ErrorAction SilentlyContinue | Select-Object @{n='Protocol';e={'UDP'}},LocalAddress,LocalPort,OwningProcess
}

$connections | Where-Object {
    $IncludeLoopback -or $_.LocalAddress -notin @('127.0.0.1','::1')
} | ForEach-Object {
    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Protocol = $_.Protocol
        LocalAddress = $_.LocalAddress
        LocalPort = $_.LocalPort
        ProcessId = $_.OwningProcess
        ProcessName = $process.ProcessName
        ExecutablePath = try {$process.Path} catch {$null}
    }
} | Sort-Object Protocol,LocalPort,ProcessName
