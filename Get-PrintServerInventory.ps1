<#
.SYNOPSIS
Inventories printers, drivers, ports, sharing, publication, and operational state.
.NOTES
Author: David Schunk
Source: https://github.com/dschunk/windows-it-toolkit
License: MIT
#>
[CmdletBinding()]
param([string]$ComputerName=$env:COMPUTERNAME)

if(-not (Get-Module -ListAvailable PrintManagement)){throw 'The PrintManagement PowerShell module is required.'}
Import-Module PrintManagement

Get-Printer -ComputerName $ComputerName | ForEach-Object {
    [pscustomobject]@{
        Server=$ComputerName;Name=$_.Name;Type=$_.Type;DriverName=$_.DriverName
        PortName=$_.PortName;Shared=$_.Shared;ShareName=$_.ShareName
        Published=$_.Published;PermissionSDDL=$_.PermissionSDDL
        PrinterStatus=$_.PrinterStatus;JobCount=$_.JobCount
        KeepPrintedJobs=$_.KeepPrintedJobs;RenderingMode=$_.RenderingMode
        Comment=$_.Comment;Location=$_.Location
    }
} | Sort-Object Name
