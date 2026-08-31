function Get-SchunkKerberosSpnAudit {
    <#
    .SYNOPSIS
    Audits Kerberos service principal names and detects duplicate ownership.

    .DESCRIPTION
    Resolves the SPNs assigned to an Active Directory object, or audits one
    explicitly supplied SPN, then searches the directory for every object that
    owns each SPN. Duplicate ownership is surfaced directly because duplicate
    SPNs are a common cause of Kerberos authentication failures and NTLM fallback.

    The command does not create, delete, or modify SPNs.

    .PARAMETER Identity
    sAMAccountName of the user, computer, or service account whose SPNs should be audited.

    .PARAMETER ServicePrincipalName
    An explicit SPN to audit, such as HTTP/app01.contoso.com.

    .EXAMPLE
    Get-SchunkKerberosSpnAudit -Identity svc_web

    .EXAMPLE
    Get-SchunkKerberosSpnAudit -ServicePrincipalName 'HTTP/app01.contoso.com'

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Requires the ActiveDirectory module and directory read permissions.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Identity')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Identity')]
        [ValidateNotNullOrEmpty()]
        [string]$Identity,

        [Parameter(Mandatory, ParameterSetName = 'Spn')]
        [ValidateNotNullOrEmpty()]
        [string]$ServicePrincipalName
    )

    if (-not (Get-Command Get-ADObject -ErrorAction SilentlyContinue)) {
        throw 'The ActiveDirectory module is required. Install the AD DS RSAT tools first.'
    }

    function ConvertTo-SchunkLdapValue {
        param([Parameter(Mandatory)][string]$Value)
        $Value.Replace('\', '\5c').Replace('*', '\2a').Replace('(', '\28').Replace(')', '\29').Replace([char]0, '\00')
    }

    $spns = @()
    $source = $null

    if ($PSCmdlet.ParameterSetName -eq 'Identity') {
        $safeIdentity = ConvertTo-SchunkLdapValue -Value $Identity
        $objects = @(Get-ADObject -LDAPFilter "(sAMAccountName=$safeIdentity)" -Properties servicePrincipalName,sAMAccountName,objectClass -ErrorAction Stop)
        if ($objects.Count -eq 0) {
            throw "No Active Directory object was found with sAMAccountName '$Identity'."
        }
        if ($objects.Count -gt 1) {
            throw "More than one Active Directory object matched sAMAccountName '$Identity'."
        }

        $source = $objects[0].DistinguishedName
        $spns = @($objects[0].ServicePrincipalName | Where-Object { $_ })
        if ($spns.Count -eq 0) {
            [pscustomobject]@{
                ServicePrincipalName = $null
                QuerySource = $source
                OwnerSamAccountName = $objects[0].SamAccountName
                OwnerDistinguishedName = $objects[0].DistinguishedName
                OwnerObjectClass = [string]$objects[0].ObjectClass
                OwnerCount = 0
                Duplicate = $false
                Status = 'NoSpnAssigned'
            }
            return
        }
    }
    else {
        $spns = @($ServicePrincipalName)
        $source = 'ExplicitSPN'
    }

    foreach ($spn in $spns | Sort-Object -Unique) {
        $safeSpn = ConvertTo-SchunkLdapValue -Value $spn
        $owners = @(Get-ADObject -LDAPFilter "(servicePrincipalName=$safeSpn)" -Properties servicePrincipalName,sAMAccountName,objectClass -ErrorAction Stop)

        if ($owners.Count -eq 0) {
            [pscustomobject]@{
                ServicePrincipalName = $spn
                QuerySource = $source
                OwnerSamAccountName = $null
                OwnerDistinguishedName = $null
                OwnerObjectClass = $null
                OwnerCount = 0
                Duplicate = $false
                Status = 'Unowned'
            }
            continue
        }

        foreach ($owner in $owners) {
            [pscustomobject]@{
                ServicePrincipalName = $spn
                QuerySource = $source
                OwnerSamAccountName = $owner.SamAccountName
                OwnerDistinguishedName = $owner.DistinguishedName
                OwnerObjectClass = [string]$owner.ObjectClass
                OwnerCount = $owners.Count
                Duplicate = $owners.Count -gt 1
                Status = if ($owners.Count -gt 1) { 'Duplicate' } else { 'Unique' }
            }
        }
    }
}
