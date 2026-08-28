<#
.SYNOPSIS
Reports Windows event-log retention, capacity, record count, age, and enabled state.
.NOTES
Author: David Schunk
Source: https://github.com/dschunk/windows-it-toolkit
License: MIT
#>
[CmdletBinding()]
param(
    [string[]]$LogName=@('Application','Security','System','Windows PowerShell')
)

foreach($name in $LogName){
    try{
        $log=Get-WinEvent -ListLog $name -ErrorAction Stop
        [pscustomobject]@{
            LogName=$log.LogName;IsEnabled=$log.IsEnabled;RecordCount=$log.RecordCount
            FileSizeMB=[math]::Round($log.FileSize/1MB,2);MaximumSizeMB=[math]::Round($log.MaximumSizeInBytes/1MB,2)
            LogMode=$log.LogMode;LogType=$log.LogType;LastWriteTime=$log.LastWriteTime
            OldestRecordNumber=$log.OldestRecordNumber;ProviderCount=@($log.ProviderNames).Count
            LogFilePath=$log.LogFilePath
        }
    }catch{Write-Warning "Unable to inspect ${name}: $($_.Exception.Message)"}
}
