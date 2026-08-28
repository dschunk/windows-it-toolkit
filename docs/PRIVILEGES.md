# Requirements and privilege guide

Most tools are read-only, but Windows may require elevation or an installed management module to expose the requested data.

| Area | Typical requirement |
|---|---|
| Local health, ports, profiles, tasks, firewall, updates | Local administrator recommended for complete results |
| Active Directory users and computers | RSAT ActiveDirectory module and delegated directory read access |
| Domain-controller replication | RSAT ActiveDirectory module and permission to query replication metadata |
| Group Policy | RSAT GroupPolicy module and domain read access |
| DNS Server | RSAT DnsServer module and permission to query the target DNS server |
| DHCP Server | RSAT DhcpServer module and permission to query the target DHCP server |
| BitLocker | BitLocker module and elevation for full protector information |
| SMB share configuration | SMB cmdlets and local or delegated server access |
| Remote local administrators | PowerShell remoting, firewall access, and delegated administrative rights |

## Safety expectations

- Read each script before execution.
- Use a non-production system for initial validation.
- Prefer delegated read-only roles over Domain Admin or local Administrator.
- Never export sensitive directory, firewall, share, or BitLocker data to an unprotected location.
- Treat operations snapshots as sensitive administrative evidence.
