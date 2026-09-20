function Get-SchunkDnsServerHealth {
    <#
    .SYNOPSIS
    Collects Windows DNS Server configuration and zone health.

    .DESCRIPTION
    Uses the DnsServer module to inventory zones and forwarders from a Windows
    DNS server. The command is read-only and can target a remote DNS server.

    .PARAMETER ComputerName
    DNS server to query. Defaults to the local computer.

    .EXAMPLE
    Get-SchunkDnsServerHealth

    .EXAMPLE
    Get-SchunkDnsServerHealth -ComputerName DC01

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if (-not (Get-Module -ListAvailable -Name DnsServer)) {
        throw 'The DnsServer PowerShell module is not available. Install the DNS Server tools or RSAT DNS tools.'
    }

    Import-Module DnsServer -ErrorAction Stop
    $zones = @(Get-DnsServerZone -ComputerName $ComputerName -ErrorAction Stop | ForEach-Object {
        [pscustomobject]@{
            ZoneName          = $_.ZoneName
            ZoneType          = $_.ZoneType
            IsDsIntegrated    = $_.IsDsIntegrated
            IsReverseLookupZone = $_.IsReverseLookupZone
            DynamicUpdate     = $_.DynamicUpdate
            ReplicationScope  = $_.ReplicationScope
            IsPaused          = $_.IsPaused
            IsShutdown        = $_.IsShutdown
        }
    })

    $forwarders = @(Get-DnsServerForwarder -ComputerName $ComputerName -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{
            IPAddress = @($_.IPAddress | ForEach-Object IPAddressToString)
            UseRootHint = $_.UseRootHint
            Timeout = $_.Timeout
        }
    })

    [pscustomobject]@{
        ComputerName       = $ComputerName
        CollectedAt        = Get-Date
        ZoneCount          = $zones.Count
        PrimaryZoneCount   = @($zones | Where-Object ZoneType -eq 'Primary').Count
        ReverseZoneCount   = @($zones | Where-Object IsReverseLookupZone).Count
        PausedZoneCount    = @($zones | Where-Object IsPaused).Count
        ShutdownZoneCount  = @($zones | Where-Object IsShutdown).Count
        Zones              = $zones
        Forwarders         = $forwarders
    }
}
