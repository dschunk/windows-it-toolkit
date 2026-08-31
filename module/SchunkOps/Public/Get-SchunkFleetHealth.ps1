function Get-SchunkFleetHealth {
    <#
    .SYNOPSIS
    Collects a compact health snapshot from multiple Windows computers.

    .DESCRIPTION
    Uses CIM to gather operating system, memory, fixed-disk, and automatic-service
    health from a list of computers. Each target returns one row, including failed
    connection details, so fleet triage can be filtered, exported, or compared
    without requiring SchunkOps to be installed on the remote computer.

    The command is read-only and does not restart services or alter remote systems.

    .PARAMETER ComputerName
    One or more Windows computers to query.

    .PARAMETER DiskWarningFreePercent
    Marks DiskPressure when the least-free fixed disk falls below this percentage.
    Defaults to 15.

    .EXAMPLE
    Get-SchunkFleetHealth -ComputerName server01,server02,server03

    .EXAMPLE
    Get-SchunkFleetHealth -ComputerName (Get-Content .\servers.txt) |
        Where-Object { -not $_.Healthy }

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    Remote CIM access requires network connectivity and appropriate management rights.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [ValidateRange(1, 99)]
        [int]$DiskWarningFreePercent = 15
    )

    foreach ($computer in $ComputerName) {
        if ([string]::IsNullOrWhiteSpace($computer)) { continue }

        $session = $null
        try {
            $session = New-CimSession -ComputerName $computer -ErrorAction Stop
            $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem -ErrorAction Stop
            $disks = @(Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop)
            $services = @(Get-CimInstance -CimSession $session -ClassName Win32_Service -Filter "StartMode = 'Auto'" -ErrorAction Stop)

            $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            $freeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            $memoryUsedPercent = if ($totalMemoryGB -gt 0) {
                [math]::Round((($totalMemoryGB - $freeMemoryGB) / $totalMemoryGB) * 100, 1)
            }
            else { $null }

            $diskRows = @($disks | ForEach-Object {
                $freePercent = if ($_.Size -gt 0) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } else { $null }
                [pscustomobject]@{
                    Drive = $_.DeviceID
                    SizeGB = [math]::Round($_.Size / 1GB, 1)
                    FreeGB = [math]::Round($_.FreeSpace / 1GB, 1)
                    FreePercent = $freePercent
                }
            })
            $validFree = @($diskRows | Where-Object { $null -ne $_.FreePercent } | Select-Object -ExpandProperty FreePercent)
            $minFree = if ($validFree.Count -gt 0) { ($validFree | Measure-Object -Minimum).Minimum } else { $null }
            $stoppedAutomatic = @($services | Where-Object { [string]$_.State -ne 'Running' } | Select-Object Name,DisplayName,State,StartMode)
            $diskPressure = [bool]($null -ne $minFree -and $minFree -lt $DiskWarningFreePercent)
            $healthy = -not $diskPressure -and $stoppedAutomatic.Count -eq 0

            [pscustomobject]@{
                ComputerName = $computer
                QueryStatus = 'Success'
                Healthy = $healthy
                OSVersion = $os.Version
                OSCaption = $os.Caption
                LastBootUpTime = $os.LastBootUpTime
                UptimeDays = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 2)
                MemoryUsedPercent = $memoryUsedPercent
                DiskWarningFreePercent = $DiskWarningFreePercent
                MinDiskFreePercent = $minFree
                DiskPressure = $diskPressure
                Disks = $diskRows
                StoppedAutomaticServiceCount = $stoppedAutomatic.Count
                StoppedAutomaticServices = $stoppedAutomatic
                Error = $null
            }
        }
        catch {
            [pscustomobject]@{
                ComputerName = $computer
                QueryStatus = 'Failed'
                Healthy = $false
                OSVersion = $null
                OSCaption = $null
                LastBootUpTime = $null
                UptimeDays = $null
                MemoryUsedPercent = $null
                DiskWarningFreePercent = $DiskWarningFreePercent
                MinDiskFreePercent = $null
                DiskPressure = $null
                Disks = @()
                StoppedAutomaticServiceCount = $null
                StoppedAutomaticServices = @()
                Error = $_.Exception.GetBaseException().Message
            }
        }
        finally {
            if ($session) { Remove-CimSession -CimSession $session -ErrorAction SilentlyContinue }
        }
    }
}
