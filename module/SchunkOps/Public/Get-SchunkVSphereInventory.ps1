function Get-SchunkVSphereInventory {
    <#
    .SYNOPSIS
    Summarizes connected VMware vSphere inventory and operational problems.

    .DESCRIPTION
    Uses an existing VMware PowerCLI connection to summarize ESXi hosts, virtual
    machines, clusters, and datastores. Optional snapshot collection highlights
    snapshots older than a configurable age. The command never connects with
    credentials on the operator's behalf and does not alter vSphere state.

    .PARAMETER ServerName
    Optional wildcard filter for currently connected vCenter or ESXi servers.

    .PARAMETER DatastoreWarningFreePercent
    Flags datastores below this free-space percentage. Defaults to 15.

    .PARAMETER IncludeSnapshots
    Includes snapshot counts and snapshots older than SnapshotAgeDays.

    .PARAMETER SnapshotAgeDays
    Snapshot age threshold used with IncludeSnapshots. Defaults to 7 days.

    .EXAMPLE
    Connect-VIServer vcsa01.contoso.com
    Get-SchunkVSphereInventory

    .EXAMPLE
    Get-SchunkVSphereInventory -IncludeSnapshots -SnapshotAgeDays 3

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Requires VMware PowerCLI and an existing Connect-VIServer session.
    #>
    [CmdletBinding()]
    param(
        [string]$ServerName = '*',

        [ValidateRange(1, 99)]
        [int]$DatastoreWarningFreePercent = 15,

        [switch]$IncludeSnapshots,

        [ValidateRange(1, 3650)]
        [int]$SnapshotAgeDays = 7
    )

    $requiredCommands = @('Get-VMHost', 'Get-VM', 'Get-Datastore', 'Get-Cluster')
    foreach ($name in $requiredCommands) {
        if (-not (Get-Command $name -Module VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
            throw 'VMware PowerCLI is required. Install VMware.PowerCLI and establish a Connect-VIServer session first.'
        }
    }

    $serverVariable = Get-Variable -Name DefaultVIServers -Scope Global -ErrorAction SilentlyContinue
    $servers = if ($serverVariable) { @($serverVariable.Value | Where-Object { $_.Name -like $ServerName }) } else { @() }
    if ($servers.Count -eq 0) {
        throw "No active PowerCLI VIServer connection matched '$ServerName'. Run Connect-VIServer first."
    }

    $getVmHost = Get-Command Get-VMHost -Module VMware.VimAutomation.Core -ErrorAction Stop
    $getVm = Get-Command Get-VM -Module VMware.VimAutomation.Core -ErrorAction Stop
    $getDatastore = Get-Command Get-Datastore -Module VMware.VimAutomation.Core -ErrorAction Stop
    $getCluster = Get-Command Get-Cluster -Module VMware.VimAutomation.Core -ErrorAction Stop
    $getSnapshot = if ($IncludeSnapshots) { Get-Command Get-Snapshot -Module VMware.VimAutomation.Core -ErrorAction Stop } else { $null }

    foreach ($server in $servers) {
        $hosts = @(& $getVmHost -Server $server -ErrorAction Stop)
        $vms = @(& $getVm -Server $server -ErrorAction Stop)
        $datastores = @(& $getDatastore -Server $server -ErrorAction Stop)
        $clusters = @(& $getCluster -Server $server -ErrorAction Stop)

        $problemHosts = @($hosts | Where-Object {
            [string]$_.ConnectionState -ne 'Connected' -or [string]$_.PowerState -ne 'PoweredOn'
        } | Select-Object Name,ConnectionState,PowerState,Version,Build)

        $lowDatastores = @($datastores | ForEach-Object {
            $freePercent = if ($_.CapacityGB -gt 0) { [math]::Round(($_.FreeSpaceGB / $_.CapacityGB) * 100, 1) } else { $null }
            if ($null -ne $freePercent -and $freePercent -lt $DatastoreWarningFreePercent) {
                [pscustomobject]@{
                    Name = $_.Name
                    Type = $_.Type
                    CapacityGB = [math]::Round($_.CapacityGB, 1)
                    FreeSpaceGB = [math]::Round($_.FreeSpaceGB, 1)
                    FreePercent = $freePercent
                }
            }
        })

        $snapshots = @()
        $oldSnapshots = @()
        if ($IncludeSnapshots) {
            foreach ($vm in $vms) {
                try {
                    $vmSnapshots = @(& $getSnapshot -VM $vm -ErrorAction Stop)
                    $snapshots += $vmSnapshots
                }
                catch {
                    Write-Verbose "Snapshot query failed for VM '$($vm.Name)': $($_.Exception.GetBaseException().Message)"
                }
            }
            $cutoff = (Get-Date).AddDays(-1 * $SnapshotAgeDays)
            $oldSnapshots = @($snapshots | Where-Object { $_.Created -lt $cutoff } |
                Select-Object Name,VM,Created,SizeGB,Description)
        }

        [pscustomobject]@{
            Server = $server.Name
            CollectedAt = Get-Date
            HostCount = $hosts.Count
            ProblemHostCount = $problemHosts.Count
            ProblemHosts = $problemHosts
            VMCount = $vms.Count
            PoweredOnVMCount = @($vms | Where-Object { [string]$_.PowerState -eq 'PoweredOn' }).Count
            PoweredOffVMCount = @($vms | Where-Object { [string]$_.PowerState -eq 'PoweredOff' }).Count
            ClusterCount = $clusters.Count
            DatastoreCount = $datastores.Count
            LowDatastoreCount = $lowDatastores.Count
            LowDatastores = $lowDatastores
            SnapshotCollectionEnabled = [bool]$IncludeSnapshots
            SnapshotCount = if ($IncludeSnapshots) { $snapshots.Count } else { $null }
            OldSnapshotCount = if ($IncludeSnapshots) { $oldSnapshots.Count } else { $null }
            OldSnapshots = if ($IncludeSnapshots) { $oldSnapshots } else { @() }
            Healthy = $problemHosts.Count -eq 0 -and $lowDatastores.Count -eq 0 -and ($oldSnapshots.Count -eq 0)
        }
    }
}
