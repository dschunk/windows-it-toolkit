[CmdletBinding()]
param(
    [ValidateRange(1,3650)][int]$Days = 60,
    [string]$StorePath = "Cert:\LocalMachine\My"
)

$deadline = (Get-Date).AddDays($Days)
Get-ChildItem -Path $StorePath -ErrorAction Stop |
    Where-Object { $_.NotAfter -le $deadline } |
    Sort-Object NotAfter |
    Select-Object Subject, Thumbprint, NotBefore, NotAfter,
        @{Name="DaysRemaining";Expression={[math]::Floor(($_.NotAfter - (Get-Date)).TotalDays)}},
        @{Name="Expired";Expression={$_.NotAfter -lt (Get-Date)}}
