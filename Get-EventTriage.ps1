[CmdletBinding()]
param(
    [string[]]$LogName = @('System','Application'),
    [ValidateRange(1,720)][int]$Hours = 24,
    [ValidateRange(1,5000)][int]$MaxEvents = 500
)

$start = (Get-Date).AddHours(-$Hours)
$events = foreach ($log in $LogName) {
    try {
        Get-WinEvent -FilterHashtable @{LogName=$log;Level=1,2,3;StartTime=$start} -MaxEvents $MaxEvents -ErrorAction Stop
    } catch {
        Write-Warning "Unable to query $log: $($_.Exception.Message)"
    }
}

$events | Group-Object LogName,ProviderName,Id,LevelDisplayName | ForEach-Object {
    $sample = $_.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1
    [pscustomobject]@{
        Count = $_.Count
        Log = $sample.LogName
        Provider = $sample.ProviderName
        EventId = $sample.Id
        Level = $sample.LevelDisplayName
        Latest = $sample.TimeCreated
        SampleMessage = ($sample.Message -replace '\s+',' ').Trim()
    }
} | Sort-Object Count -Descending
