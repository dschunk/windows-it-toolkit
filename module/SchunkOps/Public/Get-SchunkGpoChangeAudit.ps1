function Get-SchunkGpoChangeAudit {
    <#
    .SYNOPSIS
    Finds recently modified Group Policy Objects and optionally compares report fingerprints.

    .DESCRIPTION
    Returns GPO ownership, status, timestamps, version information, WMI filter context,
    and an optional SHA-256 fingerprint of the XML GPO report. When BaselinePath points
    to previously exported JSON containing Id and Fingerprint fields, the command labels
    each GPO as New, Changed, or Unchanged relative to that baseline.

    The command is read-only and does not modify Group Policy.

    .PARAMETER SinceDays
    Include GPOs modified within this many days. Defaults to 30.

    .PARAMETER Name
    Optional wildcard filter for the GPO display name.

    .PARAMETER IncludeFingerprint
    Generates a SHA-256 fingerprint from each matching GPO's XML report.

    .PARAMETER BaselinePath
    Optional JSON baseline previously produced from this command. Supplying a baseline
    automatically enables fingerprint generation.

    .EXAMPLE
    Get-SchunkGpoChangeAudit -SinceDays 14 -IncludeFingerprint

    .EXAMPLE
    Get-SchunkGpoChangeAudit -SinceDays 30 -BaselinePath .\gpo-baseline.json

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Requires the GroupPolicy module and domain read access.
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 3650)]
        [int]$SinceDays = 30,

        [string]$Name = '*',

        [switch]$IncludeFingerprint,

        [string]$BaselinePath
    )

    if (-not (Get-Command Get-GPO -ErrorAction SilentlyContinue)) {
        throw 'The GroupPolicy module is required. Install the Group Policy Management RSAT tools first.'
    }

    $baseline = @{}
    if ($BaselinePath) {
        if (-not (Test-Path -LiteralPath $BaselinePath)) {
            throw "BaselinePath was not found: $BaselinePath"
        }
        $IncludeFingerprint = $true
        $baselineData = @(Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json)
        foreach ($item in $baselineData) {
            if ($item.Id -and $item.Fingerprint) {
                $baseline[[string]$item.Id] = [string]$item.Fingerprint
            }
        }
    }

    $cutoff = (Get-Date).AddDays(-1 * $SinceDays)
    $gpos = @(Get-GPO -All -ErrorAction Stop | Where-Object {
        $_.DisplayName -like $Name -and $_.ModificationTime -ge $cutoff
    } | Sort-Object ModificationTime -Descending)

    foreach ($gpo in $gpos) {
        $fingerprint = $null
        if ($IncludeFingerprint) {
            $xml = Get-GPOReport -Guid $gpo.Id -ReportType Xml -ErrorAction Stop
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($xml)
                $fingerprint = ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
            }
            finally {
                $sha.Dispose()
            }
        }

        $previousFingerprint = $null
        $changeState = 'NotCompared'
        if ($BaselinePath) {
            $id = [string]$gpo.Id
            if ($baseline.ContainsKey($id)) {
                $previousFingerprint = $baseline[$id]
                $changeState = if ($fingerprint -eq $previousFingerprint) { 'Unchanged' } else { 'Changed' }
            }
            else {
                $changeState = 'New'
            }
        }

        [pscustomobject]@{
            DisplayName = $gpo.DisplayName
            Id = [string]$gpo.Id
            Owner = $gpo.Owner
            GpoStatus = [string]$gpo.GpoStatus
            CreationTime = $gpo.CreationTime
            ModificationTime = $gpo.ModificationTime
            AgeSinceModificationDays = [math]::Round(((Get-Date) - $gpo.ModificationTime).TotalDays, 2)
            ComputerDsVersion = $gpo.Computer.DSVersion
            ComputerSysvolVersion = $gpo.Computer.SysvolVersion
            UserDsVersion = $gpo.User.DSVersion
            UserSysvolVersion = $gpo.User.SysvolVersion
            WmiFilter = if ($gpo.WmiFilter) { $gpo.WmiFilter.Name } else { $null }
            Fingerprint = $fingerprint
            PreviousFingerprint = $previousFingerprint
            ChangeState = $changeState
        }
    }
}
