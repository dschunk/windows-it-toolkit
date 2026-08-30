<p align="center">
  <img src="assets/schunkops-banner.svg" alt="SchunkOps by David Schunk — Windows operations built for the next engineer" width="100%" />
</p>

# Windows IT Toolkit — by David Schunk

> **Personal project notice:** This repository is independently maintained in a personal/open-source capacity and is not affiliated with, sponsored by, or endorsed by any current or former employer. It is intended to contain only generic, reusable administration tooling and examples. Do not contribute employer confidential or proprietary information, non-public internal configurations, customer data, credentials, employer source code, or employer work product.

[![Author](https://img.shields.io/badge/Author-David%20Schunk-0B1F3A?style=for-the-badge)](https://github.com/dschunk)
[![License: MIT](https://img.shields.io/badge/License-MIT-C9A227?style=for-the-badge)](LICENSE)
[![Validate PowerShell](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml/badge.svg)](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml)
[![Validate SchunkOps](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-module.yml/badge.svg)](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-module.yml)

Practical PowerShell tools for everyday infrastructure work: server health, network diagnostics, certificate inspection, and storage triage.

## Start here: the 15-minute incident triage

When a Windows server is failing and the handoff needs evidence instead of
screenshots, SchunkOps can collect a structured bundle in one command:

~~~powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042 -Profile Full
~~~

The bundle contains separate JSON evidence files, per-collector status,
record counts, timestamps, and SHA-256 integrity hashes. Capture the system
again after remediation and compare what changed:

~~~powershell
$comparison = @{
    ReferencePath = 'C:\IR\INC-0042'
    DifferencePath = 'C:\IR\INC-0042-After'
}
Compare-SchunkIncidentBundle @comparison
~~~

Follow the complete, safety-conscious
[15-minute Windows incident triage](docs/INCIDENT-RESPONSE.md).

## SchunkOps PowerShell module

**SchunkOps** is the curated, installable module edition of this toolkit. Its
David-branded command names make the original project easy to discover when
commands appear in consoles, runbooks, screenshots, and shared automation.

The first Gallery release is prepared and awaiting maintainer signing secrets.
Until then, clone the repository and import the module directly:

~~~powershell
git clone https://github.com/dschunk/windows-it-toolkit.git
Import-Module .\windows-it-toolkit\module\SchunkOps\SchunkOps.psd1
Get-Command -Module SchunkOps
~~~

After `v1.0.0` is published to the PowerShell Gallery:

~~~powershell
Install-Module SchunkOps -Scope CurrentUser
Import-Module SchunkOps

Get-SchunkServerHealth
Test-SchunkNetworkPath -ComputerName server01 -Port 53,443,3389
Test-SchunkTlsEndpoint -HostName example.com
Get-SchunkPendingReboot
~~~

| SchunkOps command | Operational use |
|---|---|
| **New-SchunkIncidentBundle** | Coordinated JSON evidence collection with SHA-256 integrity hashes |
| **Compare-SchunkIncidentBundle** | Compare two bundle manifests and identify changed evidence sets |
| **Get-SchunkLogonFailure** | Group failed authentications by identity, source, event, and reason |
| **Get-SchunkServiceFailure** | Find stopped automatic services and recent Service Control Manager failures |
| `Get-SchunkServerHealth` | Uptime, CPU, memory, disks, services, and recent system errors |
| `Test-SchunkNetworkPath` | DNS, ICMP, TCP reachability, and latency |
| `Test-SchunkTlsEndpoint` | TLS protocol, certificate identity, expiry, and response time |
| `Get-SchunkPendingReboot` | Evidence from five Windows reboot indicators |
| `Get-SchunkListeningPort` | TCP/UDP listeners mapped to owning processes |
| `Get-SchunkEventTriage` | Grouped Windows warnings and errors |
| `Get-SchunkInstalledSoftware` | Side-effect-free 32/64-bit software inventory |
| `Get-SchunkWindowsUpdateHistory` | Update installation and removal history |
| `Get-SchunkScheduledTaskAudit` | Task identity, elevation, actions, and results |
| `Get-SchunkBitLockerInventory` | Encryption, protection, and recovery-key presence |

Every command includes discoverable help:

~~~powershell
Get-Help about_SchunkOps
Get-Help Get-SchunkServerHealth -Full
~~~

Release instructions and secret requirements are documented in
[docs/PUBLISHING.md](docs/PUBLISHING.md).

## Standalone field tools

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
| New-WindowsOpsSnapshot.ps1 | Run a coordinated set of collectors and export a timestamped JSON evidence bundle |
| Get-IISSiteInventory.ps1 | Inventory IIS sites, bindings, application pools, paths, runtime state, and logging |
| Get-HyperVInventory.ps1 | Report Hyper-V VM state, resources, checkpoints, disks, networking, and lifecycle actions |
| Get-PrintServerInventory.ps1 | Inventory printers, drivers, ports, sharing, publication, queues, and configuration |
| Test-RdpReadiness.ps1 | Validate RDP enablement, NLA, service state, firewall rules, port, and listener |
| Get-EventLogConfiguration.ps1 | Review event-log enablement, retention mode, capacity, records, and file locations |
| Get-EnvironmentPathAudit.ps1 | Detect missing, duplicate, and risky machine and user PATH entries |

~~~powershell
.\Get-ServerHealth.ps1
.\Test-NetworkPath.ps1 -ComputerName server01 -Ports 53,80,443,3389
.\Get-CertificateExpiry.ps1 -Days 60
.\Find-LargeFiles.ps1 -Path C:\Logs -Top 25
.\Get-EventTriage.ps1 -Hours 12
.\Get-SystemInventory.ps1 -OutputPath .\inventory.json
.\Test-DnsResolution.ps1 -Name example.com -Server 1.1.1.1,8.8.8.8
.\Test-TlsEndpoint.ps1 -HostName example.com
.\Get-PendingReboot.ps1
.\Get-ListeningPortReport.ps1 -Protocol TCP
.\Get-NtfsPermissionAudit.ps1 -Path D:\Shares -Depth 2
.\Test-ActiveDirectoryHealth.ps1
.\Get-GroupPolicyInventory.ps1
.\Get-LocalAdministrator.ps1 -ComputerName server01,server02
.\Get-InstalledSoftware.ps1 -Name VMware
.\Test-SmbShareAccess.ps1 -Path \\fileserver\department
.\Get-ADUserLifecycleAudit.ps1 -InactiveDays 90
.\Get-StaleADComputer.ps1 -InactiveDays 120
.\Test-DomainControllerPorts.ps1
.\Get-DhcpScopeUtilization.ps1 -ComputerName dhcp01
.\Get-DnsZoneInventory.ps1 -ComputerName dns01
.\Get-ScheduledTaskAudit.ps1
.\Get-WindowsUpdateHistory.ps1 -Newest 50
.\Get-FirewallExposure.ps1 -EnabledOnly
.\Get-BitLockerInventory.ps1
.\Get-SmbShareInventory.ps1
.\Get-UserProfileAudit.ps1 -OlderThanDays 180
.\Test-TimeSynchronization.ps1 -ComputerName dc01,dc02
.\New-WindowsOpsSnapshot.ps1 -OutputDirectory C:\Admin\Snapshots\Today
.\Get-IISSiteInventory.ps1
.\Get-HyperVInventory.ps1 -ComputerName hyperv01
.\Get-PrintServerInventory.ps1 -ComputerName print01
.\Test-RdpReadiness.ps1
.\Get-EventLogConfiguration.ps1 -LogName Application,Security,System
.\Get-EnvironmentPathAudit.ps1
~~~

Review the [requirements and privilege guide](docs/PRIVILEGES.md) before running domain, DHCP, DNS, BitLocker, firewall, or remote-management collectors.

## Quality gates

[![Validate PowerShell](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml/badge.svg)](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml)

Every push and pull request is parsed on a Windows runner and checked with
PSScriptAnalyzer error rules. SchunkOps also validates its manifest, imports
the module, compares declared and actual exports, and runs Pester tests.

## Authorship and credit

Created and maintained by **David Maksim Schunk**. See [AUTHORS.md](AUTHORS.md), [CITATION.cff](CITATION.cff), and the [attribution guide](docs/ATTRIBUTION.md).

The MIT License permits broad personal and commercial use while requiring preservation of the copyright and license notice in copies or substantial portions. Preferred public credit:

> Based on the Windows IT Toolkit by David Schunk — https://github.com/dschunk/windows-it-toolkit

The toolkit contains no usage telemetry or phone-home tracking. Adoption is
measured transparently through GitHub stars, forks, clones, issues,
contributors, releases, and PowerShell Gallery downloads.

The scripts use safe defaults, contain no credentials or environment-specific addresses, and return objects wherever practical. Review and test every script before production use.

Issues and pull requests are welcome. Never include real credentials, tokens, private hostnames, proprietary data, or employer confidential/work-product material in examples.

## Help build it

The [public roadmap](ROADMAP.md) includes fleet operations, baselines, reporting,
redaction, schemas, tests, and good first contributions. Pull requests use a
safety and quality checklist so new tools remain predictable under pressure.
