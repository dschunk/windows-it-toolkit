# Changelog

All notable changes to the Windows IT Toolkit are recorded here.

## Unreleased

- Prepare the next PowerShell Gallery release and broaden test coverage for remote and directory scenarios.

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
