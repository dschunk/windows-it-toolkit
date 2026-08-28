function Get-SchunkWindowsUpdateHistory {
    <#
    .SYNOPSIS
    Reads Windows Update installation and removal history.

    .PARAMETER Newest
    Maximum number of recent history entries to return.

    .EXAMPLE
    Get-SchunkWindowsUpdateHistory -Newest 50

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding()]
    param(
        [ValidateRange(1, 5000)]
        [int]$Newest = 100
    )

    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $count = $searcher.GetTotalHistoryCount()
    $take = [math]::Min($Newest, $count)

    $searcher.QueryHistory(0, $take) |
        ForEach-Object {
            [pscustomobject]@{
                Date = $_.Date
                Title = $_.Title
                Description = $_.Description
                Operation = if ($_.Operation -eq 1) {
                    'Installation'
                }
                elseif ($_.Operation -eq 2) {
                    'Uninstallation'
                }
                else {
                    $_.Operation
                }
                Result = if ($_.ResultCode -eq 2) {
                    'Succeeded'
                }
                elseif ($_.ResultCode -eq 3) {
                    'SucceededWithErrors'
                }
                elseif ($_.ResultCode -eq 4) {
                    'Failed'
                }
                elseif ($_.ResultCode -eq 5) {
                    'Aborted'
                }
                else {
                    $_.ResultCode
                }
                HResult = '0x{0:X8}' -f ($_.HResult -band 0xffffffffL)
                ClientApplicationId = $_.ClientApplicationId
            }
        } |
        Sort-Object Date -Descending
}
