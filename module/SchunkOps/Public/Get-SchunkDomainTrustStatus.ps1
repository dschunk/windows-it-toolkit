function Get-SchunkDomainTrustStatus {
    <#
    .SYNOPSIS
    Reports Windows domain membership, secure-channel state, domain controller discovery, and optional AD port checks.

    .DESCRIPTION
    Provides a read-only domain trust diagnostic for workstation and server incidents.
    It identifies whether the computer is domain joined, tests the machine secure channel
    when applicable, discovers a domain controller, reports the current logon server, and
    can optionally test common Active Directory TCP ports against the discovered controller.

    This command does not repair the secure channel, reset the computer account, or change DNS.

    .PARAMETER TestPorts
    Test common Active Directory TCP ports against the selected domain controller.

    .PARAMETER Port
    TCP ports to test when TestPorts is specified.

    .EXAMPLE
    Get-SchunkDomainTrustStatus

    .EXAMPLE
    Get-SchunkDomainTrustStatus -TestPorts

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [switch]$TestPorts,

        [ValidateRange(1, 65535)]
        [int[]]$Port = @(53, 88, 135, 389, 445, 464, 636, 3268, 3269)
    )

    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $domainJoined = [bool]$computerSystem.PartOfDomain
    $domain = if ($domainJoined) { $computerSystem.Domain } else { $null }

    $roleMap = @{
        0 = 'Standalone Workstation'
        1 = 'Member Workstation'
        2 = 'Standalone Server'
        3 = 'Member Server'
        4 = 'Backup Domain Controller'
        5 = 'Primary Domain Controller'
    }
    $domainRole = $roleMap[[int]$computerSystem.DomainRole]
    if (-not $domainRole) { $domainRole = "Unknown ($($computerSystem.DomainRole))" }

    $secureChannel = $null
    $secureChannelError = $null
    if ($domainJoined) {
        if ([int]$computerSystem.DomainRole -ge 4) {
            $secureChannel = $null
            $secureChannelError = 'Test-ComputerSecureChannel is not used for domain controllers.'
        }
        else {
            try {
                $secureChannel = [bool](Test-ComputerSecureChannel -ErrorAction Stop)
            }
            catch {
                $secureChannel = $false
                $secureChannelError = $_.Exception.GetBaseException().Message
            }
        }
    }

    $logonServer = if ($env:LOGONSERVER) { $env:LOGONSERVER.TrimStart('\') } else { $null }
    $discoveredDc = $null
    $discoveryRaw = @()

    if ($domainJoined -and $domain) {
        try {
            $discoveryRaw = @(& nltest.exe "/dsgetdc:$domain" 2>&1)
            foreach ($line in $discoveryRaw) {
                if ($line -match 'DC:\s+\\\\(?<dc>[^\s]+)') {
                    $discoveredDc = $Matches.dc
                    break
                }
            }
        }
        catch {
            Write-Verbose "Domain controller discovery failed: $($_.Exception.Message)"
        }
    }

    if (-not $discoveredDc -and $logonServer) {
        $discoveredDc = $logonServer
    }

    $portChecks = @()
    if ($TestPorts -and $discoveredDc) {
        $portChecks = @($Port | Sort-Object -Unique | ForEach-Object {
            $portNumber = $_
            $reachable = $false
            $errorMessage = $null
            try {
                $reachable = [bool](Test-NetConnection -ComputerName $discoveredDc -Port $portNumber -InformationLevel Quiet -WarningAction SilentlyContinue -ErrorAction Stop)
            }
            catch {
                $errorMessage = $_.Exception.GetBaseException().Message
            }

            [pscustomobject]@{
                DomainController = $discoveredDc
                Port = $portNumber
                Reachable = $reachable
                Error = $errorMessage
            }
        })
    }

    $status = if (-not $domainJoined) {
        'NotDomainJoined'
    }
    elseif ([int]$computerSystem.DomainRole -ge 4) {
        'DomainController'
    }
    elseif ($secureChannel -eq $true) {
        'Healthy'
    }
    else {
        'Attention'
    }

    [pscustomobject]@{
        ComputerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
        CollectedAt = Get-Date
        Status = $status
        DomainJoined = $domainJoined
        Domain = $domain
        DomainRole = $domainRole
        SecureChannelHealthy = $secureChannel
        SecureChannelError = $secureChannelError
        LogonServer = $logonServer
        DiscoveredDomainController = $discoveredDc
        PortChecks = $portChecks
    }
}
