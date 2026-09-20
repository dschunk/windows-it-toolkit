function Get-SchunkRdpHealth {
    <#
    .SYNOPSIS
    Audits Remote Desktop Services configuration and listener health.

    .DESCRIPTION
    Collects the local RDP enablement state, configured listener port, Network
    Level Authentication setting, security layer, Terminal Services service state,
    listener state, and matching Windows Firewall rules. No configuration changes
    are made.

    .EXAMPLE
    Get-SchunkRdpHealth

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param()

    $terminalServerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
    $rdpTcpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

    $terminalServer = Get-ItemProperty -LiteralPath $terminalServerPath -ErrorAction Stop
    $rdpTcp = Get-ItemProperty -LiteralPath $rdpTcpPath -ErrorAction Stop
    $port = [int]$rdpTcp.PortNumber
    $service = Get-Service -Name TermService -ErrorAction SilentlyContinue

    $listeners = @(Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess)
    $firewallRules = @(Get-NetFirewallRule -Enabled True -ErrorAction SilentlyContinue | Where-Object { $_.DisplayGroup -eq 'Remote Desktop' -or $_.Service -eq 'TermService' } | Select-Object DisplayName, Direction, Action, Profile, Enabled, PrimaryStatus)

    [pscustomobject]@{
        ComputerName               = $env:COMPUTERNAME
        CollectedAt                = Get-Date
        RdpEnabled                 = ([int]$terminalServer.fDenyTSConnections -eq 0)
        Port                       = $port
        NetworkLevelAuthentication = ([int]$rdpTcp.UserAuthentication -eq 1)
        SecurityLayer              = $rdpTcp.SecurityLayer
        MinEncryptionLevel         = $rdpTcp.MinEncryptionLevel
        ServiceStatus              = if ($service) { $service.Status } else { 'NotFound' }
        ServiceStartType           = if ($service) { $service.StartType } else { $null }
        ListenerPresent            = ($listeners.Count -gt 0)
        Listeners                  = $listeners
        FirewallRules              = $firewallRules
    }
}
