@{
    RootModule = 'SchunkOps.psm1'
    ModuleVersion = '1.2.0'
    GUID = '760fe055-3c9b-46e9-92ee-fd8211474c10'
    Author = 'David Maksim Schunk'
    CompanyName = 'David Schunk / Everyday IT'
    Copyright = '(c) 2026 David Maksim Schunk. MIT License.'
    Description = 'Practical Windows and infrastructure diagnostics from help desk triage through senior engineering and incident response.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Compare-SchunkIncidentBundle'
        'Get-SchunkAccountLockoutTrace'
        'Get-SchunkADReplicationHealth'
        'Get-SchunkBitLockerInventory'
        'Get-SchunkClusterHealth'
        'Get-SchunkDhcpDnsConsistency'
        'Get-SchunkDiskPressure'
        'Get-SchunkDomainTrustStatus'
        'Get-SchunkEndpointTriage'
        'Get-SchunkEventTriage'
        'Get-SchunkFleetHealth'
        'Get-SchunkGpoChangeAudit'
        'Get-SchunkInstalledSoftware'
        'Get-SchunkKerberosSpnAudit'
        'Get-SchunkListeningPort'
        'Get-SchunkLocalAdministrator'
        'Get-SchunkLogonFailure'
        'Get-SchunkPendingReboot'
        'Get-SchunkScheduledTaskAudit'
        'Get-SchunkServerHealth'
        'Get-SchunkServiceFailure'
        'Get-SchunkVSphereInventory'
        'Get-SchunkWindowsUpdateHistory'
        'New-SchunkIncidentBundle'
        'Test-SchunkCertificateChain'
        'Test-SchunkDnsClient'
        'Test-SchunkNetworkPath'
        'Test-SchunkTlsEndpoint'
    )

    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()

    PrivateData = @{
        PSData = @{
            Tags = @(
                'Windows'
                'WindowsServer'
                'PowerShell'
                'SysAdmin'
                'HelpDesk'
                'ActiveDirectory'
                'Kerberos'
                'GroupPolicy'
                'FailoverCluster'
                'VMware'
                'Infrastructure'
                'Diagnostics'
                'Automation'
                'ITOperations'
            )
            LicenseUri = 'https://github.com/dschunk/windows-it-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/dschunk/windows-it-toolkit'
            IconUri = 'https://avatars.githubusercontent.com/u/140072881?v=4'
            ReleaseNotes = 'SchunkOps 1.2 adds account lockout tracing, Kerberos SPN auditing, GPO fingerprint/change review, DHCP-DNS consistency checks, certificate-chain validation, failover-cluster health, fleet CIM health, and VMware vSphere inventory diagnostics.'
        }
    }
}
