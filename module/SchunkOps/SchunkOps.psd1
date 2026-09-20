@{
    RootModule = 'SchunkOps.psm1'
    ModuleVersion = '1.3.0'
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
        'Get-SchunkDhcpScopeHealth'
        'Get-SchunkDiskPressure'
        'Get-SchunkDnsServerHealth'
        'Get-SchunkDomainTrustStatus'
        'Get-SchunkEndpointTriage'
        'Get-SchunkEventTriage'
        'Get-SchunkFleetHealth'
        'Get-SchunkGpoChangeAudit'
        'Get-SchunkHyperVHealth'
        'Get-SchunkIisHealth'
        'Get-SchunkInstalledSoftware'
        'Get-SchunkKerberosSpnAudit'
        'Get-SchunkListeningPort'
        'Get-SchunkLocalAdministrator'
        'Get-SchunkLogonFailure'
        'Get-SchunkPendingReboot'
        'Get-SchunkScheduledTaskAudit'
        'Get-SchunkSmbPermissionAudit'
        'Get-SchunkServerHealth'
        'Get-SchunkServiceFailure'
        'Get-SchunkVSphereInventory'
        'Get-SchunkWindowsUpdateHealth'
        'Get-SchunkWindowsUpdateHistory'
        'Invoke-SchunkServerAudit'
        'New-SchunkIncidentBundle'
        'Test-SchunkCertificateChain'
        'Test-SchunkDnsClient'
        'Test-SchunkGpoApplication'
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
            ReleaseNotes = 'SchunkOps 1.3 adds a coordinated Windows Server audit plus IIS, Hyper-V, SMB/NTFS permission, GPO application, DNS Server, DHCP scope, and Windows Update health diagnostics.'
        }
    }
}
