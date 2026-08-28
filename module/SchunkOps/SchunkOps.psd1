@{
    RootModule = 'SchunkOps.psm1'
    ModuleVersion = '1.0.0'
    GUID = '760fe055-3c9b-46e9-92ee-fd8211474c10'
    Author = 'David Maksim Schunk'
    CompanyName = 'David Schunk / Everyday IT'
    Copyright = '(c) 2026 David Maksim Schunk. MIT License.'
    Description = 'Practical Windows infrastructure diagnostics and inventory commands by David Schunk.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Compare-SchunkIncidentBundle'
        'Get-SchunkBitLockerInventory'
        'Get-SchunkEventTriage'
        'Get-SchunkInstalledSoftware'
        'Get-SchunkListeningPort'
        'Get-SchunkLogonFailure'
        'Get-SchunkPendingReboot'
        'Get-SchunkScheduledTaskAudit'
        'Get-SchunkServerHealth'
        'Get-SchunkServiceFailure'
        'Get-SchunkWindowsUpdateHistory'
        'New-SchunkIncidentBundle'
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
                'Infrastructure'
                'Diagnostics'
                'Automation'
                'ITOperations'
            )
            LicenseUri = 'https://github.com/dschunk/windows-it-toolkit/blob/main/LICENSE'
            ProjectUri = 'https://github.com/dschunk/windows-it-toolkit'
            IconUri = 'https://avatars.githubusercontent.com/u/18497813'
            ReleaseNotes = 'First public SchunkOps release with fourteen Windows operations and incident-response commands.'
        }
    }
}
