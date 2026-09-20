function Get-SchunkIisLogSummary {
    <#
    .SYNOPSIS
    Summarizes recent IIS W3C log activity.

    .DESCRIPTION
    Parses recent IIS W3C log files and returns request counts, HTTP status-code
    distribution, top URI stems, and top client IP addresses. The command is
    read-only and does not require the IIS PowerShell module.

    .PARAMETER LogPath
    Root IIS log directory.

    .PARAMETER Hours
    Only log files modified within this lookback window are inspected.

    .PARAMETER MaxFiles
    Maximum number of recent log files to parse.

    .PARAMETER Top
    Number of top URI/client entries to return.

    .EXAMPLE
    Get-SchunkIisLogSummary -Hours 24

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$LogPath = 'C:\inetpub\logs\LogFiles',

        [ValidateRange(1, 720)]
        [int]$Hours = 24,

        [ValidateRange(1, 500)]
        [int]$MaxFiles = 50,

        [ValidateRange(1, 100)]
        [int]$Top = 10
    )

    if (-not (Test-Path -LiteralPath $LogPath)) {
        throw "IIS log path not found: $LogPath"
    }

    $cutoff = (Get-Date).AddHours(-1 * $Hours)
    $files = @(Get-ChildItem -LiteralPath $LogPath -Recurse -File -Filter '*.log' -ErrorAction Stop | Where-Object LastWriteTime -ge $cutoff | Sort-Object LastWriteTime -Descending | Select-Object -First $MaxFiles)
    $records = New-Object System.Collections.Generic.List[object]

    foreach ($file in $files) {
        $fields = $null
        foreach ($line in [System.IO.File]::ReadLines($file.FullName)) {
            if ($line.StartsWith('#Fields:')) {
                $fields = @($line.Substring(8).Trim() -split '\s+')
                continue
            }

            if ($line.StartsWith('#') -or [string]::IsNullOrWhiteSpace($line) -or -not $fields) {
                continue
            }

            $values = @($line -split '\s+')
            if ($values.Count -lt $fields.Count) {
                continue
            }

            $row = @{}
            for ($i = 0; $i -lt $fields.Count; $i++) {
                $row[$fields[$i]] = $values[$i]
            }

            $records.Add([pscustomobject]@{
                Status    = $row['sc-status']
                UriStem   = $row['cs-uri-stem']
                ClientIp  = $row['c-ip']
                Method    = $row['cs-method']
                TimeTaken = $row['time-taken']
                SiteName  = $row['s-sitename']
                Host      = $row['cs-host']
            })
        }
    }

    $statusCodes = @($records | Group-Object Status | Sort-Object Count -Descending | Select-Object @{N='Status';E={$_.Name}}, Count)
    $topUris = @($records | Where-Object UriStem | Group-Object UriStem | Sort-Object Count -Descending | Select-Object -First $Top @{N='UriStem';E={$_.Name}}, Count)
    $topClients = @($records | Where-Object ClientIp | Group-Object ClientIp | Sort-Object Count -Descending | Select-Object -First $Top @{N='ClientIp';E={$_.Name}}, Count)

    [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        CollectedAt  = Get-Date
        LogPath      = $LogPath
        FileCount    = $files.Count
        RequestCount = $records.Count
        StatusCodes  = $statusCodes
        TopUris      = $topUris
        TopClients   = $topClients
        Files        = @($files | Select-Object FullName, LastWriteTime, Length)
    }
}
