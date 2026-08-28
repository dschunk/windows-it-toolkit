<#
.SYNOPSIS
Checks whether Remote Desktop is enabled, listening, permitted by firewall, and protected by NLA.
.NOTES
Author: David Schunk
Source: https://github.com/dschunk/windows-it-toolkit
License: MIT
#>
[CmdletBinding()]
param()

$terminalServer='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
$rdpTcp='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
$deny=(Get-ItemPropertyValue -Path $terminalServer -Name fDenyTSConnections -ErrorAction SilentlyContinue)
$nla=(Get-ItemPropertyValue -Path $rdpTcp -Name UserAuthentication -ErrorAction SilentlyContinue)
$port=(Get-ItemPropertyValue -Path $rdpTcp -Name PortNumber -ErrorAction SilentlyContinue)
$service=Get-Service TermService -ErrorAction SilentlyContinue
$firewall=@(Get-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue | Where-Object {$_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' -and $_.Action -eq 'Allow'})
$listener=Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue

[pscustomobject]@{
    ComputerName=$env:COMPUTERNAME;RdpEnabled=$deny -eq 0;NetworkLevelAuthentication=$nla -eq 1
    ConfiguredPort=$port;ServiceStatus=$service.Status;EnabledFirewallRules=$firewall.Count
    PortListening=$null -ne $listener;Ready=($deny -eq 0 -and $nla -eq 1 -and $service.Status -eq 'Running' -and $firewall.Count -gt 0 -and $null -ne $listener)
    CollectedAt=Get-Date
}
