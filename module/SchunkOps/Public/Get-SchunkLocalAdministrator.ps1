function Get-SchunkLocalAdministrator {
    <#
    .SYNOPSIS
    Enumerates local Administrators group membership on one or more Windows computers.

    .DESCRIPTION
    Returns the local Administrators membership with principal type, source, and SID.
    Local collection uses Get-LocalGroupMember. Remote collection uses PowerShell remoting,
    making the command useful for endpoint escalation checks, privilege reviews, and drift
    investigations without modifying group membership.

    .PARAMETER ComputerName
    One or more Windows computers. The local computer is used by default.

    .EXAMPLE
    Get-SchunkLocalAdministrator

    .EXAMPLE
    Get-SchunkLocalAdministrator -ComputerName PC001,PC002,SERVER01

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Remote queries require PowerShell remoting and appropriate rights on the target system.
    #>
    [CmdletBinding()]
    param(
        [string[]]$ComputerName = @($env:COMPUTERNAME)
    )

    $collector = {
        if (-not (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue)) {
            throw 'Get-LocalGroupMember is not available on this computer.'
        }

        Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop | ForEach-Object {
            [pscustomobject]@{
                ComputerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
                Name = $_.Name
                ObjectClass = $_.ObjectClass
                PrincipalSource = $_.PrincipalSource
                Sid = if ($_.SID) { $_.SID.Value } else { $null }
            }
        }
    }

    foreach ($computer in $ComputerName) {
        if ([string]::IsNullOrWhiteSpace($computer)) { continue }

        $isLocal = $computer -in @('.', 'localhost', $env:COMPUTERNAME, [Environment]::MachineName)
        if ($isLocal) {
            try {
                & $collector
            }
            catch {
                Write-Error "Unable to enumerate local administrators on $computer: $($_.Exception.GetBaseException().Message)"
            }
            continue
        }

        try {
            Invoke-Command -ComputerName $computer -ScriptBlock $collector -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to enumerate local administrators on $computer: $($_.Exception.GetBaseException().Message)"
        }
    }
}
