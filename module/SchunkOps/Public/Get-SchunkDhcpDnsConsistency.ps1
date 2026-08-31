function Get-SchunkDhcpDnsConsistency {
    <#
    .SYNOPSIS
    Compares DHCP leases with forward and reverse DNS answers.

    .DESCRIPTION
    Reads IPv4 leases from a DHCP server and checks whether each lease hostname
    resolves back to the leased address and whether the leased address has a PTR
    record matching the lease hostname. Mismatches are surfaced as structured
    output for DHCP/DNS scavenging, stale-record, and name-resolution investigations.

    The command does not modify DHCP leases or DNS records.

    .PARAMETER DhcpServer
    DHCP server to query.

    .PARAMETER ScopeId
    Optional IPv4 scope to query. When omitted, all IPv4 leases are queried.

    .PARAMETER DnsServer
    Optional DNS server to use for forward and reverse lookups.

    .PARAMETER IncludeInactive
    Includes non-active leases.

    .PARAMETER MaxLeases
    Maximum number of leases to evaluate. Defaults to 500.

    .EXAMPLE
    Get-SchunkDhcpDnsConsistency -DhcpServer dhcp01

    .EXAMPLE
    Get-SchunkDhcpDnsConsistency -DhcpServer dhcp01 -ScopeId 10.20.30.0 -DnsServer dns01 |
        Where-Object Status -ne 'Consistent'

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Requires the DhcpServer module and permission to read the target DHCP server.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DhcpServer,

        [System.Net.IPAddress]$ScopeId,

        [string]$DnsServer,

        [switch]$IncludeInactive,

        [ValidateRange(1, 100000)]
        [int]$MaxLeases = 500
    )

    if (-not (Get-Command Get-DhcpServerv4Lease -ErrorAction SilentlyContinue)) {
        throw 'The DhcpServer module is required. Install the DHCP Server RSAT tools first.'
    }
    if (-not (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue)) {
        throw 'Resolve-DnsName is required for DNS consistency checks.'
    }

    $leaseParams = @{ ComputerName = $DhcpServer; ErrorAction = 'Stop' }
    if ($ScopeId) { $leaseParams.ScopeId = $ScopeId }
    else { $leaseParams.AllLeases = $true }

    $leases = @(Get-DhcpServerv4Lease @leaseParams)
    if (-not $IncludeInactive) {
        $leases = @($leases | Where-Object { [string]$_.AddressState -match '^Active' })
    }
    $leases = @($leases | Select-Object -First $MaxLeases)

    foreach ($lease in $leases) {
        $ip = [string]$lease.IPAddress
        $hostName = [string]$lease.HostName
        $aRecords = @()
        $ptrRecords = @()
        $forwardError = $null
        $reverseError = $null

        if ($hostName) {
            try {
                $forwardParams = @{ Name = $hostName; Type = 'A'; ErrorAction = 'Stop' }
                if ($DnsServer) { $forwardParams.Server = $DnsServer }
                $aRecords = @(Resolve-DnsName @forwardParams | Where-Object IPAddress | Select-Object -ExpandProperty IPAddress -Unique)
            }
            catch { $forwardError = $_.Exception.GetBaseException().Message }
        }

        try {
            $reverseParams = @{ Name = $ip; Type = 'PTR'; ErrorAction = 'Stop' }
            if ($DnsServer) { $reverseParams.Server = $DnsServer }
            $ptrRecords = @(Resolve-DnsName @reverseParams | Where-Object NameHost | Select-Object -ExpandProperty NameHost -Unique)
        }
        catch { $reverseError = $_.Exception.GetBaseException().Message }

        $normalizedHost = if ($hostName) { $hostName.TrimEnd('.').ToLowerInvariant() } else { $null }
        $normalizedPtrs = @($ptrRecords | ForEach-Object { ([string]$_).TrimEnd('.').ToLowerInvariant() })
        $forwardMatches = [bool]($ip -in $aRecords)
        $reverseMatches = [bool]($normalizedHost -and $normalizedHost -in $normalizedPtrs)

        $status = if (-not $hostName) {
            'NoLeaseHostname'
        }
        elseif ($forwardMatches -and $reverseMatches) {
            'Consistent'
        }
        elseif (-not $forwardMatches -and -not $reverseMatches) {
            'ForwardAndReverseMismatch'
        }
        elseif (-not $forwardMatches) {
            'ForwardMismatch'
        }
        else {
            'ReverseMismatch'
        }

        [pscustomobject]@{
            DhcpServer = $DhcpServer
            ScopeId = [string]$lease.ScopeId
            IPAddress = $ip
            HostName = $hostName
            ClientId = [string]$lease.ClientId
            AddressState = [string]$lease.AddressState
            LeaseExpiryTime = $lease.LeaseExpiryTime
            DnsServer = $DnsServer
            ARecords = $aRecords
            PtrRecords = $ptrRecords
            ForwardMatchesLease = $forwardMatches
            ReverseMatchesHostname = $reverseMatches
            Status = $status
            ForwardError = $forwardError
            ReverseError = $reverseError
        }
    }
}
