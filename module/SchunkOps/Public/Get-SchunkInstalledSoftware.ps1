function Get-SchunkInstalledSoftware {
    <#
    .SYNOPSIS
    Inventories installed Windows software without querying Win32_Product.

    .PARAMETER Name
    Optional case-insensitive substring filter for display names.

    .EXAMPLE
    Get-SchunkInstalledSoftware -Name VMware

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$Name
    )

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -and (-not $Name -or $_.DisplayName -like "*$Name*")
        } |
        Select-Object @{
            Name = 'Name'
            Expression = { $_.DisplayName }
        }, DisplayVersion, Publisher, InstallDate, @{
            Name = 'Architecture'
            Expression = {
                if ($_.PSPath -like '*WOW6432Node*') { '32-bit' } else { '64-bit' }
            }
        }, UninstallString |
        Sort-Object Name, DisplayVersion -Unique
}
