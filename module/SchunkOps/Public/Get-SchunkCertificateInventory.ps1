function Get-SchunkCertificateInventory {
    <#
    .SYNOPSIS
    Inventories local-machine certificates and flags upcoming expirations.

    .DESCRIPTION
    Reads certificates from selected LocalMachine certificate stores and returns
    subject, issuer, thumbprint, validity, private-key state, DNS names, Enhanced
    Key Usage, and expiration status.

    .PARAMETER StoreName
    LocalMachine certificate store names to inspect.

    .PARAMETER WarningDays
    Certificates expiring within this many days are flagged.

    .EXAMPLE
    Get-SchunkCertificateInventory

    .EXAMPLE
    Get-SchunkCertificateInventory -StoreName My,WebHosting -WarningDays 60

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [string[]]$StoreName = @('My', 'WebHosting'),

        [ValidateRange(1, 3650)]
        [int]$WarningDays = 45
    )

    $now = Get-Date
    $warningDate = $now.AddDays($WarningDays)
    $certificates = @()

    foreach ($store in $StoreName) {
        $path = "Cert:\LocalMachine\$store"
        if (-not (Test-Path -LiteralPath $path)) {
            continue
        }

        $certificates += @(Get-ChildItem -LiteralPath $path -ErrorAction SilentlyContinue | ForEach-Object {
            $dnsNames = @()
            try {
                $dnsNames = @($_.DnsNameList | ForEach-Object { $_.Unicode })
            }
            catch {
                $dnsNames = @()
            }

            $eku = @()
            try {
                $eku = @($_.EnhancedKeyUsageList | ForEach-Object { $_.FriendlyName })
            }
            catch {
                $eku = @()
            }

            [pscustomobject]@{
                StoreName        = $store
                Subject          = $_.Subject
                Issuer           = $_.Issuer
                Thumbprint       = $_.Thumbprint
                SerialNumber     = $_.SerialNumber
                NotBefore        = $_.NotBefore
                NotAfter         = $_.NotAfter
                DaysRemaining    = [math]::Floor(($_.NotAfter - $now).TotalDays)
                Expired          = ($_.NotAfter -lt $now)
                ExpiringSoon     = ($_.NotAfter -ge $now -and $_.NotAfter -le $warningDate)
                HasPrivateKey    = $_.HasPrivateKey
                DNSNames         = $dnsNames
                EnhancedKeyUsage = $eku
            }
        })
    }

    [pscustomobject]@{
        ComputerName      = $env:COMPUTERNAME
        CollectedAt       = $now
        WarningDays       = $WarningDays
        CertificateCount  = $certificates.Count
        ExpiredCount      = @($certificates | Where-Object Expired).Count
        ExpiringSoonCount = @($certificates | Where-Object ExpiringSoon).Count
        Certificates      = @($certificates | Sort-Object NotAfter)
    }
}
