# Requirements and privilege guide

Most tools are read-only, but Windows and infrastructure platforms may require elevation, delegated access, or an installed management module to expose the requested data.

| Area | Typical requirement |
|---|---|
| Local health, ports, profiles, tasks, firewall, updates | Local administrator recommended for complete results |
| Active Directory users and computers | RSAT ActiveDirectory module and delegated directory read access |
| Domain-controller replication | RSAT ActiveDirectory module and permission to query replication metadata |
| Account lockout tracing | RSAT ActiveDirectory module plus remote Security-log read access on domain controllers |
| Kerberos SPN audit | RSAT ActiveDirectory module and directory read access |
| Group Policy change / fingerprint audit | RSAT GroupPolicy module and domain read access |
| DNS Server | RSAT DnsServer module and permission to query the target DNS server |
| DHCP Server | RSAT DhcpServer module and permission to query the target DHCP server |
| DHCP/DNS consistency | DHCP Server read access plus DNS resolution access |
| Certificate chain validation | Local access to the certificate file or certificate store being inspected |
| Failover Cluster health | FailoverClusters module and permission to query the target cluster |
| Fleet health | CIM / WinRM reachability and delegated management rights on each target |
| VMware vSphere inventory | VMware PowerCLI plus an existing `Connect-VIServer` session with read permissions |
| BitLocker | BitLocker module and elevation for full protector information |
| SMB share configuration | SMB cmdlets and local or delegated server access |
| Remote local administrators | PowerShell remoting, firewall access, and delegated administrative rights |

## Safety expectations

- Read each script before execution.
- Use a non-production system or lab for initial validation when practical.
- Prefer delegated read-only roles over Domain Admin, Enterprise Admin, local Administrator, or full vSphere Administrator.
- SchunkOps senior diagnostics do not unlock accounts, edit SPNs, change GPOs, alter DHCP/DNS records, trust certificates, move cluster roles, restart services, or change vSphere state.
- Never export sensitive directory, firewall, share, BitLocker, authentication, or infrastructure inventory data to an unprotected location.
- Treat account-lockout traces, GPO reports, operations snapshots, and infrastructure inventories as sensitive administrative evidence.
