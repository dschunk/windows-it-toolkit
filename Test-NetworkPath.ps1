[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ComputerName,
    [ValidateRange(1,65535)][int[]]$Ports = @(53,80,443,3389),
    [ValidateRange(100,30000)][int]$TimeoutMilliseconds = 2000
)

$addresses = try { [System.Net.Dns]::GetHostAddresses($ComputerName).IPAddressToString } catch { @() }
$ping = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue

foreach ($port in $Ports) {
    $client = [System.Net.Sockets.TcpClient]::new()
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $open = $false
    $errorText = $null
    try {
        $task = $client.ConnectAsync($ComputerName, $port)
        if ($task.Wait($TimeoutMilliseconds) -and $client.Connected) { $open = $true }
        else { $errorText = "Timeout" }
    } catch { $errorText = $_.Exception.GetBaseException().Message }
    finally { $timer.Stop(); $client.Dispose() }

    [pscustomobject]@{
        Destination = $ComputerName; Addresses = $addresses -join ", "; Ping = $ping
        Port = $port; TcpOpen = $open; LatencyMs = $timer.ElapsedMilliseconds; Error = $errorText
    }
}
