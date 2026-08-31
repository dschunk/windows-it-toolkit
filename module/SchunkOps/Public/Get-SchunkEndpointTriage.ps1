function Get-SchunkEndpointTriage {
    <#
    .SYNOPSIS
    Produces an at-a-glance Windows endpoint triage object for help desk and server support.

    .DESCRIPTION
    Collects the signals that usually matter during first-contact Windows troubleshooting:
    uptime, memory pressure, fixed-disk free space, active IPv4 configuration, DNS servers,
    default gateways, domain membership, secure-channel state, pending reboot state,
    Windows Time source, stopped automatic services, and recent critical/error event counts.

    The command is read-only and returns one structured object that can be attached to a
    ticket, exported to JSON, or used as the first step before escalation.

    .PARAMETER EventLookbackHours
    Number of hours of System and Application events to inspect.

    .PARAMETER LowDiskThresholdPercent
    Fixed disks below this free-space percentage are surfaced as an attention signal.

    .EXAMPLE
    Get-SchunkEndpointTriage

    .EXAMPLE
    Get-SchunkEndpointTriage -EventLookbackHours 8 | ConvertTo-Json -Depth 6

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 168)]
        [int]$EventLookbackHours = 4,

        [ValidateRange(1, 99)]
        [int]$LowDiskThresholdPercent = 15
    )

    $collectedAt = Get-Date
    $since = $collectedAt.AddHours(-1 * $EventLookbackHours)
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop

    $memoryTotalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $memoryFreeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $memoryUsedPercent = if ($memoryTotalGB -gt 0) {
        [math]::Round((($memoryTotalGB - $memoryFreeGB) / $memoryTotalGB) * 100, 1)
    }
    else {
        $null
    }

    $disks = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop | ForEach-Object {
        $freePercent = if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { $null }
        [pscustomobject]@{
            Drive = $_.DeviceID
            Label = $_.VolumeName
            SizeGB = [math]::Round($_.Size / 1GB, 1)
            FreeGB = [math]::Round($_.FreeSpace / 1GB, 1)
            FreePercent = $freePercent
            Status = if ($null -ne $freePercent -and $freePercent -lt $LowDiskThresholdPercent) { 'Attention' } else { 'OK' }
        }
    })

    $network = @(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE' -ErrorAction SilentlyContinue | ForEach-Object {
        $ipv4 = @($_.IPAddress | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' })
        [pscustomobject]@{
            Description = $_.Description
            IPv4Address = $ipv4
            DefaultGateway = @($_.DefaultIPGateway)
            DnsServers = @($_.DNSServerSearchOrder)
            DhcpEnabled = [bool]$_.DHCPEnabled
            DhcpServer = $_.DHCPServer
        }
    })

    $stoppedAutomaticServices = @(Get-CimInstance -ClassName Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } |
        Select-Object Name, DisplayName, State, StartMode, StartName, ExitCode)

    $pendingReboot = $null
    try {
        $pendingReboot = Get-SchunkPendingReboot -ErrorAction Stop
    }
    catch {
        Write-Verbose "Unable to collect pending reboot state: $($_.Exception.Message)"
    }

    $secureChannel = $null
    if ($computerSystem.PartOfDomain) {
        if ([int]$computerSystem.DomainRole -ge 4) {
            $secureChannel = 'DomainController'
        }
        else {
            try {
                $secureChannel = [bool](Test-ComputerSecureChannel -ErrorAction Stop)
            }
            catch {
                $secureChannel = $false
            }
        }
    }

    $timeSource = $null
    try {
        $timeSource = (& w32tm.exe /query /source 2>$null | Select-Object -First 1)
        if ($timeSource) { $timeSource = $timeSource.ToString().Trim() }
    }
    catch {
        Write-Verbose "Unable to query Windows Time source: $($_.Exception.Message)"
    }

    $systemErrorCount = try {
        @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = $since } -ErrorAction Stop).Count
    }
    catch {
        0
    }

    $applicationErrorCount = try {
        @(Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Level = 1, 2; StartTime = $since } -ErrorAction Stop).Count
    }
    catch {
        0
    }

    $signals = New-Object System.Collections.Generic.List[string]
    foreach ($disk in $disks) {
        if ($disk.Status -eq 'Attention') {
            $signals.Add("Low disk space on $($disk.Drive): $($disk.FreePercent)% free")
        }
    }
    if ($memoryUsedPercent -ge 90) { $signals.Add("Memory use is $memoryUsedPercent%") }
    if ($pendingReboot -and $pendingReboot.PendingReboot) { $signals.Add('A Windows reboot is pending') }
    if ($secureChannel -eq $false) { $signals.Add('Domain secure channel test failed') }
    if ($stoppedAutomaticServices.Count -gt 0) { $signals.Add("$($stoppedAutomaticServices.Count) automatic service(s) are not running") }
    if (($systemErrorCount + $applicationErrorCount) -gt 0) { $signals.Add("$($systemErrorCount + $applicationErrorCount) recent critical/error event(s)") }

    [pscustomobject]@{
        ComputerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
        CollectedAt = $collectedAt
        OverallStatus = if ($signals.Count -gt 0) { 'Attention' } else { 'OK' }
        Signals = @($signals)
        CurrentUser = [Environment]::UserName
        OperatingSystem = $os.Caption
        OsVersion = $os.Version
        LastBoot = $os.LastBootUpTime
        UptimeHours = [math]::Round(($collectedAt - $os.LastBootUpTime).TotalHours, 1)
        MemoryTotalGB = $memoryTotalGB
        MemoryFreeGB = $memoryFreeGB
        MemoryUsedPercent = $memoryUsedPercent
        Disks = $disks
        Network = $network
        DomainJoined = [bool]$computerSystem.PartOfDomain
        Domain = $computerSystem.Domain
        DomainRole = [int]$computerSystem.DomainRole
        SecureChannel = $secureChannel
        LogonServer = $env:LOGONSERVER
        PendingReboot = if ($pendingReboot) { [bool]$pendingReboot.PendingReboot } else { $null }
        TimeSource = $timeSource
        StoppedAutomaticServices = $stoppedAutomaticServices
        RecentSystemCriticalOrErrors = $systemErrorCount
        RecentApplicationCriticalOrErrors = $applicationErrorCount
        EventLookbackHours = $EventLookbackHours
    }
}
