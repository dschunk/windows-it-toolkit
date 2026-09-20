function Get-SchunkDfsNamespaceHealth {
    <#
    .SYNOPSIS
    Audits DFS Namespace roots, folders, and folder targets.

    .DESCRIPTION
    Uses the Dfsn module to return a read-only inventory of DFS Namespace roots,
    folders, and target state. It also reports local DFS Namespace and DFS
    Replication service state when those services exist.

    .PARAMETER NamespacePath
    Optional namespace root path such as \\contoso.com\Public.

    .EXAMPLE
    Get-SchunkDfsNamespaceHealth

    .EXAMPLE
    Get-SchunkDfsNamespaceHealth -NamespacePath '\\contoso.com\Public'

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string]$NamespacePath
    )

    if (-not (Get-Module -ListAvailable -Name Dfsn)) {
        throw 'The Dfsn PowerShell module is not available. Install the DFS Namespace management tools.'
    }

    Import-Module Dfsn -ErrorAction Stop

    $roots = if ($NamespacePath) {
        @(Get-DfsnRoot -Path $NamespacePath -ErrorAction Stop)
    }
    else {
        @(Get-DfsnRoot -ErrorAction Stop)
    }

    $rootResults = foreach ($root in $roots) {
        $folders = @(Get-DfsnFolder -Path ($root.Path.TrimEnd('\') + '\*') -ErrorAction SilentlyContinue)
        $folderResults = foreach ($folder in $folders) {
            $targets = @(Get-DfsnFolderTarget -Path $folder.Path -ErrorAction SilentlyContinue | Select-Object Path, TargetPath, State, ReferralPriorityClass, ReferralPriorityRank)
            [pscustomobject]@{
                Path          = $folder.Path
                State         = $folder.State
                TimeToLiveSec = $folder.TimeToLiveSec
                TargetCount   = $targets.Count
                Targets       = $targets
            }
        }

        [pscustomobject]@{
            Path          = $root.Path
            Type          = $root.Type
            State         = $root.State
            TimeToLiveSec = $root.TimeToLiveSec
            Description   = $root.Description
            FolderCount   = $folderResults.Count
            Folders       = @($folderResults)
        }
    }

    $dfsnService = Get-Service -Name Dfs -ErrorAction SilentlyContinue
    $dfsrService = Get-Service -Name DFSR -ErrorAction SilentlyContinue

    [pscustomobject]@{
        ComputerName       = $env:COMPUTERNAME
        CollectedAt        = Get-Date
        RootCount          = $rootResults.Count
        NamespaceService   = if ($dfsnService) { $dfsnService.Status } else { 'NotInstalled' }
        ReplicationService = if ($dfsrService) { $dfsrService.Status } else { 'NotInstalled' }
        Roots              = @($rootResults)
    }
}
