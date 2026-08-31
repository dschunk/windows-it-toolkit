function Get-SchunkADReplicationHealth {
    <#
    .SYNOPSIS
    Summarizes Active Directory replication health for each discoverable domain controller.

    .DESCRIPTION
    Uses the ActiveDirectory module to inspect replication partner metadata and replication
    failures for every discovered domain controller. The output highlights failed links,
    recorded failures, and the largest observed interval since a successful replication.

    The command is read-only and is designed to give an engineer a fast, pipeline-friendly
    replication view before opening repadmin output or Event Viewer.

    .PARAMETER MaxReplicationAgeMinutes
    Replication success older than this threshold is reported as Stale when no harder failure
    is already present.

    .EXAMPLE
    Get-SchunkADReplicationHealth

    .EXAMPLE
    Get-SchunkADReplicationHealth -MaxReplicationAgeMinutes 30 | Format-Table -AutoSize

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Requires the Microsoft ActiveDirectory PowerShell module and sufficient directory read access.
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 10080)]
        [int]$MaxReplicationAgeMinutes = 60
    )

    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw 'The ActiveDirectory PowerShell module is required. Install RSAT: Active Directory Domain Services and Lightweight Directory Services Tools.'
    }

    Import-Module ActiveDirectory -ErrorAction Stop
    $now = Get-Date
    $domainControllers = @(Get-ADDomainController -Filter * -ErrorAction Stop | Sort-Object HostName)

    foreach ($dc in $domainControllers) {
        $metadata = @()
        $failures = @()
        $collectionError = $null

        try {
            $metadata = @(Get-ADReplicationPartnerMetadata -Target $dc.HostName -Scope Server -ErrorAction Stop)
            $failures = @(Get-ADReplicationFailure -Target $dc.HostName -Scope Server -ErrorAction Stop)
        }
        catch {
            $collectionError = $_.Exception.GetBaseException().Message
        }

        $failedPartners = @($metadata | Where-Object { $null -ne $_.LastReplicationResult -and [int]$_.LastReplicationResult -ne 0 })
        $successTimes = @($metadata | Where-Object { $_.LastReplicationSuccess } | ForEach-Object { $_.LastReplicationSuccess })

        $largestAgeMinutes = $null
        $oldestSuccess = $null
        if ($successTimes.Count -gt 0) {
            $oldestSuccess = $successTimes | Sort-Object | Select-Object -First 1
            $largestAgeMinutes = [math]::Round(($now - $oldestSuccess).TotalMinutes, 1)
        }

        $status = if ($collectionError) {
            'CollectionFailed'
        }
        elseif ($failures.Count -gt 0 -or $failedPartners.Count -gt 0) {
            'Unhealthy'
        }
        elseif ($null -ne $largestAgeMinutes -and $largestAgeMinutes -gt $MaxReplicationAgeMinutes) {
            'Stale'
        }
        else {
            'Healthy'
        }

        [pscustomobject]@{
            DomainController = $dc.HostName
            Site = $dc.Site
            IPv4Address = $dc.IPv4Address
            IsGlobalCatalog = [bool]$dc.IsGlobalCatalog
            IsReadOnly = [bool]$dc.IsReadOnly
            Status = $status
            PartnerCount = $metadata.Count
            FailedPartnerCount = $failedPartners.Count
            RecordedFailureCount = $failures.Count
            LargestReplicationAgeMinutes = $largestAgeMinutes
            OldestSuccessfulReplication = $oldestSuccess
            ThresholdMinutes = $MaxReplicationAgeMinutes
            FailedPartners = @($failedPartners | Select-Object Server, Partner, Partition, LastReplicationAttempt, LastReplicationSuccess, LastReplicationResult)
            ReplicationFailures = @($failures | Select-Object Server, Partner, FirstFailureTime, FailureCount, LastError)
            CollectionError = $collectionError
            CollectedAt = $now
        }
    }
}
