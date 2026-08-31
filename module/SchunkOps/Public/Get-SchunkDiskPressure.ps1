function Get-SchunkDiskPressure {
    <#
    .SYNOPSIS
    Reports fixed-disk capacity with warning and critical free-space thresholds.

    .DESCRIPTION
    Returns one object per fixed disk with total size, free space, free-space percentage,
    and an operational status of OK, Warning, or Critical. The command is intentionally
    small and pipeline-friendly so it can be used interactively, in scheduled checks, or
    as part of a ticket escalation workflow.

    .PARAMETER WarningFreePercent
    Free-space percentage at or below which a disk is marked Warning.

    .PARAMETER CriticalFreePercent
    Free-space percentage at or below which a disk is marked Critical.

    .EXAMPLE
    Get-SchunkDiskPressure

    .EXAMPLE
    Get-SchunkDiskPressure -WarningFreePercent 20 -CriticalFreePercent 8 | Where-Object Status -ne 'OK'

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 99)]
        [int]$WarningFreePercent = 15,

        [ValidateRange(1, 99)]
        [int]$CriticalFreePercent = 8
    )

    if ($CriticalFreePercent -gt $WarningFreePercent) {
        throw 'CriticalFreePercent must be less than or equal to WarningFreePercent.'
    }

    Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop | ForEach-Object {
        $freePercent = if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { $null }
        $status = if ($null -eq $freePercent) {
            'Unknown'
        }
        elseif ($freePercent -le $CriticalFreePercent) {
            'Critical'
        }
        elseif ($freePercent -le $WarningFreePercent) {
            'Warning'
        }
        else {
            'OK'
        }

        [pscustomobject]@{
            ComputerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
            Drive = $_.DeviceID
            Label = $_.VolumeName
            FileSystem = $_.FileSystem
            SizeGB = [math]::Round($_.Size / 1GB, 2)
            FreeGB = [math]::Round($_.FreeSpace / 1GB, 2)
            UsedGB = [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)
            FreePercent = $freePercent
            Status = $status
            WarningThresholdPercent = $WarningFreePercent
            CriticalThresholdPercent = $CriticalFreePercent
            CollectedAt = Get-Date
        }
    }
}
