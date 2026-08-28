# Windows IT Toolkit

Practical PowerShell tools for everyday infrastructure work: server health, network diagnostics, certificate inspection, and storage triage.

| Script | Purpose |
|---|---|
| Get-ServerHealth.ps1 | CPU, memory, disk, uptime, critical services, and recent system errors |
| Test-NetworkPath.ps1 | DNS, ICMP, TCP-port, and latency diagnostics |
| Get-CertificateExpiry.ps1 | Certificates approaching expiration |
| Find-LargeFiles.ps1 | Largest files beneath a path without modifying anything |

~~~powershell
.\Get-ServerHealth.ps1
.\Test-NetworkPath.ps1 -ComputerName server01 -Ports 53,80,443,3389
.\Get-CertificateExpiry.ps1 -Days 60
.\Find-LargeFiles.ps1 -Path C:\Logs -Top 25
~~~

The scripts use safe defaults, contain no credentials or environment-specific addresses, and return objects wherever practical. Review and test every script before production use.

Issues and pull requests are welcome. Never include real credentials, tokens, private hostnames, or proprietary data in examples.
