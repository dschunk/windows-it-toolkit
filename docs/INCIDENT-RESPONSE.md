# The 15-Minute Windows Incident Triage

This field workflow is designed for the first minutes after someone says,
“The server is acting weird.” It favors evidence preservation, structured
output, explicit failures, and commands another engineer can reproduce.

> Build it like you will not be there tomorrow. Investigate it like someone
> else will have to defend your conclusions.

## 1. Start an elevated PowerShell session

Use an account approved for the affected system. Do not bypass organizational
logging, change-control, endpoint-protection, or evidence-handling requirements.

~~~powershell
Import-Module SchunkOps
New-Item C:\IR -ItemType Directory -Force
~~~

## 2. Capture an evidence bundle

Standard mode is appropriate for routine operational incidents:

~~~powershell
New-SchunkIncidentBundle -OutputPath C:\IR\INC-0042
~~~

Full mode adds software, update, task, authentication, and BitLocker data:

~~~powershell
$incident = @{
    OutputPath = 'C:\IR\INC-0042-Full'
    Profile = 'Full'
    EventLookbackHours = 72
}
New-SchunkIncidentBundle @incident
~~~

Each collector writes a separate JSON document. The manifest records its
status, record count, completion time, and SHA-256 hash. A failed collector is
reported without silently discarding the other evidence.

## 3. Answer the highest-value questions

~~~powershell
Get-SchunkServerHealth
Get-SchunkPendingReboot
Get-SchunkServiceFailure -EventLookbackHours 24
Get-SchunkLogonFailure -Hours 24
Get-SchunkListeningPort | Sort-Object LocalPort
Get-SchunkEventTriage -Hours 24 | Select-Object -First 20
~~~

Ask:

- Is the system unhealthy, or is one service unhealthy?
- Did the failure start after a reboot, update, task, or service change?
- Are repeated authentication failures coming from one identity or source?
- Is a new listener or process visible?
- Which conclusion is supported by captured evidence rather than memory?

## 4. Compare against another capture

Take a second bundle after containment or recovery, then compare the manifests:

~~~powershell
$comparison = @{
    ReferencePath = 'C:\IR\INC-0042'
    DifferencePath = 'C:\IR\INC-0042-After'
}
Compare-SchunkIncidentBundle @comparison
~~~

A Changed result means the collector file hash differs. It is a signal to
inspect the corresponding JSON; it is not automatically evidence of malicious
activity.

## 5. Preserve and hand off

- Record the incident number, operator, timezone, and system time source.
- Copy the complete bundle, not selected screenshots.
- Preserve the original bundle as read-only according to your policy.
- Document every containment or remediation action separately.
- Treat usernames, network addresses, software, paths, and event contents as
  potentially sensitive.
- Do not publish a real incident bundle in a GitHub issue.

## What this workflow does not replace

SchunkOps is an operations and first-response toolkit. It does not replace EDR,
memory or disk forensics, chain-of-custody procedures, legal guidance, or your
organization's incident-response plan.

Created by [David Schunk](https://github.com/dschunk) as part of the
[Windows IT Toolkit](https://github.com/dschunk/windows-it-toolkit).
