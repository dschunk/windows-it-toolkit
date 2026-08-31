# SchunkOps Help Desk Field Guide

This guide is for the first 5–15 minutes of a Windows ticket: collect evidence, narrow the failure domain, and escalate with something better than screenshots and “it still doesn’t work.”

All commands below are read-only unless the command explicitly creates an evidence folder. SchunkOps does not upload telemetry or contact a third-party service.

## Install or import

```powershell
git clone https://github.com/dschunk/windows-it-toolkit.git
Import-Module .\windows-it-toolkit\module\SchunkOps\SchunkOps.psd1
```

If SchunkOps is already installed from the PowerShell Gallery:

```powershell
Import-Module SchunkOps
```

## The one-command first look

```powershell
Get-SchunkEndpointTriage
```

This gives you one structured object containing:

- uptime and last boot
- memory pressure
- fixed-disk capacity
- active IPv4, gateway, DHCP, and DNS configuration
- domain membership and secure-channel state
- pending reboot state
- Windows Time source
- stopped automatic services
- recent System and Application critical/error counts

For a ticket attachment:

```powershell
Get-SchunkEndpointTriage |
    ConvertTo-Json -Depth 6 |
    Set-Content .\endpoint-triage.json
```

## “The computer is slow”

Start with:

```powershell
Get-SchunkEndpointTriage
Get-SchunkDiskPressure
Get-SchunkPendingReboot
Get-SchunkEventTriage -Hours 4
Get-SchunkInstalledSoftware
```

Look for:

1. memory above roughly 90 percent
2. system volume approaching the critical threshold
3. a pending reboot after patching or software deployment
4. repeating System/Application errors
5. recently installed software that lines up with when the problem began

For deeper evidence:

```powershell
New-SchunkIncidentBundle -OutputPath C:\Support\TICKET-12345 -Profile Full
```

Attach the bundle only after reviewing it for usernames, hostnames, IP addresses, software names, and other operational data.

## “I can reach it by IP but not by name”

```powershell
Test-SchunkDnsClient -Name fileserver.contoso.com
Test-SchunkNetworkPath -ComputerName fileserver.contoso.com -Port 445
```

`Test-SchunkDnsClient` queries each DNS server actually configured on the endpoint, which makes split answers and dead resolvers obvious.

Useful follow-up checks:

```powershell
ipconfig /all
Get-SchunkDomainTrustStatus
```

## “The trust relationship between this workstation and the primary domain failed”

Do **not** immediately remove the computer from the domain.

Collect first:

```powershell
Get-SchunkDomainTrustStatus
Get-SchunkDomainTrustStatus -TestPorts
Test-SchunkDnsClient -Name _ldap._tcp.dc._msdcs.contoso.com -Type SRV
```

The status command does not repair or reset anything. It reports domain membership, secure-channel state, logon server, discovered DC, and optional AD port reachability.

Escalate with the output before resetting the machine account or rejoining the domain. Those actions can hide the original cause if DNS, time, replication, or network reachability is actually broken.

## “The mapped drive / file share is broken”

```powershell
Test-SchunkNetworkPath -ComputerName fileserver.contoso.com -Port 445
Test-SchunkDnsClient -Name fileserver.contoso.com
Test-SchunkSmbShareAccess -Path \\fileserver\department
```

If the path is reachable but access fails, capture the exact identity being used and escalate the permissions question separately from the network question.

## “Why is this user an administrator?”

Local machine:

```powershell
Get-SchunkLocalAdministrator
```

Multiple endpoints:

```powershell
Get-SchunkLocalAdministrator -ComputerName PC001,PC002,SERVER01
```

This is inventory only. It does not add or remove members.

## “RDP is down”

```powershell
Test-SchunkNetworkPath -ComputerName server01 -Port 3389
.\Test-RdpReadiness.ps1
Get-SchunkServiceFailure -EventLookbackHours 8
```

Separate these questions:

- does DNS resolve?
- is the system reachable?
- is TCP/3389 reachable?
- is Remote Desktop enabled?
- is TermService healthy?
- are firewall rules active?
- is NLA configured as expected?

## “A Windows server is acting weird”

```powershell
Get-SchunkServerHealth
Get-SchunkEndpointTriage -EventLookbackHours 12
Get-SchunkListeningPort
Get-SchunkServiceFailure -EventLookbackHours 12
Get-SchunkWindowsUpdateHistory -Newest 50
```

Then create evidence:

```powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042 -Profile Full -EventLookbackHours 24
```

After remediation, collect a second bundle and compare manifests:

```powershell
Compare-SchunkIncidentBundle `
    -ReferencePath C:\IR\INC-0042 `
    -DifferencePath C:\IR\INC-0042-After
```

## Active Directory engineer quick check

Domain/member trust:

```powershell
Get-SchunkDomainTrustStatus -TestPorts
```

Replication:

```powershell
Get-SchunkADReplicationHealth
Get-SchunkADReplicationHealth -MaxReplicationAgeMinutes 30 |
    Format-Table DomainController,Site,Status,FailedPartnerCount,RecordedFailureCount,LargestReplicationAgeMinutes -AutoSize
```

Supporting checks:

```powershell
.\Test-ActiveDirectoryHealth.ps1
.\Test-DomainControllerPorts.ps1
.\Test-TimeSynchronization.ps1 -ComputerName dc01,dc02
.\Get-DnsZoneInventory.ps1 -ComputerName dns01
.\Get-DhcpScopeUtilization.ps1 -ComputerName dhcp01
```

## Before escalating a ticket

A good escalation should answer these questions:

1. **What is failing?** State the observable symptom, not a theory.
2. **When did it start?** Include the earliest known time and whether it is continuous or intermittent.
3. **Who or what is affected?** One user, one endpoint, one subnet, one server, or everyone?
4. **What still works?** IP but not DNS? HTTPS but not SMB? Local login but not domain login?
5. **What changed?** Patches, software, password, network, certificate, policy, reboot, or deployment.
6. **What evidence did you collect?** Include SchunkOps output or a reviewed incident bundle.
7. **What did you intentionally not change?** This matters during incidents.

Example escalation note:

```text
TICKET-12345
User cannot access \\FS01\Finance from PC104.
Started approximately 09:10 ET after morning login.
FS01 resolves correctly through both configured DNS servers.
TCP/445 to FS01 succeeds. Other users can access the share.
Domain secure channel is healthy. No reboot pending.
No remediation or permission changes performed.
Attached: endpoint-triage.json and Test-SchunkSmbShareAccess output.
Likely escalation domain: authorization / share or NTFS access, not connectivity.
```

## Operating principle

The goal is not to run every command. The goal is to reduce uncertainty without making the incident harder to understand.

**Collect first. Change second. Document always.**
