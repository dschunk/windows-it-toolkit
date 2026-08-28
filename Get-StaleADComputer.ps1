[CmdletBinding()]
param(
    [ValidateRange(1,3650)][int]$InactiveDays = 90,
    [string]$SearchBase,
    [switch]$IncludeDisabled
)

if (-not (Get-Module -ListAvailable ActiveDirectory)) {throw 'The ActiveDirectory PowerShell module is required.'}
Import-Module ActiveDirectory
$cutoff=(Get-Date).AddDays(-$InactiveDays)
$params=@{Filter='*';Properties=@('Enabled','LastLogonDate','PasswordLastSet','OperatingSystem','OperatingSystemVersion','IPv4Address','WhenCreated')}
if($SearchBase){$params.SearchBase=$SearchBase}

Get-ADComputer @params | Where-Object {
    ($IncludeDisabled -or $_.Enabled) -and (-not $_.LastLogonDate -or $_.LastLogonDate -lt $cutoff)
} | Select-Object Name,Enabled,OperatingSystem,OperatingSystemVersion,IPv4Address,LastLogonDate,PasswordLastSet,WhenCreated,
    @{n='InactiveDays';e={if($_.LastLogonDate){[math]::Floor(((Get-Date)-$_.LastLogonDate).TotalDays)}else{$null}}} |
    Sort-Object InactiveDays -Descending
