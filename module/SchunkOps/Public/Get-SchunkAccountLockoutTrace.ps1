function Get-SchunkAccountLockoutTrace {
    <#
    .SYNOPSIS
    Traces Active Directory account lockout events across domain controllers.

    .DESCRIPTION
    Queries Security event 4740 on one or more domain controllers and returns
    the domain controller that recorded the lockout, the caller computer, the
    target account, and event timestamps. The command is read-only and is
    intended to replace manual Event Viewer searches during account-lockout
    investigations.

    .PARAMETER Identity
    User name to trace. DOMAIN\user, user@domain, and sAMAccountName formats are accepted.

    .PARAMETER LookbackHours
    Number of hours of Security log history to query. Defaults to 24.

    .PARAMETER DomainController
    Optional domain controllers to query. When omitted, all discoverable DCs are used.

    .EXAMPLE
    Get-SchunkAccountLockoutTrace -Identity jsmith

    .EXAMPLE
    Get-SchunkAccountLockoutTrace -Identity CONTOSO\jsmith -LookbackHours 72 |
        Sort-Object TimeCreatedUtc -Descending

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Reading remote Security logs requires appropriate Event Log Reader or administrative rights.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,

        [ValidateRange(1, 720)]
        [int]$LookbackHours = 24,

        [string[]]$DomainController
    )

    if (-not (Get-Command Get-ADDomainController -ErrorAction SilentlyContinue)) {
        throw 'The ActiveDirectory module is required. Install the AD DS RSAT tools first.'
    }

    $targetUser = $Identity
    if ($targetUser -match '\\') { $targetUser = ($targetUser -split '\\')[-1] }
    if ($targetUser -match '@') { $targetUser = ($targetUser -split '@')[0] }
    $since = (Get-Date).AddHours(-1 * $LookbackHours)

    if (-not $DomainController) {
        $DomainController = @(Get-ADDomainController -Filter * -ErrorAction Stop | Select-Object -ExpandProperty HostName)
    }

    foreach ($dc in $DomainController) {
        if ([string]::IsNullOrWhiteSpace($dc)) { continue }

        try {
            $events = Get-WinEvent -ComputerName $dc -FilterHashtable @{
                LogName = 'Security'
                Id = 4740
                StartTime = $since
            } -ErrorAction Stop

            foreach ($event in $events) {
                $xml = [xml]$event.ToXml()
                $data = @{}
                foreach ($item in $xml.Event.EventData.Data) {
                    if ($item.Name) { $data[[string]$item.Name] = [string]$item.'#text' }
                }

                if ($data.TargetUserName -and $data.TargetUserName -ine $targetUser) { continue }

                [pscustomobject]@{
                    QueryStatus = 'Success'
                    TargetUserName = $data.TargetUserName
                    TargetDomainName = $data.TargetDomainName
                    CallerComputerName = $data.CallerComputerName
                    DomainController = $dc
                    TimeCreatedUtc = $event.TimeCreated.ToUniversalTime()
                    SubjectUserName = $data.SubjectUserName
                    SubjectDomainName = $data.SubjectDomainName
                    EventId = $event.Id
                    RecordId = $event.RecordId
                    Error = $null
                }
            }
        }
        catch {
            [pscustomobject]@{
                QueryStatus = 'Failed'
                TargetUserName = $targetUser
                TargetDomainName = $null
                CallerComputerName = $null
                DomainController = $dc
                TimeCreatedUtc = $null
                SubjectUserName = $null
                SubjectDomainName = $null
                EventId = 4740
                RecordId = $null
                Error = $_.Exception.GetBaseException().Message
            }
        }
    }
}
