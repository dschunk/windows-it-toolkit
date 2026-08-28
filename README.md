# Windows IT Toolkit

Practical PowerShell tools for everyday infrastructure work: server health, network diagnostics, certificate inspection, and storage triage.

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
~~~

## Quality gates

[![Validate PowerShell](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml/badge.svg)](https://github.com/dschunk/windows-it-toolkit/actions/workflows/validate-powershell.yml)

Every push and pull request is parsed on a Windows runner and checked with PSScriptAnalyzer error rules.

The scripts use safe defaults, contain no credentials or environment-specific addresses, and return objects wherever practical. Review and test every script before production use.

Issues and pull requests are welcome. Never include real credentials, tokens, private hostnames, or proprietary data in examples.
