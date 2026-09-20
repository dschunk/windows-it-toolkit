function Get-SchunkSqlServerHealth {
    <#
    .SYNOPSIS
    Audits local Microsoft SQL Server service and listener health.

    .DESCRIPTION
    Discovers installed SQL Server Database Engine instances from the registry,
    reports SQL-related Windows service state, and maps listening TCP ports to
    SQL service process IDs. It does not connect to databases or modify SQL
    configuration.

    .EXAMPLE
    Get-SchunkSqlServerHealth

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param()

    $instancePaths = @(
        'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Microsoft SQL Server\Instance Names\SQL'
    )

    $instances = @()
    foreach ($path in $instancePaths) {
        if (Test-Path -LiteralPath $path) {
            $item = Get-ItemProperty -LiteralPath $path -ErrorAction SilentlyContinue
            if ($item) {
                foreach ($property in $item.PSObject.Properties) {
                    if ($property.Name -notlike 'PS*') {
                        $instances += [pscustomobject]@{
                            InstanceName = $property.Name
                            InstanceId   = [string]$property.Value
                            RegistryPath = $path
                        }
                    }
                }
            }
        }
    }
    $instances = @($instances | Sort-Object InstanceName -Unique)

    $services = @(Get-CimInstance Win32_Service -ErrorAction Stop | Where-Object { $_.Name -like 'MSSQL*' -or $_.Name -like 'SQLAgent*' -or $_.Name -eq 'SQLBrowser' -or $_.Name -like 'SQLWriter*' } | Select-Object Name, DisplayName, State, StartMode, StartName, ProcessId, PathName)

    $listeners = @()
    foreach ($service in ($services | Where-Object { $_.ProcessId -gt 0 })) {
        $ports = @(Get-NetTCPConnection -State Listen -OwningProcess $service.ProcessId -ErrorAction SilentlyContinue | Select-Object LocalAddress, LocalPort, OwningProcess)
        foreach ($port in $ports) {
            $listeners += [pscustomobject]@{
                ServiceName  = $service.Name
                DisplayName  = $service.DisplayName
                LocalAddress = $port.LocalAddress
                LocalPort    = $port.LocalPort
                ProcessId    = $port.OwningProcess
            }
        }
    }

    [pscustomobject]@{
        ComputerName        = $env:COMPUTERNAME
        CollectedAt         = Get-Date
        InstanceCount       = $instances.Count
        Instances           = $instances
        SqlServiceCount     = $services.Count
        StoppedAutoServices = @($services | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' })
        Services            = $services
        ListeningEndpoints  = @($listeners | Sort-Object LocalPort, ServiceName)
    }
}
