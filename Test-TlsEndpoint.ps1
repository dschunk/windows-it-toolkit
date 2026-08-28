[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$HostName,
    [ValidateRange(1,65535)][int]$Port = 443,
    [ValidateRange(1,60)][int]$TimeoutSeconds = 10
)

foreach ($target in $HostName) {
    $tcp = [Net.Sockets.TcpClient]::new()
    $started = Get-Date
    try {
        $connect = $tcp.ConnectAsync($target, $Port)
        if (-not $connect.Wait([TimeSpan]::FromSeconds($TimeoutSeconds))) {
            throw "Connection timed out after $TimeoutSeconds seconds"
        }

        $callback = { param($sender,$certificate,$chain,$errors) return $true }
        $ssl = [Net.Security.SslStream]::new($tcp.GetStream(), $false, $callback)
        $ssl.AuthenticateAsClient($target)
        $cert = [Security.Cryptography.X509Certificates.X509Certificate2]::new($ssl.RemoteCertificate)

        [pscustomobject]@{
            HostName = $target
            Port = $Port
            Reachable = $true
            Protocol = $ssl.SslProtocol
            Subject = $cert.Subject
            Issuer = $cert.Issuer
            Thumbprint = $cert.Thumbprint
            NotAfter = $cert.NotAfter
            DaysRemaining = [math]::Floor(($cert.NotAfter - (Get-Date)).TotalDays)
            ResponseMilliseconds = [math]::Round(((Get-Date) - $started).TotalMilliseconds)
            Error = $null
        }
        $ssl.Dispose()
    } catch {
        [pscustomobject]@{
            HostName = $target; Port = $Port; Reachable = $false; Protocol = $null
            Subject = $null; Issuer = $null; Thumbprint = $null; NotAfter = $null
            DaysRemaining = $null
            ResponseMilliseconds = [math]::Round(((Get-Date) - $started).TotalMilliseconds)
            Error = $_.Exception.GetBaseException().Message
        }
    } finally {
        $tcp.Dispose()
    }
}
