function Get-SchunkScheduledTaskAudit {
    <#
    .SYNOPSIS
    Audits scheduled task identity, elevation, actions, and execution state.

    .PARAMETER TaskPath
    Task Scheduler path prefix to inspect.

    .PARAMETER IncludeMicrosoft
    Includes tasks beneath the Microsoft task path.

    .EXAMPLE
    Get-SchunkScheduledTaskAudit

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$TaskPath = '\',
        [switch]$IncludeMicrosoft
    )

    Get-ScheduledTask |
        Where-Object {
            $_.TaskPath -like "$TaskPath*" -and ($IncludeMicrosoft -or $_.TaskPath -notlike '\Microsoft\*')
        } |
        ForEach-Object {
            $task = $_
            $info = $task | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
            [pscustomobject]@{
                TaskPath = $task.TaskPath
                TaskName = $task.TaskName
                State = $task.State
                Author = $task.Author
                RunAs = $task.Principal.UserId
                LogonType = $task.Principal.LogonType
                RunLevel = $task.Principal.RunLevel
                LastRunTime = $info.LastRunTime
                LastTaskResult = $info.LastTaskResult
                NextRunTime = $info.NextRunTime
                MissedRuns = $info.NumberOfMissedRuns
                Actions = $task.Actions.Execute -join '; '
            }
        } |
        Sort-Object TaskPath, TaskName
}
