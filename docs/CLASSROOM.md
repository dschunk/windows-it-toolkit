# Classroom & Lab Guide

SchunkOps can be used as a teaching repository for Windows support, systems administration, Active Directory, infrastructure operations, PowerShell, and incident-response courses.

The repository is most useful when students are asked to explain **why evidence matters**, not simply copy commands.

> Recommended environment: disposable Windows VMs, a lab domain, synthetic users, and non-production infrastructure.

## Learning objectives

Students should be able to:

- distinguish observation from remediation;
- collect structured troubleshooting evidence;
- explain why DNS, time, trust, authentication, and network reachability are dependencies;
- document required privileges before running a tool;
- preserve before/after state during incidents;
- produce a handoff that another technician can continue;
- interpret partial failure and unknown state honestly;
- explain why read-only-first tooling is safer for first-contact diagnostics.

## Lab 1 — Five-minute endpoint triage

**Level:** introductory

Run:

```powershell
Get-SchunkEndpointTriage
```

Ask students to classify each finding into:

1. identity / domain;
2. network;
3. storage / resource pressure;
4. reboot / servicing;
5. services;
6. event evidence.

Then export the evidence:

```powershell
Get-SchunkEndpointTriage |
    ConvertTo-Json -Depth 6 |
    Set-Content .\endpoint-triage.json
```

**Deliverable:** a short ticket update that contains facts, a hypothesis, missing evidence, and the next least-disruptive action.

## Lab 2 — DNS vs network

**Level:** introductory / intermediate

Use:

```powershell
Test-SchunkDnsClient -Name fileserver.contoso.com
Test-SchunkNetworkPath -ComputerName fileserver.contoso.com -Port 445
```

Create one lab where DNS is wrong and another where DNS works but TCP/445 is blocked.

**Question:** What evidence distinguishes the two cases?

## Lab 3 — Domain trust

**Level:** intermediate

Use:

```powershell
Get-SchunkDomainTrustStatus -TestPorts
```

Have students explain:

- domain membership;
- secure channel;
- DC discovery;
- DNS dependency;
- service-port reachability.

**Assessment:** students should identify which findings are enough to justify escalation and which still require more evidence.

## Lab 4 — Active Directory replication

**Level:** intermediate

Use:

```powershell
Get-SchunkADReplicationHealth
```

Students should explain why identity issues can appear inconsistent when domain controllers disagree.

**Extension:** pair replication evidence with DNS and time-service checks.

## Lab 5 — Account lockout investigation

**Level:** intermediate

Use:

```powershell
Get-SchunkAccountLockoutTrace -Identity jsmith -LookbackHours 24
```

Students trace event 4740 and identify the reported caller computer.

**Discussion:** Why should a lockout-tracing tool not automatically unlock the account?

## Lab 6 — Kerberos and duplicate SPNs

**Level:** intermediate / advanced

Use:

```powershell
Get-SchunkKerberosSpnAudit -Identity svc_web
```

In an isolated lab, create a duplicate SPN and ask students to:

1. observe the authentication failure;
2. identify duplicate ownership;
3. explain the root cause;
4. write the safe correction plan.

Do not turn the diagnostic into automated remediation.

## Lab 7 — Group Policy change evidence

**Level:** intermediate / advanced

Create a baseline:

```powershell
Get-SchunkGpoChangeAudit -SinceDays 3650 -IncludeFingerprint |
    ConvertTo-Json -Depth 5 |
    Set-Content .\gpo-baseline.json
```

Make a controlled lab change, then compare later output.

**Learning goal:** policy should be treated as operational state that can be reviewed and evidenced.

## Lab 8 — Incident evidence before and after remediation

**Level:** intermediate / advanced

Before:

```powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042 -Profile Full
```

After one controlled remediation:

```powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042-After -Profile Full

Compare-SchunkIncidentBundle `
    -ReferencePath C:\IR\INC-0042 `
    -DifferencePath C:\IR\INC-0042-After
```

**Deliverables:**

- before evidence;
- after evidence;
- change performed;
- rollback path;
- concise root-cause statement;
- recommendation to improve detection or recovery.

## Lab 9 — Server audit and operational handoff

**Level:** advanced

Use:

```powershell
Invoke-SchunkServerAudit -IncludeIis -IncludeHyperV -HtmlPath C:\Reports\server-audit.html
```

Pair the output with the [System Runbook](https://github.com/dschunk/build-it-like-you-wont-be-there/blob/main/templates/system-runbook.md) and [Engineering Handoff Checklist](https://github.com/dschunk/build-it-like-you-wont-be-there/blob/main/templates/handoff-checklist.md).

**Capstone question:** Could a different student operate this server without asking the original builder for undocumented information?

## Assessment rubric

A strong submission should show:

| Area | What good work looks like |
|---|---|
| Evidence | Findings are captured before changes |
| Reasoning | Facts are separated from assumptions |
| Safety | Scope and privileges are understood |
| Reproducibility | Commands and environment are documented |
| Communication | Another technician could continue from the handoff |
| Recovery | Rollback or recovery is considered |
| Security | No credentials, private data, or real production identifiers are exposed |
| Reflection | Student explains what they would monitor or document better next time |

## Instructor prompts

- Why is “no output” different from “healthy”?
- What should a script do when one collector fails?
- Why are structured PowerShell objects stronger than screenshots for escalation?
- When does automation reduce risk, and when can it accelerate a mistake?
- Which evidence should be preserved before rebooting a server?
- Why do DNS and time belong in identity troubleshooting?
- How do privilege requirements affect whether a tool is safe for help desk use?
- What makes a handoff operationally complete?

## Safety

Do not run classroom exercises against production systems unless the institution has explicitly designed the exercise for that environment.

Students should never submit:

- passwords;
- tokens;
- private keys;
- real customer data;
- sensitive user data;
- private infrastructure inventories;
- internal-only hostnames or addresses;
- proprietary configuration;
- incident evidence that has not been sanitized.

## Citation

This repository includes `CITATION.cff`. Use that metadata when citing SchunkOps in academic or technical work.

## Related teaching material

- [Quick Start](QUICKSTART.md)
- [Help Desk Field Guide](HELPDESK.md)
- [Incident Response](INCIDENT-RESPONSE.md)
- [Senior Engineer Field Guide](SENIOR-ENGINEER.md)
- [Privileges](PRIVILEGES.md)
- [Profile-level Teaching Guide](https://github.com/dschunk/dschunk/blob/main/docs/CLASSROOM.md)
