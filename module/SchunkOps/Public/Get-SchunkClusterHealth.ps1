function Get-SchunkClusterHealth {
    <#
    .SYNOPSIS
    Collects a concise Windows Failover Cluster health summary.

    .DESCRIPTION
    Reads cluster nodes, clustered groups, resources, shared volumes, networks,
    and quorum information and returns one structured health object. Failed or
    non-online components are preserved in problem collections so an engineer
    can quickly see whether the issue is node, role, resource, storage, network,
    or quorum related.

    The command is read-only and does not move roles, restart resources, or change quorum.

    .PARAMETER Cluster
    Optional cluster name. When omitted, the local cluster context is used.

    .EXAMPLE
    Get-SchunkClusterHealth

    .EXAMPLE
    Get-SchunkClusterHealth -Cluster sqlcluster01 | Format-List

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Requires the FailoverClusters module and permission to query the target cluster.
    #>
    [CmdletBinding()]
    param(
        [string]$Cluster
    )

    if (-not (Get-Command Get-ClusterNode -ErrorAction SilentlyContinue)) {
        throw 'The FailoverClusters module is required. Install the Failover Clustering management tools first.'
    }

    $clusterParams = @{}
    if ($Cluster) { $clusterParams.Cluster = $Cluster }

    $clusterObject = if ($Cluster) { Get-Cluster -Name $Cluster -ErrorAction Stop } else { Get-Cluster -ErrorAction Stop }
    $nodes = @(Get-ClusterNode @clusterParams -ErrorAction Stop)
    $groups = @(Get-ClusterGroup @clusterParams -ErrorAction Stop)
    $resources = @(Get-ClusterResource @clusterParams -ErrorAction Stop)
    $networks = @(Get-ClusterNetwork @clusterParams -ErrorAction Stop)
    $sharedVolumes = @()
    try { $sharedVolumes = @(Get-ClusterSharedVolume @clusterParams -ErrorAction Stop) } catch { $sharedVolumes = @() }
    $quorum = $null
    try { $quorum = Get-ClusterQuorum @clusterParams -ErrorAction Stop } catch { $quorum = $null }

    $problemNodes = @($nodes | Where-Object { [string]$_.State -ne 'Up' } | Select-Object Name,State,NodeWeight,DynamicWeight)
    $problemGroups = @($groups | Where-Object { [string]$_.State -ne 'Online' } | Select-Object Name,State,OwnerNode,GroupType)
    $problemResources = @($resources | Where-Object { [string]$_.State -ne 'Online' } | Select-Object Name,State,OwnerGroup,OwnerNode,ResourceType)
    $problemNetworks = @($networks | Where-Object { [string]$_.State -ne 'Up' } | Select-Object Name,State,Role,Address,AddressMask)
    $problemCsvs = @($sharedVolumes | Where-Object { [string]$_.State -ne 'Online' } | Select-Object Name,State,OwnerNode)

    [pscustomobject]@{
        ClusterName = $clusterObject.Name
        CollectedAt = Get-Date
        NodeCount = $nodes.Count
        NodesUp = @($nodes | Where-Object { [string]$_.State -eq 'Up' }).Count
        NodesProblem = $problemNodes.Count
        GroupCount = $groups.Count
        GroupsOnline = @($groups | Where-Object { [string]$_.State -eq 'Online' }).Count
        GroupsProblem = $problemGroups.Count
        ResourceCount = $resources.Count
        ResourcesOnline = @($resources | Where-Object { [string]$_.State -eq 'Online' }).Count
        ResourcesProblem = $problemResources.Count
        NetworkCount = $networks.Count
        NetworksProblem = $problemNetworks.Count
        SharedVolumeCount = $sharedVolumes.Count
        SharedVolumesProblem = $problemCsvs.Count
        QuorumResource = if ($quorum) { [string]$quorum.QuorumResource } else { $null }
        QuorumType = if ($quorum) { [string]$quorum.QuorumType } else { $null }
        Healthy = ($problemNodes.Count + $problemGroups.Count + $problemResources.Count + $problemNetworks.Count + $problemCsvs.Count) -eq 0
        ProblemNodes = $problemNodes
        ProblemGroups = $problemGroups
        ProblemResources = $problemResources
        ProblemNetworks = $problemNetworks
        ProblemSharedVolumes = $problemCsvs
    }
}
