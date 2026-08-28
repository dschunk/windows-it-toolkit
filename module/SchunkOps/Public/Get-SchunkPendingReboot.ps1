function Get-SchunkPendingReboot {
    <#
    .SYNOPSIS
    Explains whether the local Windows computer has a pending reboot.

    .DESCRIPTION
    Checks Component Based Servicing, Windows Update, pending file renames,
    update state, and a pending computer rename.

    .EXAMPLE
    Get-SchunkPendingReboot

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param()

    $componentBasedServicing = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
    $windowsUpdate = Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
    $pendingRename = $null -ne (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name PendingFileRenameOperations -ErrorAction SilentlyContinue)
    $updateExeVolatile = (Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Updates' -Name UpdateExeVolatile -ErrorAction SilentlyContinue) -ne 0

    $computerRename = $false
    try {
        $activeName = Get-ItemPropertyValue 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -Name ComputerName
        $pendingName = Get-ItemPropertyValue 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -Name ComputerName
        $computerRename = $activeName -ne $pendingName
    }
    catch {
        Write-Verbose "Unable to compare active and pending computer names: $($_.Exception.Message)"
    }

    [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        PendingReboot = $componentBasedServicing -or $windowsUpdate -or $pendingRename -or $updateExeVolatile -or $computerRename
        ComponentBasedServicing = $componentBasedServicing
        WindowsUpdate = $windowsUpdate
        PendingFileRename = $pendingRename
        UpdateExeVolatile = $updateExeVolatile
        PendingComputerRename = $computerRename
        CollectedAt = Get-Date
    }
}
