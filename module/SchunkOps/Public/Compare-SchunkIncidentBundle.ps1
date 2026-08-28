function Compare-SchunkIncidentBundle {
    <#
    .SYNOPSIS
    Compares the integrity manifest of two SchunkOps incident bundles.

    .DESCRIPTION
    Compares collector presence and SHA-256 hashes to identify evidence sets
    that are added, removed, changed, unchanged, or failed between bundles.

    .PARAMETER ReferencePath
    Reference bundle directory or manifest.json path.

    .PARAMETER DifferencePath
    Newer bundle directory or manifest.json path.

    .EXAMPLE
    Compare-SchunkIncidentBundle -ReferencePath C:\IR\Baseline -DifferencePath C:\IR\INC-0042

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [string]$ReferencePath,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ })]
        [string]$DifferencePath
    )

    function Get-BundleManifest {
        param([Parameter(Mandatory)][string]$Path)

        $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
        $manifestPath = if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
            Join-Path $resolvedPath 'manifest.json'
        }
        else {
            $resolvedPath
        }

        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
            throw "No manifest.json was found at $Path."
        }

        Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop | ConvertFrom-Json
    }

    $reference = Get-BundleManifest -Path $ReferencePath
    $difference = Get-BundleManifest -Path $DifferencePath
    $names = @($reference.Collectors.Name) + @($difference.Collectors.Name) | Sort-Object -Unique

    foreach ($name in $names) {
        $before = $reference.Collectors | Where-Object Name -eq $name | Select-Object -First 1
        $after = $difference.Collectors | Where-Object Name -eq $name | Select-Object -First 1

        $change = if (-not $before) {
            'Added'
        }
        elseif (-not $after) {
            'Removed'
        }
        elseif ($before.Status -eq 'Failed' -or $after.Status -eq 'Failed') {
            'CollectionFailed'
        }
        elseif ($before.Sha256 -eq $after.Sha256) {
            'Unchanged'
        }
        else {
            'Changed'
        }

        [pscustomobject]@{
            Collector = $name
            Change = $change
            ReferenceStatus = $before.Status
            DifferenceStatus = $after.Status
            ReferenceRecords = $before.RecordCount
            DifferenceRecords = $after.RecordCount
            ReferenceSha256 = $before.Sha256
            DifferenceSha256 = $after.Sha256
            ReferenceBundleId = $reference.BundleId
            DifferenceBundleId = $difference.BundleId
        }
    }
}
