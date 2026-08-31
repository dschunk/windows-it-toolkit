@{
    RootModule = 'SchunkOps.psm1'
    ModuleVersion = '1.1.0'
    GUID = '760fe055-3c9b-46e9-92ee-fd8211474c10'
    Author = 'David Maksim Schunk'
    CompanyName = 'David Schunk / Everyday IT'
    Copyright = '(c) 2026 David Maksim Schunk. MIT License.'
    Description = 'Practical Windows infrastructure diagnostics, help desk triage, identity, and incident-response commands by David Schunk.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Compare-SchunkIncidentBundle'
        'Get-SchunkADReplicationHealth'
        'Get-SchunkBitLockerInventory'
        'Get-SchunkDiskPressure'
        'Get-SchunkDomainTrustStatus'
        'Get-SchunkEndpointTriage'
        'Get-SchunkEventTriage'
        'Get-SchunkInstalledSoftware'
        'Get-SchunkListeningPort'
        'Get-SchunkLocalAdministrator'
        'Get-SchunkLogonFailure'
        'Get-SchunkPendingReboot'
        'Get-SchunkScheduledTaskAudit'
        'Get-SchunkServerHealth'
        'Get-SchunkServiceFailure'
        'Get-SchunkWindowsUpdateHistory'
        'New-SchunkIncidentBundle'
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
                'Infrastructure'
                'Diagnostics'
                'Automation'
                'ITOperations'
            )
            LicenseUri = 'https://github.com/dschunk/windows-it-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/dschunk/windows-it-toolkit'
            IconUri = 'https://avatars.githubusercontent.com/u/140072881?v=4'
            ReleaseNotes = 'SchunkOps 1.1 adds endpoint triage, domain trust diagnostics, configured-DNS testing, local administrator inventory, disk pressure reporting, and Active Directory replication health.'
        }
    }
}
