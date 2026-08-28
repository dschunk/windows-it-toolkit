function Get-SchunkServiceFailure {
    <#
    .SYNOPSIS
    Finds stopped automatic services and recent Service Control Manager failures.

    .DESCRIPTION
    Returns a unified, object-first view of automatic services that are not
    running and recent service failure, timeout, crash, and configuration events.

    .PARAMETER EventLookbackHours
    Number of hours of Service Control Manager events to inspect.

    .PARAMETER MaxEvents
    Maximum matching events to retrieve.

    .EXAMPLE
    Get-SchunkServiceFailure -EventLookbackHours 12

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 720)]
        [int]$EventLookbackHours = 24,

        [ValidateRange(1, 5000)]
        [int]$MaxEvents = 500
    )

    Get-CimInstance -ClassName Win32_Service -Filter "StartMode = 'Auto'" -ErrorAction Stop |
        Where-Object State -ne 'Running' |
        ForEach-Object {
            [pscustomobject]@{
                RecordType = 'ServiceState'
                TimeCreated = $null
                ServiceName = $_.Name
                DisplayName = $_.DisplayName
                State = $_.State
                StartMode = $_.StartMode
                StartName = $_.StartName
                ExitCode = $_.ExitCode
                EventId = $null
                Message = $null
            }
        }

    $eventIds = 7000, 7001, 7009, 7011, 7022, 7023, 7024, 7031, 7034, 7040, 7045
    $start = (Get-Date).AddHours(-$EventLookbackHours)

    try {
        Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            ProviderName = 'Service Control Manager'
            Id = $eventIds
            StartTime = $start
        } -MaxEvents $MaxEvents -ErrorAction Stop |
            ForEach-Object {
                [pscustomobject]@{
                    RecordType = 'ServiceEvent'
                    TimeCreated = $_.TimeCreated
                    ServiceName = $null
                    DisplayName = $null
                    State = $null
                    StartMode = $null
                    StartName = $null
                    ExitCode = $null
                    EventId = $_.Id
                    Message = ($_.Message -replace '\s+', ' ').Trim()
                }
            }
    }
    catch {
        Write-Warning "Unable to query Service Control Manager events: $($_.Exception.Message)"
    }
}
