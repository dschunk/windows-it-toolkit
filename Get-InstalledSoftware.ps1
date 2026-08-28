[CmdletBinding()]
param([string]$Name)

$paths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

Get-ItemProperty -Path $paths -ErrorAction SilentlyContinue |
    Where-Object {$_.DisplayName -and (-not $Name -or $_.DisplayName -like "*$Name*")} |
    Select-Object @{n='Name';e={$_.DisplayName}},DisplayVersion,Publisher,InstallDate,
        @{n='Architecture';e={if($_.PSPath -like '*WOW6432Node*'){'32-bit'}else{'64-bit'}}},
        UninstallString |
    Sort-Object Name,DisplayVersion -Unique
