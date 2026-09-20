function Get-SchunkHyperVHealth {
    <#
    .SYNOPSIS
    Collects Hyper-V host, VM, virtual-switch, disk, and checkpoint health.

    .DESCRIPTION
    Returns a read-only health snapshot from the local Hyper-V host. It includes
    VM state, integration service status, attached VHD/VHDX paths, checkpoints,
    and virtual switches.

    .PARAMETER CheckpointAgeDays
    Age in days after which a checkpoint is flagged as old.

    .EXAMPLE
    Get-SchunkHyperVHealth -CheckpointAgeDays 7

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 3650)]
        [int]$CheckpointAgeDays = 7
    )

    if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
        throw 'The Hyper-V PowerShell module is not available on this computer.'
    }

    Import-Module Hyper-V -ErrorAction Stop
    $cutoff = (Get-Date).AddDays(-1 * $CheckpointAgeDays)
    $hostInfo = Get-VMHost

    $vms = @(Get-VM | ForEach-Object {
        $vm = $_
        $drives = @(Get-VMHardDiskDrive -VMName $vm.Name -ErrorAction SilentlyContinue | ForEach-Object {
            $vhd = $null
            if ($_.Path -and (Test-Path -LiteralPath $_.Path)) {
                $vhd = Get-VHD -Path $_.Path -ErrorAction SilentlyContinue
            }
            [pscustomobject]@{
                Path       = $_.Path
                VhdType    = if ($vhd) { $vhd.VhdType } else { $null }
                FileSizeGB = if ($vhd) { [math]::Round($vhd.FileSize / 1GB, 2) } else { $null }
                SizeGB     = if ($vhd) { [math]::Round($vhd.Size / 1GB, 2) } else { $null }
            }
        })

        $checkpoints = @(Get-VMSnapshot -VMName $vm.Name -ErrorAction SilentlyContinue | ForEach-Object {
            [pscustomobject]@{
                Name        = $_.Name
                CreationTime= $_.CreationTime
                AgeDays     = [math]::Round(((Get-Date) - $_.CreationTime).TotalDays, 1)
                IsOld       = $_.CreationTime -lt $cutoff
            }
        })

        [pscustomobject]@{
            Name              = $vm.Name
            State             = $vm.State
            Status            = $vm.Status
            Uptime            = $vm.Uptime
            ProcessorCount    = $vm.ProcessorCount
            MemoryAssignedGB  = [math]::Round($vm.MemoryAssigned / 1GB, 2)
            Generation        = $vm.Generation
            AutomaticStartAction = $vm.AutomaticStartAction
            IntegrationServices = @(Get-VMIntegrationService -VMName $vm.Name | Select-Object Name, Enabled, PrimaryStatusDescription)
            Disks             = $drives
            Checkpoints       = $checkpoints
        }
    })

    $switches = @(Get-VMSwitch | Select-Object Name, SwitchType, NetAdapterInterfaceDescription, AllowManagementOS)

    [pscustomobject]@{
        ComputerName       = $env:COMPUTERNAME
        CollectedAt        = Get-Date
        Available          = $true
        LogicalProcessorCount = $hostInfo.LogicalProcessorCount
        MemoryCapacityGB   = [math]::Round($hostInfo.MemoryCapacity / 1GB, 2)
        VirtualMachineCount= $vms.Count
        RunningVmCount     = @($vms | Where-Object State -eq 'Running').Count
        OldCheckpointCount = @($vms.Checkpoints | Where-Object IsOld).Count
        VirtualMachines    = $vms
        VirtualSwitches    = $switches
    }
}
