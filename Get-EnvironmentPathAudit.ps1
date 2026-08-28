<#
.SYNOPSIS
Audits machine and user PATH entries for duplicates, missing directories, and risky current-directory entries.
.NOTES
Author: David Schunk
Source: https://github.com/dschunk/windows-it-toolkit
License: MIT
#>
[CmdletBinding()]
param()

$sources=[ordered]@{
    Machine=[Environment]::GetEnvironmentVariable('Path','Machine')
    User=[Environment]::GetEnvironmentVariable('Path','User')
}
$seen=@{}
foreach($scope in $sources.Keys){
    foreach($raw in @($sources[$scope] -split ';')){
        $entry=$raw.Trim()
        if([string]::IsNullOrWhiteSpace($entry)){continue}
        $expanded=[Environment]::ExpandEnvironmentVariables($entry).TrimEnd('\')
        $key=$expanded.ToLowerInvariant()
        $duplicate=$seen.ContainsKey($key)
        if(-not $duplicate){$seen[$key]="${scope}:$entry"}
        [pscustomobject]@{
            Scope=$scope;Entry=$entry;ExpandedPath=$expanded;Exists=Test-Path -LiteralPath $expanded -PathType Container
            Duplicate=$duplicate;FirstSeen=if($duplicate){$seen[$key]}else{$null}
            CurrentDirectoryEntry=$entry -in @('.','%CD%')
        }
    }
}
