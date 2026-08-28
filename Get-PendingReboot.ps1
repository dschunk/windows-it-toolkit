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
} catch {}

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
