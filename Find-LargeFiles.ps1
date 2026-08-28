[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateScript({Test-Path -LiteralPath $_ -PathType Container})][string]$Path,
    [ValidateRange(1,10000)][int]$Top = 20
)

Get-ChildItem -LiteralPath $Path -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First $Top FullName,
        @{Name="SizeMB";Expression={[math]::Round($_.Length / 1MB, 2)}}, LastWriteTime
