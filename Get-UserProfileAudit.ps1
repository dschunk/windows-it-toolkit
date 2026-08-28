[CmdletBinding()]
param(
    [ValidateRange(1,3650)][int]$OlderThanDays=180,
    [switch]$IncludeSpecial
)

$cutoff=(Get-Date).AddDays(-$OlderThanDays)
Get-CimInstance Win32_UserProfile | Where-Object {
    ($IncludeSpecial -or -not $_.Special) -and $_.LocalPath
} | ForEach-Object {
    $profile=$_
    $size=$null
    if(Test-Path -LiteralPath $profile.LocalPath){
        $size=[math]::Round(((Get-ChildItem -LiteralPath $profile.LocalPath -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum)/1GB,2)
    }
    [pscustomobject]@{
        LocalPath=$profile.LocalPath;Sid=$profile.SID;Loaded=$profile.Loaded;Special=$profile.Special
        LastUseTime=$profile.LastUseTime;Inactive=$profile.LastUseTime -lt $cutoff
        SizeGB=$size;Status=$profile.Status
    }
} | Sort-Object LastUseTime
