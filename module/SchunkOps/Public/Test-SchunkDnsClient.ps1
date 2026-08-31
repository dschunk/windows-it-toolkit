function Test-SchunkDnsClient {
    <#
    .SYNOPSIS
    Tests a DNS name against the DNS servers configured on the local Windows computer.

    .DESCRIPTION
    Enumerates DNS servers configured on active IP-enabled adapters and queries each unique
    server for the requested name. The result includes success, response time, record types,
    returned addresses or names, and the error message when a query fails.

    This is intended for cases where one endpoint resolves a name differently from another,
    a mapped drive fails by hostname but works by IP, or an application appears to be using
    the wrong DNS path.

    .PARAMETER Name
    DNS name to resolve. This parameter is mandatory so the command never generates an
    unexpected external query by default.

    .PARAMETER Type
    DNS record type to request.

    .EXAMPLE
    Test-SchunkDnsClient -Name fileserver.contoso.com

    .EXAMPLE
    Test-SchunkDnsClient -Name contoso.com -Type SRV

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet('A', 'AAAA', 'CNAME', 'MX', 'NS', 'PTR', 'SOA', 'SRV', 'TXT')]
        [string]$Type = 'A'
    )

    if (-not (Get-Command Resolve-DnsName -ErrorAction SilentlyContinue)) {
        throw 'Resolve-DnsName is not available on this computer.'
    }

    $adapters = @(Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter 'IPEnabled = TRUE' -ErrorAction Stop)
    $servers = @($adapters.DNSServerSearchOrder | Where-Object { $_ } | Sort-Object -Unique)

    if ($servers.Count -eq 0) {
        [pscustomobject]@{
            ComputerName = $env:COMPUTERNAME
            Name = $Name
            Type = $Type
            DnsServer = $null
            Success = $false
            ResponseMilliseconds = $null
            Answers = @()
            Error = 'No DNS servers were found on active IP-enabled adapters.'
        }
        return
    }

    foreach ($server in $servers) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $success = $false
        $answers = @()
        $errorMessage = $null

        try {
            $response = @(Resolve-DnsName -Name $Name -Type $Type -Server $server -DnsOnly -ErrorAction Stop)
            $success = $true
            $answers = @($response | ForEach-Object {
                $value = $null
                foreach ($propertyName in @('IPAddress', 'NameHost', 'NameExchange', 'NameTarget', 'Strings')) {
                    $property = $_.PSObject.Properties[$propertyName]
                    if ($property -and $null -ne $property.Value) {
                        $value = $property.Value
                        break
                    }
                }

                [pscustomobject]@{
                    Name = $_.Name
                    QueryType = $_.QueryType
                    TTL = $_.TTL
                    Value = $value
                }
            })
        }
        catch {
            $errorMessage = $_.Exception.GetBaseException().Message
        }
        finally {
            $stopwatch.Stop()
        }

        [pscustomobject]@{
            ComputerName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
            CollectedAt = Get-Date
            Name = $Name
            Type = $Type
            DnsServer = $server
            Success = $success
            ResponseMilliseconds = [math]::Round($stopwatch.Elapsed.TotalMilliseconds, 1)
            Answers = $answers
            Error = $errorMessage
        }
    }
}
