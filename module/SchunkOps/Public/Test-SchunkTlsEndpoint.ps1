function Test-SchunkTlsEndpoint {
    <#
    .SYNOPSIS
    Inspects TLS connectivity and the certificate presented by an endpoint.

    .DESCRIPTION
    Opens a bounded TLS connection and returns protocol, certificate identity,
    expiration, thumbprint, response time, and any connection error.

    .PARAMETER HostName
    One or more TLS host names.

    .PARAMETER Port
    TCP port used for TLS. The default is 443.

    .PARAMETER TimeoutSeconds
    Maximum time to wait for the TCP connection.

    .EXAMPLE
    Test-SchunkTlsEndpoint -HostName example.com

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$HostName,

        [ValidateRange(1, 65535)]
        [int]$Port = 443,

        [ValidateRange(1, 60)]
        [int]$TimeoutSeconds = 10
    )

    foreach ($target in $HostName) {
        $tcp = [Net.Sockets.TcpClient]::new()
        $started = Get-Date

        try {
            $connect = $tcp.ConnectAsync($target, $Port)
            if (-not $connect.Wait([TimeSpan]::FromSeconds($TimeoutSeconds))) {
                throw "Connection timed out after $TimeoutSeconds seconds"
            }

            $callback = {
                param($sender, $certificate, $chain, $errors)
                $true
            }
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
        }
        catch {
            [pscustomobject]@{
                HostName = $target
                Port = $Port
                Reachable = $false
                Protocol = $null
                Subject = $null
                Issuer = $null
                Thumbprint = $null
                NotAfter = $null
                DaysRemaining = $null
                ResponseMilliseconds = [math]::Round(((Get-Date) - $started).TotalMilliseconds)
                Error = $_.Exception.GetBaseException().Message
            }
        }
        finally {
            $tcp.Dispose()
        }
    }
}
