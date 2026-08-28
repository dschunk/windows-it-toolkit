[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateScript({Test-Path -LiteralPath $_ -PathType Container})][string]$Path,
    [ValidateRange(0,10)][int]$Depth = 1,
    [switch]$IncludeInherited
)

$root = Get-Item -LiteralPath $Path
$targets = @($root)
if ($Depth -gt 0) {
    $targets += Get-ChildItem -LiteralPath $Path -Directory -Recurse -Depth $Depth -ErrorAction SilentlyContinue
}

foreach ($target in $targets) {
    try {
        $acl = Get-Acl -LiteralPath $target.FullName -ErrorAction Stop
        foreach ($rule in $acl.Access) {
            if ($IncludeInherited -or -not $rule.IsInherited) {
                [pscustomobject]@{
                    Path = $target.FullName
                    Owner = $acl.Owner
                    Identity = $rule.IdentityReference.Value
                    Rights = $rule.FileSystemRights
                    Type = $rule.AccessControlType
                    Inherited = $rule.IsInherited
                    InheritanceFlags = $rule.InheritanceFlags
                    PropagationFlags = $rule.PropagationFlags
                }
            }
        }
    } catch {
        Write-Warning "Unable to inspect $($target.FullName): $($_.Exception.Message)"
    }
}
