[CmdletBinding()]
param([string]$Domain)

if (-not (Get-Module -ListAvailable GroupPolicy)) {
    throw 'The GroupPolicy PowerShell module is required.'
}

Import-Module GroupPolicy
$params = @{All=$true}
if ($Domain) {$params.Domain=$Domain}

Get-GPO @params | ForEach-Object {
    [pscustomobject]@{
        DisplayName = $_.DisplayName
        Id = $_.Id
        GpoStatus = $_.GpoStatus
        CreationTime = $_.CreationTime
        ModificationTime = $_.ModificationTime
        Owner = $_.Owner
        UserVersion = $_.User.DSVersion
        ComputerVersion = $_.Computer.DSVersion
        WmiFilter = $_.WmiFilter.Name
        Description = $_.Description
    }
} | Sort-Object DisplayName
