[CmdletBinding()]
param(
    [string[]]$CriticalServices = @("WinRM", "EventLog"),
    [int]$EventLookbackHours = 24
)

$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = 3"
$since = (Get-Date).AddHours(-1 * $EventLookbackHours)
$totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)

$services = foreach ($name in $CriticalServices) {
    $service = Get-Service -Name $name -ErrorAction SilentlyContinue
    [pscustomobject]@{ Name = $name; Status = if ($service) { $service.Status } else { "NotFound" } }
}

$errors = try {
    (Get-WinEvent -FilterHashtable @{ LogName = "System"; Level = 1,2; StartTime = $since } -ErrorAction Stop | Measure-Object).Count
} catch { $null }

[pscustomobject]@{
    ComputerName = $env:COMPUTERNAME
    CollectedAt = Get-Date
    UptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 2)
    CpuLogicalCount = ($cpu.NumberOfLogicalProcessors | Measure-Object -Sum).Sum
    MemoryUsedPercent = [math]::Round((($totalGB - $freeGB) / $totalGB) * 100, 1)
    Disks = @($disks | ForEach-Object { [pscustomobject]@{
        Drive = $_.DeviceID
        SizeGB = [math]::Round($_.Size / 1GB, 1)
        FreeGB = [math]::Round($_.FreeSpace / 1GB, 1)
        FreePercent = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
    }})
    CriticalServices = @($services)
    RecentSystemErrors = $errors
}
