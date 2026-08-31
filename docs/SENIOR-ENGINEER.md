# SchunkOps Senior Engineer Field Guide

This guide is for the problems that arrive after first-line troubleshooting has already failed: repeated account lockouts, Kerberos failures, Group Policy drift, stale DHCP/DNS state, certificate trust problems, cluster instability, fleet-wide health questions, and vSphere operational review.

The operating rule remains the same:

> **Collect first. Change second. Document always.**

The commands in this guide are diagnostic and read-only. They do not reset passwords, repair secure channels, edit SPNs, modify GPOs, change DHCP/DNS records, trust certificates, move cluster roles, restart services, or alter vSphere state.

## Account keeps locking out

Start by asking every domain controller that can read the Security log where event 4740 was recorded:

```powershell
Get-SchunkAccountLockoutTrace -Identity jsmith -LookbackHours 24 |
    Sort-Object TimeCreatedUtc -Descending
```

Useful fields:

- `DomainController` — the DC that recorded the lockout
- `CallerComputerName` — the machine reported as the source
- `TargetUserName` — the account that locked
- `TimeCreatedUtc` — normalized timestamp for correlation
- `QueryStatus` / `Error` — DCs that could not be queried

Typical next step: correlate the caller computer with scheduled tasks, services, mapped drives, saved credentials, mobile clients, VPN clients, or stale application pools. Do not unlock the account repeatedly without locating the credential source.

## Kerberos works sometimes / NTLM fallback / service auth failure

Audit the SPNs on the service identity:

```powershell
Get-SchunkKerberosSpnAudit -Identity svc_web
```

Or test the exact SPN the client is expected to request:

```powershell
Get-SchunkKerberosSpnAudit -ServicePrincipalName 'HTTP/app01.contoso.com'
```

Any result with `Duplicate = True` deserves immediate review. Duplicate SPNs can cause ticket decryption failures, intermittent authentication, or fallback to NTLM depending on which principal the KDC resolves.

Pair this with DNS and time checks:

```powershell
Test-SchunkDnsClient -Name app01.contoso.com
Test-SchunkNetworkPath -ComputerName app01.contoso.com -Port 88,389,445
Get-SchunkDomainTrustStatus -TestPorts
```

## What changed in Group Policy?

Find recently modified policies:

```powershell
Get-SchunkGpoChangeAudit -SinceDays 14
```

Create fingerprints you can store as a baseline:

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

The fingerprint is SHA-256 over the XML GPO report. It is intended to answer “is this report materially different from the baseline?” without changing policy state.

## DHCP lease exists but DNS is wrong

```powershell
Get-SchunkDhcpDnsConsistency -DhcpServer dhcp01 -ScopeId 10.20.30.0 |
    Where-Object Status -ne 'Consistent'
```

The command compares:

- lease hostname → A record(s)
- lease IP → PTR record(s)
- A record answer → leased IP
- PTR target → lease hostname

Statuses distinguish forward-only, reverse-only, dual mismatches, and leases without a hostname. This is useful before deleting records, changing scavenging, or blaming the client.

## Certificate looks fine but the app rejects it

Validate a file:

```powershell
Test-SchunkCertificateChain -Path .\server.cer
```

Or a certificate in the Windows store:

```powershell
Test-SchunkCertificateChain `
    -Thumbprint '001122AABBCCDDEEFF...' `
    -StoreLocation LocalMachine `
    -StoreName My
```

Review `ChainValid`, `ChainStatus`, `ChainElements`, issuer, expiration, and private-key presence. The command uses the local Windows trust stores and does not install or trust anything.

For a live TLS endpoint, pair it with:

```powershell
Test-SchunkTlsEndpoint -HostName app01.contoso.com
```

## Failover cluster is degraded

```powershell
Get-SchunkClusterHealth -Cluster sqlcluster01 | Format-List
```

The summary separates problems into:

- nodes
- clustered groups / roles
- resources
- cluster networks
- Cluster Shared Volumes
- quorum context

The `Healthy` field is intentionally simple; the problem collections contain the evidence needed for deeper review.

## Which servers are actually unhealthy?

```powershell
Get-SchunkFleetHealth -ComputerName (Get-Content .\servers.txt) |
    Where-Object { -not $_.Healthy } |
    Export-Csv .\fleet-health.csv -NoTypeInformation
```

The command does not require SchunkOps to be installed remotely. It uses CIM to collect:

- OS and uptime
- memory pressure
- fixed-disk free space
- stopped automatic services
- per-target connection failures

Use this to narrow a 100-server question into a 5-server investigation before opening individual consoles.

## vSphere morning check

Use your normal PowerCLI authentication first:

```powershell
Connect-VIServer vcsa01.contoso.com
Get-SchunkVSphereInventory
```

Include snapshot review when needed:

```powershell
Get-SchunkVSphereInventory -IncludeSnapshots -SnapshotAgeDays 7
```

The inventory highlights disconnected/powered-off hosts, low-free-space datastores, VM power counts, cluster counts, and optionally old snapshots. SchunkOps never accepts vCenter credentials or establishes a connection on your behalf.

## Suggested escalation packet

When handing a problem to another engineer, attach the evidence rather than summarizing from memory:

```powershell
$case = 'INC-0042'

Get-SchunkFleetHealth -ComputerName server01,server02 |
    ConvertTo-Json -Depth 6 |
    Set-Content ".\$case-fleet.json"

Get-SchunkGpoChangeAudit -SinceDays 30 -IncludeFingerprint |
    ConvertTo-Json -Depth 6 |
    Set-Content ".\$case-gpo.json"

New-SchunkIncidentBundle -OutputPath ".\$case-windows" -Profile Full
```

Then document:

1. what failed,
2. when it started,
3. what evidence was collected,
4. what was **not** changed,
5. what changed during remediation,
6. whether the post-change capture differs from the original.

That is the difference between “I tried some things” and an engineering handoff.
