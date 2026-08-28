function Get-SchunkListeningPort {
    <#
    .SYNOPSIS
    Maps local listening ports to their owning processes.

    .PARAMETER Protocol
    TCP, UDP, or All.

    .PARAMETER IncludeLoopback
    Includes listeners bound only to IPv4 or IPv6 loopback.

    .EXAMPLE
    Get-SchunkListeningPort -Protocol TCP

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('TCP', 'UDP', 'All')]
        [string]$Protocol = 'All',

        [switch]$IncludeLoopback
    )

    $connections = @()
    if ($Protocol -in @('TCP', 'All')) {
        $connections += Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
            Select-Object @{ Name = 'Protocol'; Expression = { 'TCP' } }, LocalAddress, LocalPort, OwningProcess
    }
    if ($Protocol -in @('UDP', 'All')) {
        $connections += Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
            Select-Object @{ Name = 'Protocol'; Expression = { 'UDP' } }, LocalAddress, LocalPort, OwningProcess
    }

    $connections |
        Where-Object {
            $IncludeLoopback -or $_.LocalAddress -notin @('127.0.0.1', '::1')
        } |
        ForEach-Object {
            $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            [pscustomobject]@{
                Protocol = $_.Protocol
                LocalAddress = $_.LocalAddress
                LocalPort = $_.LocalPort
                ProcessId = $_.OwningProcess
                ProcessName = $process.ProcessName
                ExecutablePath = try { $process.Path } catch { $null }
            }
        } |
        Sort-Object Protocol, LocalPort, ProcessName
}
