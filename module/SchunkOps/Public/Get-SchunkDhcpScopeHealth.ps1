function Get-SchunkDhcpScopeHealth {
    <#
    .SYNOPSIS
    Reports Windows DHCP IPv4 scope state and utilization.

    .DESCRIPTION
    Uses the DhcpServer module to combine scope configuration with scope statistics.
    High-utilization scopes are flagged without modifying DHCP configuration.

    .PARAMETER ComputerName
    DHCP server to query. Defaults to the local computer.

    .PARAMETER WarningPercent
    Utilization percentage at which a scope is flagged.

    .EXAMPLE
    Get-SchunkDhcpScopeHealth -ComputerName DHCP01 -WarningPercent 80

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,

        [ValidateRange(1, 100)]
        [int]$WarningPercent = 85
    )

    if (-not (Get-Module -ListAvailable -Name DhcpServer)) {
        throw 'The DhcpServer PowerShell module is not available. Install the DHCP Server tools or RSAT DHCP tools.'
    }

    Import-Module DhcpServer -ErrorAction Stop
    $scopes = @(Get-DhcpServerv4Scope -ComputerName $ComputerName -ErrorAction Stop)

    $results = foreach ($scope in $scopes) {
        $stats = Get-DhcpServerv4ScopeStatistics -ComputerName $ComputerName -ScopeId $scope.ScopeId -ErrorAction SilentlyContinue

        [pscustomobject]@{
            ScopeId          = $scope.ScopeId.IPAddressToString
            Name             = $scope.Name
            State            = $scope.State
            StartRange       = $scope.StartRange.IPAddressToString
            EndRange         = $scope.EndRange.IPAddressToString
            SubnetMask       = $scope.SubnetMask.IPAddressToString
            LeaseDuration    = $scope.LeaseDuration
            AddressesInUse   = if ($stats) { $stats.AddressesInUse } else { $null }
            AddressesFree    = if ($stats) { $stats.AddressesFree } else { $null }
            PercentageInUse  = if ($stats) { [math]::Round($stats.PercentageInUse, 1) } else { $null }
            HighUtilization  = if ($stats) { $stats.PercentageInUse -ge $WarningPercent } else { $false }
        }
    }

    $failover = @(Get-DhcpServerv4Failover -ComputerName $ComputerName -ErrorAction SilentlyContinue | Select-Object Name, PartnerServer, Mode, State, ScopeId)

    [pscustomobject]@{
        ComputerName          = $ComputerName
        CollectedAt           = Get-Date
        ScopeCount            = $results.Count
        InactiveScopeCount    = @($results | Where-Object State -ne 'Active').Count
        HighUtilizationCount  = @($results | Where-Object HighUtilization).Count
        WarningPercent        = $WarningPercent
        Scopes                = @($results)
        FailoverRelationships = $failover
    }
}
