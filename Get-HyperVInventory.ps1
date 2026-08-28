<#
.SYNOPSIS
Reports Hyper-V virtual machines, generation, state, resources, uptime, and checkpoints.
.NOTES
Author: David Schunk
Source: https://github.com/dschunk/windows-it-toolkit
License: MIT
#>
[CmdletBinding()]
param([string]$ComputerName=$env:COMPUTERNAME)

if(-not (Get-Module -ListAvailable Hyper-V)){throw 'The Hyper-V PowerShell module is required.'}
Import-Module Hyper-V

Get-VM -ComputerName $ComputerName | ForEach-Object {
    $vm=$_
    $drives=@($vm | Get-VMHardDiskDrive -ErrorAction SilentlyContinue)
    $adapters=@($vm | Get-VMNetworkAdapter -ErrorAction SilentlyContinue)
    [pscustomobject]@{
        Host=$ComputerName;Name=$vm.Name;Generation=$vm.Generation;State=$vm.State
        Status=$vm.Status;Version=$vm.Version;ProcessorCount=$vm.ProcessorCount
        MemoryAssignedGB=[math]::Round($vm.MemoryAssigned/1GB,2)
        MemoryDemandGB=[math]::Round($vm.MemoryDemand/1GB,2)
        DynamicMemoryEnabled=$vm.DynamicMemoryEnabled;Uptime=$vm.Uptime
        AutomaticStartAction=$vm.AutomaticStartAction;AutomaticStopAction=$vm.AutomaticStopAction
        Checkpoints=@($vm | Get-VMSnapshot -ErrorAction SilentlyContinue).Count
        DiskCount=$drives.Count;NetworkAdapters=$adapters.Count
        ConfigurationLocation=$vm.ConfigurationLocation
    }
}
