function Get-SchunkLogonFailure {
    <#
    .SYNOPSIS
    Summarizes recent Windows authentication failures.

    .DESCRIPTION
    Reads Security events 4625, 4771, and 4776, extracts normalized identity and
    source fields from event XML, and groups repeated failures for rapid triage.
    Reading the Security log commonly requires elevation.

    .PARAMETER Hours
    Number of hours to look back.

    .PARAMETER MaxEvents
    Maximum failed authentication events to retrieve.

    .EXAMPLE
    Get-SchunkLogonFailure -Hours 8

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 720)]
        [int]$Hours = 24,

        [ValidateRange(1, 10000)]
        [int]$MaxEvents = 2000
    )

    $start = (Get-Date).AddHours(-$Hours)
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        Id = 4625, 4771, 4776
        StartTime = $start
    } -MaxEvents $MaxEvents -ErrorAction Stop

    $normalized = foreach ($event in $events) {
        $xml = [xml]$event.ToXml()
        $fields = @{}
        foreach ($item in $xml.Event.EventData.Data) {
            $fields[[string]$item.Name] = [string]$item.'#text'
        }

        $userName = if ($fields.TargetUserName) {
            $fields.TargetUserName
        }
        elseif ($fields.TargetUser) {
            $fields.TargetUser
        }
        else {
            '(unknown)'
        }

        $sourceAddress = if ($fields.IpAddress -and $fields.IpAddress -ne '-') {
            $fields.IpAddress
        }
        elseif ($fields.Workstation -and $fields.Workstation -ne '-') {
            $fields.Workstation
        }
        elseif ($fields.WorkstationName -and $fields.WorkstationName -ne '-') {
            $fields.WorkstationName
        }
        else {
            '(local or unavailable)'
        }

        [pscustomobject]@{
            EventId = $event.Id
            TimeCreated = $event.TimeCreated
            UserName = $userName
            Domain = $fields.TargetDomainName
            SourceAddress = $sourceAddress
            LogonType = $fields.LogonType
            AuthenticationPackage = $fields.AuthenticationPackageName
            Status = $fields.Status
            SubStatus = $fields.SubStatus
            FailureReason = $fields.FailureReason
        }
    }

    $normalized |
        Group-Object UserName, Domain, SourceAddress, EventId, FailureReason |
        ForEach-Object {
            $latest = $_.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1
            [pscustomobject]@{
                Count = $_.Count
                UserName = $latest.UserName
                Domain = $latest.Domain
                SourceAddress = $latest.SourceAddress
                EventId = $latest.EventId
                FailureReason = $latest.FailureReason
                Status = $latest.Status
                SubStatus = $latest.SubStatus
                LogonType = $latest.LogonType
                AuthenticationPackage = $latest.AuthenticationPackage
                FirstSeen = ($_.Group | Measure-Object TimeCreated -Minimum).Minimum
                LastSeen = ($_.Group | Measure-Object TimeCreated -Maximum).Maximum
            }
        } |
        Sort-Object Count -Descending
}
