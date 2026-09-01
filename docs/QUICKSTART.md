# SchunkOps Quick Start

SchunkOps is a read-only-first Windows operations module for help desk technicians, sysadmins, Active Directory engineers, infrastructure engineers, and incident responders.

> **Collect first. Change second. Document always.**

## Install from PowerShell Gallery

```powershell
Install-Module SchunkOps -Scope CurrentUser
Import-Module SchunkOps
Get-Command -Module SchunkOps
```

If your organization requires explicit repository trust, review the registered repository before installing:

```powershell
Get-PSRepository -Name PSGallery
```

## Help desk: user says “my computer is broken”

```powershell
Get-SchunkEndpointTriage
```

This returns a structured first look at uptime, memory pressure, disks, active network configuration, DNS, gateway, DHCP, domain membership, secure channel, pending reboot, time source, stopped automatic services, and recent critical/error events.

Export it directly into a ticket or escalation packet:

```powershell
Get-SchunkEndpointTriage |
    ConvertTo-Json -Depth 6 |
    Set-Content .\endpoint-triage.json
```

## Domain trust problem

```powershell
Get-SchunkDomainTrustStatus -TestPorts
```

SchunkOps checks domain membership, the machine secure channel, DC discovery, and common AD service reachability. It does not reset the computer account or rejoin the domain.

## Works by IP, fails by name

```powershell
Test-SchunkDnsClient -Name fileserver.contoso.com
Test-SchunkNetworkPath -ComputerName fileserver.contoso.com -Port 445
```

## Fleet health

```powershell
Get-SchunkFleetHealth -ComputerName server01,server02,server03 |
    Sort-Object OverallStatus,ComputerName
```

Export a reusable report:

```powershell
Get-SchunkFleetHealth -ComputerName server01,server02,server03 |
    Export-Csv .\fleet-health.csv -NoTypeInformation
```

## Active Directory replication

```powershell
Get-SchunkADReplicationHealth |
    Format-Table DomainController,Site,Status,FailedPartnerCount,LargestReplicationAgeMinutes -AutoSize
```

## Account lockout investigation

```powershell
Get-SchunkAccountLockoutTrace -Identity jsmith -LookbackHours 24
```

Use this to correlate account-lockout events across domain controllers and surface caller computers. The command is diagnostic only; it does not unlock or modify the account.

## Kerberos / SPN review

```powershell
Get-SchunkKerberosSpnAudit -Identity svc_web
```

Use it to review SPN ownership and duplicate registrations before changing service identities.

## Group Policy change review

```powershell
Get-SchunkGpoChangeAudit -SinceDays 14 -IncludeFingerprint
```

The optional fingerprint gives you a SHA-256 representation that can be preserved and compared during later reviews.

## Certificate-chain validation

```powershell
Test-SchunkCertificateChain -Path .\server.cer
```

## Failover Cluster health

```powershell
Get-SchunkClusterHealth -Cluster sqlcluster01
```

## VMware vSphere inventory

Connect with VMware PowerCLI using your organization's approved authentication method, then run:

```powershell
Get-SchunkVSphereInventory -IncludeSnapshots
```

The command is read-only and expects an existing PowerCLI connection.

## Incident response

Create an evidence bundle before remediation:

```powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042 -Profile Full
```

Capture the machine again after the change:

```powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042-After -Profile Full
```

Compare the evidence sets:

```powershell
Compare-SchunkIncidentBundle `
    -ReferencePath C:\IR\INC-0042 `
    -DifferencePath C:\IR\INC-0042-After
```

## Discover the module

```powershell
Get-Help about_SchunkOps
Get-Help Get-SchunkEndpointTriage -Full
Get-Help Get-SchunkFleetHealth -Examples
Get-Help Get-SchunkAccountLockoutTrace -Full
```

## Operational safety

SchunkOps diagnostics are designed to collect evidence rather than silently remediate systems. Some commands require local administrator rights, RSAT modules, delegated directory access, PowerShell remoting, Failover Clustering tools, or VMware PowerCLI. Review [`PRIVILEGES.md`](PRIVILEGES.md) before production use.

Never paste credentials, tokens, private keys, internal host inventories, or sensitive incident evidence into public issues.
