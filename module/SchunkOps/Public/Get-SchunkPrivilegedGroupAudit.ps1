function Get-SchunkPrivilegedGroupAudit {
    <#
    .SYNOPSIS
    Audits membership of well-known privileged Active Directory groups.

    .DESCRIPTION
    Resolves privileged groups by well-known SID where possible and returns their
    recursive membership. DNSAdmins is included by name when present.

    .PARAMETER IncludeDnsAdmins
    Include the DNSAdmins group when it exists.

    .EXAMPLE
    Get-SchunkPrivilegedGroupAudit

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeDnsAdmins = $true
    )

    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        throw 'The ActiveDirectory PowerShell module is not available. Install RSAT Active Directory tools.'
    }

    Import-Module ActiveDirectory -ErrorAction Stop

    $domain = Get-ADDomain -ErrorAction Stop
    $forest = Get-ADForest -ErrorAction Stop
    $forestRoot = Get-ADDomain -Identity $forest.RootDomain -ErrorAction Stop

    $groupSids = @(
        "$($domain.DomainSID.Value)-512",
        "$($domain.DomainSID.Value)-520",
        "$($forestRoot.DomainSID.Value)-518",
        "$($forestRoot.DomainSID.Value)-519",
        'S-1-5-32-544',
        'S-1-5-32-548',
        'S-1-5-32-549',
        'S-1-5-32-550',
        'S-1-5-32-551'
    ) | Select-Object -Unique

    $groups = @()
    foreach ($sid in $groupSids) {
        try {
            $group = Get-ADGroup -Identity $sid -Properties Description -ErrorAction Stop
            $groups += $group
        }
        catch {
            continue
        }
    }

    if ($IncludeDnsAdmins) {
        try {
            $dnsAdmins = Get-ADGroup -Identity 'DNSAdmins' -Properties Description -ErrorAction Stop
            if ($groups.DistinguishedName -notcontains $dnsAdmins.DistinguishedName) {
                $groups += $dnsAdmins
            }
        }
        catch {
        }
    }

    $results = foreach ($group in ($groups | Sort-Object Name -Unique)) {
        $members = @()
        $memberError = $null
        try {
            $members = @(Get-ADGroupMember -Identity $group.DistinguishedName -Recursive -ErrorAction Stop | Select-Object Name, SamAccountName, ObjectClass, DistinguishedName, SID)
        }
        catch {
            $memberError = $_.Exception.Message
        }

        [pscustomobject]@{
            GroupName         = $group.Name
            GroupSid          = $group.SID.Value
            DistinguishedName = $group.DistinguishedName
            Description       = $group.Description
            MemberCount       = $members.Count
            Members           = $members
            Error             = $memberError
        }
    }

    [pscustomobject]@{
        DomainName  = $domain.DNSRoot
        ForestName  = $forest.Name
        CollectedAt = Get-Date
        GroupCount  = $results.Count
        Groups      = @($results)
    }
}
