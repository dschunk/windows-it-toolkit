function Test-SchunkNetworkPath {
    <#
    .SYNOPSIS
    Tests DNS, ICMP, and TCP connectivity to a destination.

    .DESCRIPTION
    Resolves a destination, performs a single ICMP test, then measures a
    bounded TCP connection attempt for each requested port.

    .PARAMETER ComputerName
    DNS name or IP address to test.

    .PARAMETER Port
    One or more TCP ports. The default is 53, 80, 443, and 3389.

    .PARAMETER TimeoutMilliseconds
    Maximum time to wait for each TCP connection.

    .EXAMPLE
    Test-SchunkNetworkPath -ComputerName server01 -Port 53,443,3389

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Alias('HostName')]
        [string]$ComputerName,

        [ValidateRange(1, 65535)]
        [int[]]$Port = @(53, 80, 443, 3389),

        [ValidateRange(100, 30000)]
        [int]$TimeoutMilliseconds = 2000
    )

    $addresses = try {
        [System.Net.Dns]::GetHostAddresses($ComputerName).IPAddressToString
    }
    catch {
        @()
    }
    $ping = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -ErrorAction SilentlyContinue

    foreach ($targetPort in $Port) {
        $client = [System.Net.Sockets.TcpClient]::new()
        $timer = [System.Diagnostics.Stopwatch]::StartNew()
        $open = $false
        $errorText = $null

        try {
            $task = $client.ConnectAsync($ComputerName, $targetPort)
            if ($task.Wait($TimeoutMilliseconds) -and $client.Connected) {
                $open = $true
            }
            else {
                $errorText = 'Timeout'
            }
        }
        catch {
            $errorText = $_.Exception.GetBaseException().Message
        }
        finally {
            $timer.Stop()
            $client.Dispose()
        }

        [pscustomobject]@{
            Destination = $ComputerName
            Addresses = $addresses -join ', '
            Ping = $ping
            Port = $targetPort
            TcpOpen = $open
            LatencyMs = $timer.ElapsedMilliseconds
            Error = $errorText
        }
    }
}
