function New-SchunkIncidentBundle {
    <#
    .SYNOPSIS
    Creates a structured Windows incident evidence bundle with integrity hashes.

    .DESCRIPTION
    Runs a coordinated set of SchunkOps collectors, writes each result to its
    own JSON file, and creates a manifest containing collection status and
    SHA-256 hashes. Standard mode collects health, reboot, ports, events, and
    service failures. Full mode also includes software, updates, scheduled
    tasks, failed logons, and BitLocker state.

    The command does not upload data or contact an external service.

    .PARAMETER OutputPath
    Directory in which the evidence bundle will be created.

    .PARAMETER Profile
    Standard or Full. Full can require elevation for Security and BitLocker data.

    .PARAMETER EventLookbackHours
    Number of hours of event and service history to collect.

    .EXAMPLE
    New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042

    .EXAMPLE
    New-SchunkIncidentBundle -Profile Full -EventLookbackHours 72

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Review the bundle for sensitive hostnames, usernames, addresses, paths, and
    software details before sharing it outside your organization.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$OutputPath = (Join-Path (Get-Location) ('SchunkOps-Incident-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))),

        [ValidateSet('Standard', 'Full')]
        [string]$Profile = 'Standard',

        [ValidateRange(1, 720)]
        [int]$EventLookbackHours = 24
    )

    if (-not $PSCmdlet.ShouldProcess($OutputPath, 'Create SchunkOps incident evidence bundle')) {
        return
    }

    $bundleId = [guid]::NewGuid().Guid
    $collectedAtUtc = (Get-Date).ToUniversalTime()
    $computerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }

    $collectors = @(
        @{
            Name = 'server-health'
            Action = { Get-SchunkServerHealth -EventLookbackHours $EventLookbackHours }
        }
        @{
            Name = 'pending-reboot'
            Action = { Get-SchunkPendingReboot }
        }
        @{
            Name = 'listening-ports'
            Action = { Get-SchunkListeningPort }
        }
        @{
            Name = 'event-triage'
            Action = { Get-SchunkEventTriage -Hours $EventLookbackHours }
        }
        @{
            Name = 'service-failures'
            Action = { Get-SchunkServiceFailure -EventLookbackHours $EventLookbackHours }
        }
    )

    if ($Profile -eq 'Full') {
        $collectors += @(
            @{
                Name = 'installed-software'
                Action = { Get-SchunkInstalledSoftware }
            }
            @{
                Name = 'windows-update-history'
                Action = { Get-SchunkWindowsUpdateHistory -Newest 250 }
            }
            @{
                Name = 'scheduled-tasks'
                Action = { Get-SchunkScheduledTaskAudit }
            }
            @{
                Name = 'logon-failures'
                Action = { Get-SchunkLogonFailure -Hours $EventLookbackHours }
            }
            @{
                Name = 'bitlocker-inventory'
                Action = { Get-SchunkBitLockerInventory }
            }
        )
    }

    $null = New-Item -ItemType Directory -Path $OutputPath -Force -ErrorAction Stop
    $results = foreach ($collector in $collectors) {
        $startedAtUtc = (Get-Date).ToUniversalTime()
        $status = 'Success'
        $errorMessage = $null

        try {
            $data = @(& $collector.Action)
        }
        catch {
            $status = 'Failed'
            $errorMessage = $_.Exception.GetBaseException().Message
            $data = @()
        }

        $fileName = '{0}.json' -f $collector.Name
        $filePath = Join-Path $OutputPath $fileName
        $json = ConvertTo-Json -InputObject @($data) -Depth 10
        Set-Content -LiteralPath $filePath -Value $json -Encoding UTF8
        $hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash

        [pscustomobject]@{
            Name = $collector.Name
            Status = $status
            File = $fileName
            Sha256 = $hash
            RecordCount = $data.Count
            StartedAtUtc = $startedAtUtc
            CompletedAtUtc = (Get-Date).ToUniversalTime()
            Error = $errorMessage
        }
    }

    $manifest = [pscustomobject]@{
        SchemaVersion = '1.0'
        BundleId = $bundleId
        ComputerName = $computerName
        CollectedAtUtc = $collectedAtUtc
        CollectedBy = [Environment]::UserName
        Profile = $Profile
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        EventLookbackHours = $EventLookbackHours
        CollectorCount = $results.Count
        SuccessfulCollectors = @($results | Where-Object Status -eq 'Success').Count
        FailedCollectors = @($results | Where-Object Status -eq 'Failed').Count
        Collectors = @($results)
        HandlingNotice = 'Review for sensitive operational data before sharing.'
    }

    $manifestPath = Join-Path $OutputPath 'manifest.json'
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    [pscustomobject]@{
        BundleId = $bundleId
        Path = (Resolve-Path -LiteralPath $OutputPath).Path
        ManifestPath = (Resolve-Path -LiteralPath $manifestPath).Path
        Profile = $Profile
        SuccessfulCollectors = $manifest.SuccessfulCollectors
        FailedCollectors = $manifest.FailedCollectors
        CollectedAtUtc = $collectedAtUtc
    }
}
