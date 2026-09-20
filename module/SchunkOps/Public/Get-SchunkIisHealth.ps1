function Get-SchunkIisHealth {
    <#
    .SYNOPSIS
    Collects IIS site, binding, and application-pool health.

    .DESCRIPTION
    Uses the built-in WebAdministration module to return a read-only IIS health
    snapshot. No site, binding, application pool, or configuration is changed.

    .EXAMPLE
    Get-SchunkIisHealth

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param()

    if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
        throw 'The WebAdministration module is not available. Install the IIS management scripting tools on this server.'
    }

    Import-Module WebAdministration -ErrorAction Stop

    $sites = @(Get-Website | ForEach-Object {
        $site = $_
        $bindings = @(Get-WebBinding -Name $site.Name | ForEach-Object {
            [pscustomobject]@{
                Protocol           = $_.protocol
                BindingInformation = $_.bindingInformation
                SslFlags           = $_.sslFlags
            }
        })

        [pscustomobject]@{
            Name         = $site.Name
            State        = $site.State
            PhysicalPath = $site.PhysicalPath
            Id           = $site.Id
            Bindings     = $bindings
        }
    })

    $appPools = @(Get-ChildItem IIS:\AppPools | ForEach-Object {
        $state = try { (Get-WebAppPoolState -Name $_.Name -ErrorAction Stop).Value } catch { 'Unknown' }
        [pscustomobject]@{
            Name                  = $_.Name
            State                 = $state
            ManagedRuntimeVersion = $_.managedRuntimeVersion
            PipelineMode          = $_.managedPipelineMode
            AutoStart             = $_.autoStart
        }
    })

    [pscustomobject]@{
        ComputerName       = $env:COMPUTERNAME
        CollectedAt        = Get-Date
        Available          = $true
        SiteCount          = $sites.Count
        StoppedSiteCount   = @($sites | Where-Object State -ne 'Started').Count
        AppPoolCount       = $appPools.Count
        StoppedAppPoolCount= @($appPools | Where-Object State -ne 'Started').Count
        Sites              = $sites
        ApplicationPools   = $appPools
    }
}
