# Changelog

## 1.4.0 — 2026-09-20

### Added
- `Get-SchunkFirewallAudit` for firewall profile posture and enabled-rule review.
- `Get-SchunkRdpHealth` for RDP enablement, NLA, listener, service, port, and firewall evidence.
- `Get-SchunkDfsNamespaceHealth` for DFS Namespace root, folder, target, and service state.
- `Get-SchunkCertificateInventory` for local-machine certificate lifecycle inventory.
- `Get-SchunkPrivilegedGroupAudit` for recursive review of well-known privileged AD groups.
- `Get-SchunkIisLogSummary` for recent IIS W3C request and status-code summaries.
- `Get-SchunkSqlServerHealth` for local SQL instance, service, and TCP listener health.
- `Get-SchunkWindowsBackupHealth` for Windows Server Backup service, status, versions, and task evidence.

### Changed
- Module version raised to 1.4.0.
- Public command count increased from 36 to 44.
- Safety tests expanded to reject firewall, DFS, and privileged-group state-changing commands from the diagnostic set.


## 1.3.0 — 2026-09-20

### Added
- `Invoke-SchunkServerAudit` for coordinated Windows Server evidence collection and optional HTML reporting.
- `Get-SchunkIisHealth` for IIS sites, bindings, and application pools.
- `Get-SchunkHyperVHealth` for Hyper-V host, VM, disk, switch, integration-service, and checkpoint health.
- `Get-SchunkSmbPermissionAudit` for share permissions and NTFS ACL review.
- `Test-SchunkGpoApplication` for non-destructive GPResult evidence.
- `Get-SchunkDnsServerHealth` for DNS zones and forwarders.
- `Get-SchunkDhcpScopeHealth` for scope utilization, state, and failover relationships.
- `Get-SchunkWindowsUpdateHealth` for pending updates, update history, and reboot state.

### Changed
- Module version raised to 1.3.0.
- Public command count increased from 28 to 36.
- README and module tests updated for the Windows Server operations release.


All notable changes to the Windows IT Toolkit are recorded here.

## Unreleased

- Prepare the next PowerShell Gallery release and broaden test coverage for live directory, cluster, DHCP, and vSphere environments.

## 1.2.0 — 2026-08-31

- Expanded SchunkOps from twenty to twenty-eight public commands.
- Added `Get-SchunkAccountLockoutTrace` to correlate Security event 4740 across domain controllers and surface caller computers.
- Added `Get-SchunkKerberosSpnAudit` for read-only SPN ownership and duplicate detection.
- Added `Get-SchunkGpoChangeAudit` with recent-change review and optional SHA-256 GPO report fingerprint comparison.
- Added `Get-SchunkDhcpDnsConsistency` to compare DHCP leases with forward and reverse DNS records.
- Added `Test-SchunkCertificateChain` for local X.509 trust-chain diagnostics without modifying certificate stores.
- Added `Get-SchunkClusterHealth` for Windows Failover Cluster node, role, resource, network, CSV, and quorum health.
- Added `Get-SchunkFleetHealth` for multi-server CIM health collection without requiring SchunkOps on remote targets.
- Added `Get-SchunkVSphereInventory` for read-only PowerCLI inventory, host health, datastore capacity, and optional snapshot review.
- Added a Senior Engineer Field Guide covering account lockouts, Kerberos, GPO changes, DHCP/DNS, certificates, clustering, fleet triage, and vSphere.
- Expanded the Pester safety contract to reject state-changing administrative commands from the senior diagnostic set.

## 1.1.0 — 2026-08-31

- Expanded SchunkOps from fourteen to twenty public commands.
- Added `Get-SchunkEndpointTriage` for one-command help desk and endpoint escalation evidence.
- Added `Get-SchunkDomainTrustStatus` for read-only domain membership, secure-channel, DC discovery, and optional AD port checks.
- Added `Test-SchunkDnsClient` to query each DNS server actually configured on an endpoint.
- Added `Get-SchunkADReplicationHealth` for pipeline-friendly domain controller replication summaries.
- Added `Get-SchunkLocalAdministrator` for local and remote Administrators-group inventory.
- Added `Get-SchunkDiskPressure` with warning and critical capacity thresholds.
- Expanded Full incident bundles with domain trust and local-administrator evidence and added endpoint triage to Standard bundles.
- Added a dedicated Help Desk Field Guide with first-contact, DNS, domain trust, SMB, RDP, Windows server, and AD escalation workflows.
- Corrected SchunkOps module icon metadata and expanded Gallery discovery tags.

## 1.0.0 — 2026-08-28

- Published the initial public sysadmin field kit.
- Added the SchunkOps module with fourteen David-branded Windows operations commands.
- Added integrity-hashed Standard and Full incident evidence bundles.
- Added bundle-to-bundle manifest comparison for repeatable before/after analysis.
- Added failed-logon aggregation and Service Control Manager failure triage.
- Published a practical 15-minute Windows incident-response field workflow.
- Added a custom SchunkOps project banner.
- Added full command help, module metadata, Pester tests, and module-specific CI.
- Added a protected tag-driven release workflow for Authenticode signing and PowerShell Gallery publishing.
- Documented secure maintainer setup and the repeatable release process.
- Published the initial public sysadmin field kit spanning Windows health, identity, networking, storage, security, update, virtualization, web, printing, and evidence collectors.
- Added automated Windows parsing and PSScriptAnalyzer validation.
- Added security, contribution, support, privilege, citation, and attribution documentation.
- Established David Schunk / Everyday IT authorship and MIT licensing.
