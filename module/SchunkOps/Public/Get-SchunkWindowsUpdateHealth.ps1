function Get-SchunkWindowsUpdateHealth {
    <#
    .SYNOPSIS
    Summarizes Windows Update state, recent history, and pending updates.

    .DESCRIPTION
    Uses the Windows Update Agent COM API and SchunkOps reboot detection to provide
    a read-only update-health snapshot. The search respects the computer's
    configured Windows Update or WSUS source.

    .PARAMETER HistoryCount
    Maximum number of recent update-history records to return.

    .EXAMPLE
    Get-SchunkWindowsUpdateHealth

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 200)]
        [int]$HistoryCount = 20
    )

    $pending = @()
    $history = @()
    $searchError = $null
    $historyError = $null

    try {
        $session = New-Object -ComObject Microsoft.Update.Session
        $searcher = $session.CreateUpdateSearcher()
        $result = $searcher.Search("IsInstalled=0 and IsHidden=0")
        $pending = @(for ($i = 0; $i -lt $result.Updates.Count; $i++) {
            $update = $result.Updates.Item($i)
            [pscustomobject]@{
                Title          = $update.Title
                RebootRequired = $update.RebootRequired
                MsrcSeverity   = $update.MsrcSeverity
                Categories     = @($update.Categories | ForEach-Object Name)
            }
        })
    }
    catch {
        $searchError = $_.Exception.Message
    }

    try {
        if (-not $session) {
            $session = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
        }

        $totalHistory = $searcher.GetTotalHistoryCount()
        $take = [math]::Min($HistoryCount, $totalHistory)
        if ($take -gt 0) {
            $history = @($searcher.QueryHistory(0, $take) | ForEach-Object {
                [pscustomobject]@{
                    Date       = $_.Date
                    Title      = $_.Title
                    Operation  = $_.Operation
                    ResultCode = $_.ResultCode
                    HResult    = ('0x{0:X8}' -f ($_.HResult -band 0xffffffff))
                }
            })
        }
    }
    catch {
        $historyError = $_.Exception.Message
    }

    [pscustomobject]@{
        ComputerName       = $env:COMPUTERNAME
        CollectedAt        = Get-Date
        PendingUpdateCount = $pending.Count
        PendingUpdates     = $pending
        RecentHistory      = $history
        PendingReboot      = Get-SchunkPendingReboot
        SearchError        = $searchError
        HistoryError       = $historyError
    }
}
