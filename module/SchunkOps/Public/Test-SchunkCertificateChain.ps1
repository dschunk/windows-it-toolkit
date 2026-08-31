function Test-SchunkCertificateChain {
    <#
    .SYNOPSIS
    Validates an X.509 certificate chain using the local Windows trust stores.

    .DESCRIPTION
    Loads a certificate from a file or Windows certificate store, builds its X.509
    chain without changing trust configuration, and returns expiration, chain elements,
    and chain-status details. This is useful when an application rejects a certificate
    because an issuer, intermediate, or trust relationship is missing.

    .PARAMETER Path
    Path to a certificate file such as .cer, .crt, or .der.

    .PARAMETER Thumbprint
    Thumbprint of a certificate in the selected Windows certificate store.

    .PARAMETER StoreLocation
    CurrentUser or LocalMachine. Defaults to LocalMachine.

    .PARAMETER StoreName
    Certificate store name. Defaults to My.

    .EXAMPLE
    Test-SchunkCertificateChain -Path .\server.cer

    .EXAMPLE
    Test-SchunkCertificateChain -Thumbprint '001122AABB...' -StoreLocation LocalMachine -StoreName My

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    This command does not install, remove, or trust certificates.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory, ParameterSetName = 'Store')]
        [ValidateNotNullOrEmpty()]
        [string]$Thumbprint,

        [Parameter(ParameterSetName = 'Store')]
        [ValidateSet('CurrentUser', 'LocalMachine')]
        [string]$StoreLocation = 'LocalMachine',

        [Parameter(ParameterSetName = 'Store')]
        [ValidateNotNullOrEmpty()]
        [string]$StoreName = 'My'
    )

    if ($PSCmdlet.ParameterSetName -eq 'Path') {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Certificate file was not found: $Path"
        }
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2((Resolve-Path -LiteralPath $Path).Path)
    }
    else {
        $normalizedThumbprint = ($Thumbprint -replace '\s', '').ToUpperInvariant()
        $storePath = "Cert:\$StoreLocation\$StoreName"
        if (-not (Test-Path -LiteralPath $storePath)) {
            throw "Certificate store was not found: $storePath"
        }
        $matches = @(Get-ChildItem -LiteralPath $storePath | Where-Object { $_.Thumbprint -eq $normalizedThumbprint })
        if ($matches.Count -ne 1) {
            throw "Expected exactly one certificate with thumbprint '$normalizedThumbprint' in $storePath; found $($matches.Count)."
        }
        $certificate = $matches[0]
    }

    $chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
    try {
        $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
        $chain.ChainPolicy.VerificationFlags = [System.Security.Cryptography.X509Certificates.X509VerificationFlags]::NoFlag
        $valid = $chain.Build($certificate)

        $status = @($chain.ChainStatus | ForEach-Object {
            [pscustomobject]@{
                Status = [string]$_.Status
                Information = ([string]$_.StatusInformation).Trim()
            }
        })
        $elements = @($chain.ChainElements | ForEach-Object {
            [pscustomobject]@{
                Subject = $_.Certificate.Subject
                Issuer = $_.Certificate.Issuer
                Thumbprint = $_.Certificate.Thumbprint
                NotAfter = $_.Certificate.NotAfter
            }
        })

        [pscustomobject]@{
            Subject = $certificate.Subject
            Issuer = $certificate.Issuer
            Thumbprint = $certificate.Thumbprint
            SerialNumber = $certificate.SerialNumber
            NotBefore = $certificate.NotBefore
            NotAfter = $certificate.NotAfter
            DaysRemaining = [math]::Round(($certificate.NotAfter - (Get-Date)).TotalDays, 1)
            HasPrivateKey = $certificate.HasPrivateKey
            SelfSigned = $certificate.Subject -eq $certificate.Issuer
            ChainValid = $valid
            ChainElementCount = $chain.ChainElements.Count
            ChainStatus = $status
            ChainElements = $elements
        }
    }
    finally {
        $chain.Reset()
    }
}
