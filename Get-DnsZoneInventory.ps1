[CmdletBinding()]
param([string]$ComputerName=$env:COMPUTERNAME)

if(-not (Get-Module -ListAvailable DnsServer)){throw 'The DnsServer PowerShell module is required.'}
Import-Module DnsServer

Get-DnsServerZone -ComputerName $ComputerName | ForEach-Object {
    [pscustomobject]@{
        Server=$ComputerName;ZoneName=$_.ZoneName;ZoneType=$_.ZoneType
        IsDsIntegrated=$_.IsDsIntegrated;IsReverseLookupZone=$_.IsReverseLookupZone
        IsAutoCreated=$_.IsAutoCreated;IsPaused=$_.IsPaused
        DynamicUpdate=$_.DynamicUpdate;ReplicationScope=$_.ReplicationScope
        DirectoryPartitionName=$_.DirectoryPartitionName
    }
} | Sort-Object IsReverseLookupZone,ZoneName
