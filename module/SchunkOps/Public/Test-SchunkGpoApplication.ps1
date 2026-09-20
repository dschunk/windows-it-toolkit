function Test-SchunkGpoApplication {
    <#
    .SYNOPSIS
    Captures local Group Policy resultant-set evidence using GPResult.

    .DESCRIPTION
    Runs GPResult for computer and/or user scope and returns the raw output,
    exit code, timestamp, and local identity. It does not refresh or modify policy.

    .PARAMETER Scope
    Computer, User, or Both.

    .EXAMPLE
    Test-SchunkGpoApplication

    .EXAMPLE
    Test-SchunkGpoApplication -Scope Computer

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Computer', 'User', 'Both')]
        [string]$Scope = 'Both'
    )

    $results = foreach ($targetScope in @('Computer', 'User')) {
        if ($Scope -ne 'Both' -and $Scope -ne $targetScope) {
            continue
        }

        $output = & gpresult.exe /Scope $targetScope /R 2>&1
        $exitCode = $LASTEXITCODE

        [pscustomobject]@{
            Scope    = $targetScope
            ExitCode = $exitCode
            Success  = ($exitCode -eq 0)
            Output   = @($output | ForEach-Object { $_.ToString() })
        }
    }

    [pscustomobject]@{
        ComputerName = $env:COMPUTERNAME
        UserName     = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        CollectedAt  = Get-Date
        Results      = @($results)
    }
}
