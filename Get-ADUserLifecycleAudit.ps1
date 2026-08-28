[CmdletBinding()]
param(
    [ValidateRange(1,3650)][int]$InactiveDays = 90,
    [ValidateRange(1,3650)][int]$PasswordAgeDays = 180,
    [string]$SearchBase
)

if (-not (Get-Module -ListAvailable ActiveDirectory)) {throw 'The ActiveDirectory PowerShell module is required.'}
Import-Module ActiveDirectory
$inactiveCutoff=(Get-Date).AddDays(-$InactiveDays)
$passwordCutoff=(Get-Date).AddDays(-$PasswordAgeDays)
$params=@{Filter='*';Properties=@('Enabled','LastLogonDate','PasswordLastSet','PasswordNeverExpires','PasswordExpired','WhenCreated','Description','Manager')}
if($SearchBase){$params.SearchBase=$SearchBase}

Get-ADUser @params | ForEach-Object {
    $findings=@()
    if($_.Enabled -and (-not $_.LastLogonDate -or $_.LastLogonDate -lt $inactiveCutoff)){$findings+='Inactive enabled account'}
    if($_.Enabled -and -not $_.PasswordNeverExpires -and $_.PasswordLastSet -lt $passwordCutoff){$findings+='Old password'}
    if($_.PasswordNeverExpires){$findings+='Password never expires'}
    if($_.PasswordExpired){$findings+='Password expired'}
    [pscustomobject]@{
        SamAccountName=$_.SamAccountName;DisplayName=$_.DisplayName;Enabled=$_.Enabled
        LastLogonDate=$_.LastLogonDate;PasswordLastSet=$_.PasswordLastSet
        PasswordNeverExpires=$_.PasswordNeverExpires;WhenCreated=$_.WhenCreated
        Manager=$_.Manager;Findings=$findings -join '; '
    }
} | Sort-Object @{Expression={if($_.Findings){0}else{1}}},SamAccountName
