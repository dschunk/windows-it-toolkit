function Get-SchunkWindowsBackupHealth {
    <#
    .SYNOPSIS
    Collects Windows Server Backup status and recent version information.

    .DESCRIPTION
    Runs read-only wbadmin status/version queries and reports the Windows Backup
    engine service plus configured backup scheduled tasks when present. This is
    intended for Windows Server Backup environments; other backup products should
    be checked with their own management tools.

    .EXAMPLE
    Get-SchunkWindowsBackupHealth

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param()

    $wbadmin = Get-Command wbadmin.exe -ErrorAction SilentlyContinue
    $service = Get-Service -Name wbengine -ErrorAction SilentlyContinue

    $statusOutput = @()
    $statusExitCode = $null
    $versionsOutput = @()
    $versionsExitCode = $null

    if ($wbadmin) {
        $statusOutput = @(& $wbadmin.Source get status 2>&1 | ForEach-Object { $_.ToString() })
        $statusExitCode = $LASTEXITCODE

        $versionsOutput = @(& $wbadmin.Source get versions 2>&1 | ForEach-Object { $_.ToString() })
        $versionsExitCode = $LASTEXITCODE
    }

    $tasks = @()
    try {
        $tasks = @(Get-ScheduledTask -TaskPath '\Microsoft\Windows\Backup\' -ErrorAction Stop | Select-Object TaskName, State, Author, Description, @{N='UserId';E={$_.Principal.UserId}})
    }
    catch {
        $tasks = @()
    }

    [pscustomobject]@{
        ComputerName         = $env:COMPUTERNAME
        CollectedAt          = Get-Date
        WbadminAvailable     = [bool]$wbadmin
        BackupEngineStatus   = if ($service) { $service.Status } else { 'NotInstalled' }
        BackupEngineStartType= if ($service) { $service.StartType } else { $null }
        ScheduledTasks       = $tasks
        StatusExitCode       = $statusExitCode
        StatusOutput         = $statusOutput
        VersionsExitCode     = $versionsExitCode
        VersionsOutput       = $versionsOutput
    }
}
