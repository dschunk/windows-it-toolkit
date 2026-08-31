<p align="center">
  <img src="assets/schunkops-banner.svg" alt="SchunkOps by David Schunk — Windows operations built for the next engineer" width="100%" />
</p>

# Windows IT Toolkit — by David Schunk

> **Personal project notice:** This repository is independently maintained in a personal/open-source capacity and is not affiliated with, sponsored by, or endorsed by any current or former employer. It is intended to contain only generic, reusable administration tooling and examples. Do not contribute employer confidential or proprietary information, non-public internal configurations, customer data, credentials, employer source code, or employer work product.

[![Author](https://img.shields.io/badge/Author-David%20Schunk-0B1F3A?style=for-the-badge)](https://github.com/dschunk)
[![License: MIT](https://img.shields.io/badge/License-MIT-C9A227?style=for-the-badge)](LICENSE)
[![Validate PowerShell](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml/badge.svg)](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml)
[![Validate SchunkOps](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-module.yml/badge.svg)](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-module.yml)

**A practical IT operations center for help desk technicians, Windows sysadmins, Active Directory engineers, infrastructure teams, and incident responders.**

The goal is simple: turn common operational questions into safe, inspectable PowerShell objects that can be read by a technician, piped by an engineer, serialized by automation, and handed to the next person without a screen-sharing session.

> **Collect first. Change second. Document always.**

## Start here by role

| You are... | Start with... | Why |
|---|---|---|
| **Help desk / desktop support** | [`docs/HELPDESK.md`](docs/HELPDESK.md) | Five-minute endpoint triage, DNS, trust, SMB, RDP, admin checks, escalation evidence |
| **Windows sysadmin** | `Get-SchunkEndpointTriage` + `Get-SchunkFleetHealth` | Fast local triage plus multi-server health collection |
| **AD / identity engineer** | `Get-SchunkADReplicationHealth` + `Get-SchunkAccountLockoutTrace` | Replication, trust, lockouts, SPNs, stale objects, GPO context |
| **Senior infrastructure engineer** | [`docs/SENIOR-ENGINEER.md`](docs/SENIOR-ENGINEER.md) | Kerberos, GPO fingerprinting, DHCP/DNS, certificates, clusters, fleet, vSphere |
| **Server engineer** | `Get-SchunkServerHealth` + `New-SchunkIncidentBundle` | Repeatable server evidence instead of screenshots |
| **Security / incident response** | [`docs/INCIDENT-RESPONSE.md`](docs/INCIDENT-RESPONSE.md) | Structured evidence with timestamps and SHA-256 hashes |
| **Automation engineer** | `Import-Module SchunkOps` | Twenty-eight object-producing commands designed for pipelines and runbooks |

## Five-minute help desk triage

```powershell
Get-SchunkEndpointTriage
```

That one command collects uptime, memory pressure, fixed disks, active IP/DNS/gateway/DHCP configuration, domain membership, machine secure-channel state, pending reboot indicators, Windows Time source, stopped automatic services, and recent System/Application critical and error counts.

Attach it to a ticket instead of sending screenshots:

```powershell
Get-SchunkEndpointTriage |
    ConvertTo-Json -Depth 6 |
    Set-Content .\endpoint-triage.json
```

Then follow the complete [Help Desk Field Guide](docs/HELPDESK.md).

## Senior-engineer diagnostics

SchunkOps 1.2 adds the problems that usually appear after first-line troubleshooting has run out of road.

### Account keeps locking out

```powershell
Get-SchunkAccountLockoutTrace -Identity jsmith -LookbackHours 24 |
    Sort-Object TimeCreatedUtc -Descending
```

The output shows which DC recorded event 4740 and which caller computer was reported as the lockout source.

### Kerberos / duplicate SPN

```powershell
Get-SchunkKerberosSpnAudit -Identity svc_web
Get-SchunkKerberosSpnAudit -ServicePrincipalName 'HTTP/app01.contoso.com'
```

Duplicate ownership is surfaced directly instead of making the operator interpret `setspn` output manually.

### What changed in Group Policy?

```powershell
Get-SchunkGpoChangeAudit -SinceDays 14
```

Create a fingerprint baseline:

```powershell
Get-SchunkGpoChangeAudit -SinceDays 3650 -IncludeFingerprint |
    ConvertTo-Json -Depth 5 |
    Set-Content .\gpo-baseline.json
```

Compare later:

```powershell
Get-SchunkGpoChangeAudit -SinceDays 90 -BaselinePath .\gpo-baseline.json |
    Where-Object ChangeState -in 'Changed','New'
```

### DHCP lease exists but DNS is stale

```powershell
Get-SchunkDhcpDnsConsistency -DhcpServer dhcp01 -ScopeId 10.20.30.0 |
    Where-Object Status -ne 'Consistent'
```

### Certificate trust chain

```powershell
Test-SchunkCertificateChain -Path .\server.cer
```

### Failover cluster

```powershell
Get-SchunkClusterHealth -Cluster sqlcluster01 | Format-List
```

### Fleet health

```powershell
Get-SchunkFleetHealth -ComputerName (Get-Content .\servers.txt) |
    Where-Object { -not $_.Healthy }
```

### vSphere inventory

```powershell
Connect-VIServer vcsa01.contoso.com
Get-SchunkVSphereInventory -IncludeSnapshots -SnapshotAgeDays 7
```

SchunkOps never accepts vCenter credentials or connects on the operator's behalf. It uses the PowerCLI session you already established.

Read the complete [Senior Engineer Field Guide](docs/SENIOR-ENGINEER.md).

## Incident evidence

When a Windows server is failing and the handoff needs evidence instead of screenshots:

```powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042 -Profile Full
```

The bundle contains separate JSON evidence files, per-collector status, record counts, timestamps, and SHA-256 integrity hashes. Standard bundles include endpoint triage, server health, reboot state, listening ports, event triage, and service failures. Full bundles add trust state, local administrators, installed software, updates, scheduled tasks, failed logons, and BitLocker inventory.

Capture again after remediation and compare:

```powershell
Compare-SchunkIncidentBundle `
    -ReferencePath C:\IR\INC-0042 `
    -DifferencePath C:\IR\INC-0042-After
```

Follow the [15-minute Windows incident triage](docs/INCIDENT-RESPONSE.md).

## SchunkOps PowerShell module

Version **1.2.0** exports **28** public commands spanning help desk, Windows Server, Active Directory, Kerberos, Group Policy, DHCP/DNS, certificates, failover clustering, fleet operations, VMware vSphere, and incident response.

Until the Gallery release is published:

```powershell
git clone https://github.com/dschunk/windows-it-toolkit.git
Import-Module .\windows-it-toolkit\module\SchunkOps\SchunkOps.psd1
Get-Command -Module SchunkOps
```

Once published:

```powershell
Install-Module SchunkOps -Scope CurrentUser
Import-Module SchunkOps
```

### Command catalog

| Command | Operational use |
|---|---|
| **Get-SchunkEndpointTriage** | One-command first look for help desk and endpoint/server escalation |
| **Get-SchunkFleetHealth** | Multi-server CIM health without installing SchunkOps remotely |
| **Get-SchunkAccountLockoutTrace** | Correlate account lockout event 4740 across domain controllers |
| **Get-SchunkKerberosSpnAudit** | Audit SPN ownership and detect duplicate Kerberos registrations |
| **Get-SchunkADReplicationHealth** | Summarize DC replication failures, partners, and replication age |
| **Get-SchunkDomainTrustStatus** | Domain membership, secure channel, DC discovery, optional AD port checks |
| **Test-SchunkDnsClient** | Query every DNS server configured on the endpoint and compare results |
| **Get-SchunkGpoChangeAudit** | Recent GPO changes plus optional SHA-256 report fingerprint comparison |
| **Get-SchunkDhcpDnsConsistency** | Compare DHCP leases with A and PTR DNS answers |
| **Test-SchunkCertificateChain** | Validate local X.509 trust chain without changing certificate stores |
| **Get-SchunkClusterHealth** | Failover Cluster nodes, roles, resources, networks, CSVs, and quorum |
| **Get-SchunkVSphereInventory** | Read-only PowerCLI vSphere inventory and health summary |
| **Get-SchunkLocalAdministrator** | Inventory local Administrators membership locally or remotely |
| **Get-SchunkDiskPressure** | Flag fixed disks by warning and critical free-space thresholds |
| **New-SchunkIncidentBundle** | Coordinated JSON evidence collection with SHA-256 integrity hashes |
| **Compare-SchunkIncidentBundle** | Compare two bundle manifests and identify changed evidence sets |
| **Get-SchunkLogonFailure** | Group failed authentications by identity, source, event, and reason |
| **Get-SchunkServiceFailure** | Find stopped automatic services and recent SCM failures |
| `Get-SchunkServerHealth` | Uptime, CPU, memory, disks, services, and recent system errors |
| `Test-SchunkNetworkPath` | DNS, ICMP, TCP reachability, and latency |
| `Test-SchunkTlsEndpoint` | TLS protocol, certificate identity, expiry, and response time |
| `Get-SchunkPendingReboot` | Evidence from Windows reboot indicators |
| `Get-SchunkListeningPort` | TCP/UDP listeners mapped to owning processes |
| `Get-SchunkEventTriage` | Grouped Windows warnings and errors |
| `Get-SchunkInstalledSoftware` | Side-effect-free 32/64-bit software inventory |
| `Get-SchunkWindowsUpdateHistory` | Windows Update installation and removal history |
| `Get-SchunkScheduledTaskAudit` | Task identity, elevation, actions, and results |
| `Get-SchunkBitLockerInventory` | Encryption, protection, and recovery-key presence |

Every command includes discoverable help:

```powershell
Get-Help about_SchunkOps
Get-Help Get-SchunkAccountLockoutTrace -Full
Get-Help Get-SchunkKerberosSpnAudit -Full
Get-Help Get-SchunkFleetHealth -Full
```

## Standalone field tools

The repository also contains **35 standalone `.ps1` tools** for technicians who want one script without importing a module.

| Script | Purpose |
|---|---|
| Get-ServerHealth.ps1 | CPU, memory, disk, uptime, critical services, and recent system errors |
| Test-NetworkPath.ps1 | DNS, ICMP, TCP-port, and latency diagnostics |
| Get-CertificateExpiry.ps1 | Certificates approaching expiration |
| Find-LargeFiles.ps1 | Largest files beneath a path without modifying anything |
| Get-EventTriage.ps1 | Group recent warnings and errors into an actionable event summary |
| Get-SystemInventory.ps1 | Collect portable system, network, hotfix, and hardware inventory |
| Test-DnsResolution.ps1 | Compare DNS resolution, answers, failures, and response times |
| Test-TlsEndpoint.ps1 | Inspect TLS protocol, certificate identity, expiration, and response time |
| Get-PendingReboot.ps1 | Explain which Windows subsystem is requesting a restart |
| Get-ListeningPortReport.ps1 | Map listening TCP/UDP ports to processes and executable paths |
| Get-NtfsPermissionAudit.ps1 | Audit explicit and inherited NTFS access rules beneath a path |
| Test-ActiveDirectoryHealth.ps1 | Check domain controllers, LDAP reachability, sites, and replication freshness |
| Get-GroupPolicyInventory.ps1 | Inventory GPO ownership, status, versions, WMI filters, and modification dates |
| Get-LocalAdministrator.ps1 | Enumerate local Administrators membership locally or through PowerShell remoting |
| Get-InstalledSoftware.ps1 | Inventory 32-bit and 64-bit installed software without Win32_Product side effects |
| Test-SmbShareAccess.ps1 | Measure UNC read access and perform an optional reversible write probe |
| Get-ADUserLifecycleAudit.ps1 | Find inactive enabled users, old passwords, expired passwords, and non-expiring credentials |
| Get-StaleADComputer.ps1 | Identify inactive Active Directory computer objects with OS and logon context |
| Test-DomainControllerPorts.ps1 | Validate DNS, Kerberos, RPC, LDAP, SMB, LDAPS, and Global Catalog reachability |
| Get-DhcpScopeUtilization.ps1 | Report scope capacity, leases, reservations, and utilization percentages |
| Get-DnsZoneInventory.ps1 | Inventory DNS zones, update modes, replication scopes, and directory integration |
| Get-ScheduledTaskAudit.ps1 | Review task identity, elevation, actions, results, missed runs, and schedules |
| Get-WindowsUpdateHistory.ps1 | Read Windows Update installation history without scraping Event Viewer |
| Get-FirewallExposure.ps1 | Flatten effective firewall rules with ports, addresses, profiles, and programs |
| Get-BitLockerInventory.ps1 | Report encryption, protection, lock state, methods, and key-protector presence |
| Get-SmbShareInventory.ps1 | Inventory SMB configuration, encryption, caching, and share permissions |
| Get-UserProfileAudit.ps1 | Find large, old, loaded, and inactive local profiles |
| Test-TimeSynchronization.ps1 | Measure Windows time offsets against one or more systems |
| New-WindowsOpsSnapshot.ps1 | Run coordinated collectors and export a timestamped JSON evidence bundle |
| Get-IISSiteInventory.ps1 | Inventory IIS sites, bindings, application pools, paths, runtime state, and logging |
| Get-HyperVInventory.ps1 | Report Hyper-V VM state, resources, checkpoints, disks, networking, and lifecycle actions |
| Get-PrintServerInventory.ps1 | Inventory printers, drivers, ports, sharing, publication, queues, and configuration |
| Test-RdpReadiness.ps1 | Validate RDP enablement, NLA, service state, firewall rules, port, and listener |
| Get-EventLogConfiguration.ps1 | Review event-log enablement, retention mode, capacity, records, and file locations |
| Get-EnvironmentPathAudit.ps1 | Detect missing, duplicate, and risky machine and user PATH entries |

Review the [requirements and privilege guide](docs/PRIVILEGES.md) before running directory, DHCP, cluster, remote-management, or vSphere collectors.

## Design principles

1. **Read-only by default.** Diagnostic tooling should not quietly become remediation tooling.
2. **Return objects, not screenshots.** People can read objects; engineers can pipe them; automation can serialize them.
3. **Collect before changing.** Evidence is easiest to understand before someone “tries a few things.”
4. **Fail visibly.** Partial collection and errors belong in the output, not hidden behind a green check.
5. **Use the operator's authentication.** SchunkOps does not accept vCenter credentials or invent privileged sessions.
6. **Build for handoff.** The next engineer should understand what was checked and what was not changed.
7. **No phone-home telemetry.** The toolkit does not upload usage or operational data.

## Quality gates

Every push and pull request is parsed on a Windows runner and checked with PSScriptAnalyzer error rules. SchunkOps validates its manifest, imports the module, compares declared and actual exports, checks command help/attribution, and runs Pester tests. The 1.2 safety contract also statically rejects known state-changing AD, GPO, DHCP/DNS, cluster, and vSphere commands from the senior diagnostic set.

## Authorship and credit

Created and maintained by **David Maksim Schunk**. See [AUTHORS.md](AUTHORS.md), [CITATION.cff](CITATION.cff), and the [attribution guide](docs/ATTRIBUTION.md).

The MIT License permits broad personal and commercial use while requiring preservation of the copyright and license notice in copies or substantial portions. Preferred public credit:

> Based on the Windows IT Toolkit by David Schunk — https://github.com/dschunk/windows-it-toolkit

Issues and pull requests are welcome. Never include real credentials, tokens, private hostnames, proprietary data, or employer confidential/work-product material in examples.

**Collect first. Change second. Document always.**
