function Get-SchunkFirewallAudit {
    <#
    .SYNOPSIS
    Audits Windows Defender Firewall profiles and enabled rules.

    .DESCRIPTION
    Returns a read-only summary of local firewall profile state and enabled
    inbound/outbound rule counts. Use IncludeRules to include a bounded list of
    enabled rules for review.

    .PARAMETER IncludeRules
    Include enabled firewall rules in the returned object.

    .PARAMETER MaxRules
    Maximum number of enabled rules to include when IncludeRules is used.

    .EXAMPLE
    Get-SchunkFirewallAudit

    .EXAMPLE
    Get-SchunkFirewallAudit -IncludeRules -MaxRules 100

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeRules,

        [ValidateRange(1, 5000)]
        [int]$MaxRules = 200
    )

    $profiles = @(Get-NetFirewallProfile -ErrorAction Stop | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction, AllowInboundRules, AllowLocalFirewallRules, AllowLocalIPsecRules, LogAllowed, LogBlocked, LogFileName, LogMaxSizeKilobytes)
    $enabledRules = @(Get-NetFirewallRule -Enabled True -ErrorAction Stop)

    $summary = [pscustomobject]@{
        TotalEnabledRules      = $enabledRules.Count
        EnabledInboundAllow    = @($enabledRules | Where-Object { $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow' }).Count
        EnabledInboundBlock    = @($enabledRules | Where-Object { $_.Direction -eq 'Inbound' -and $_.Action -eq 'Block' }).Count
        EnabledOutboundAllow   = @($enabledRules | Where-Object { $_.Direction -eq 'Outbound' -and $_.Action -eq 'Allow' }).Count
        EnabledOutboundBlock   = @($enabledRules | Where-Object { $_.Direction -eq 'Outbound' -and $_.Action -eq 'Block' }).Count
        EnabledAnyProfileRules = @($enabledRules | Where-Object { $_.Profile -match 'Any' }).Count
    }

    $rules = @()
    if ($IncludeRules) {
        $rules = @($enabledRules | Sort-Object Direction, Action, DisplayName | Select-Object -First $MaxRules DisplayName, DisplayGroup, Direction, Action, Profile, EdgeTraversalPolicy, PolicyStoreSourceType, PrimaryStatus, Status)
    }

    [pscustomobject]@{
        ComputerName   = $env:COMPUTERNAME
        CollectedAt    = Get-Date
        Profiles       = $profiles
        Summary        = $summary
        Rules          = $rules
        RulesTruncated = ($IncludeRules -and $enabledRules.Count -gt $MaxRules)
    }
}
