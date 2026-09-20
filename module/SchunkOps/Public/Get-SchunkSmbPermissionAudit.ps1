function Get-SchunkSmbPermissionAudit {
    <#
    .SYNOPSIS
    Audits SMB share permissions and NTFS access rules.

    .DESCRIPTION
    Returns SMB share access entries alongside NTFS ACL information for the share
    root. Administrative shares are excluded by default. The command is read-only.

    .PARAMETER Name
    Optional SMB share name to audit.

    .PARAMETER IncludeAdministrative
    Include administrative and special shares.

    .EXAMPLE
    Get-SchunkSmbPermissionAudit

    .EXAMPLE
    Get-SchunkSmbPermissionAudit -Name Finance

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$Name,
        [switch]$IncludeAdministrative
    )

    $shares = if ($Name) {
        @(Get-SmbShare -Name $Name -ErrorAction Stop)
    }
    else {
        @(Get-SmbShare | Where-Object {
            $IncludeAdministrative -or -not $_.Special
        })
    }

    foreach ($share in $shares) {
        $shareAccess = @(Get-SmbShareAccess -Name $share.Name -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{
                AccountName       = $_.AccountName
                AccessControlType = $_.AccessControlType
                AccessRight       = $_.AccessRight
            }
        })

        $ntfsAccess = @()
        $aclError = $null
        if ($share.Path -and (Test-Path -LiteralPath $share.Path)) {
            try {
                $acl = Get-Acl -LiteralPath $share.Path -ErrorAction Stop
                $ntfsAccess = @($acl.Access | ForEach-Object {
                    [pscustomobject]@{
                        IdentityReference = $_.IdentityReference.Value
                        FileSystemRights  = $_.FileSystemRights
                        AccessControlType = $_.AccessControlType
                        IsInherited       = $_.IsInherited
                        InheritanceFlags  = $_.InheritanceFlags
                        PropagationFlags  = $_.PropagationFlags
                    }
                })
            }
            catch {
                $aclError = $_.Exception.Message
            }
        }

        [pscustomobject]@{
            ComputerName = $env:COMPUTERNAME
            ShareName    = $share.Name
            Path         = $share.Path
            Description  = $share.Description
            EncryptData  = $share.EncryptData
            FolderEnumerationMode = $share.FolderEnumerationMode
            ShareAccess  = $shareAccess
            NtfsAccess   = $ntfsAccess
            NtfsAclError = $aclError
        }
    }
}
