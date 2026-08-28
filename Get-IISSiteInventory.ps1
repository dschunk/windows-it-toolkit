<#
.SYNOPSIS
Inventories IIS sites, bindings, application pools, paths, and runtime state.
.NOTES
Author: David Schunk
Source: https://github.com/dschunk/windows-it-toolkit
License: MIT
#>
[CmdletBinding()]
param()

if(-not (Get-Module -ListAvailable WebAdministration)){throw 'The WebAdministration module and IIS management tools are required.'}
Import-Module WebAdministration

Get-Website | ForEach-Object {
    $site=$_
    $pool=Get-Item "IIS:\AppPools\$($site.ApplicationPool)" -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name=$site.Name;Id=$site.Id;State=$site.State;PhysicalPath=$site.PhysicalPath
        ApplicationPool=$site.ApplicationPool;PoolState=if($pool){$pool.State}else{$null}
        ManagedRuntimeVersion=if($pool){$pool.ManagedRuntimeVersion}else{$null}
        PipelineMode=if($pool){$pool.ManagedPipelineMode}else{$null}
        Bindings=@($site.Bindings.Collection | ForEach-Object {"$($_.protocol)://$($_.bindingInformation)"}) -join '; '
        LogDirectory=$site.LogFile.Directory
    }
}
