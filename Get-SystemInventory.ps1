[CmdletBinding()]
param([string]$OutputPath)

$os = Get-CimInstance Win32_OperatingSystem
$computer = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$adapters = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True'
$inventory = [pscustomobject]@{
    CollectedAt = (Get-Date).ToString('o')
    ComputerName = $env:COMPUTERNAME
    Manufacturer = $computer.Manufacturer
    Model = $computer.Model
    SerialNumber = $bios.SerialNumber
    OperatingSystem = $os.Caption
    OSVersion = $os.Version
    LastBoot = $os.LastBootUpTime
    MemoryGB = [math]::Round($computer.TotalPhysicalMemory/1GB,2)
    IPv4 = @($adapters.IPAddress | Where-Object {$_ -match '^\d{1,3}(\.\d{1,3}){3}$'})
    DnsServers = @($adapters.DNSServerSearchOrder | Select-Object -Unique)
    InstalledHotfixes = @(Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object HotFixID,InstalledOn)
}

if ($OutputPath) {
    $inventory | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}
$inventory
