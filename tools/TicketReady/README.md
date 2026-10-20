# TicketReady v0.1.0

**Know what to check. Before you fix.**

TicketReady is an **offline, read-only, privacy-conscious Windows support report**. A user double-clicks a launcher, then gets a readable HTML report and a structured JSON copy. There is no installer, agent, admin elevation, account, subscription, telemetry, or automated fix.

![GitHub release](https://img.shields.io/github/v/release/dschunk/windows-it-toolkit?include_prereleases&label=Windows%20Toolkit)
[Source](TicketReady.ps1) · [Support issues](https://github.com/dschunk/windows-it-toolkit/issues)

## Download and run

**[Download TicketReady v0.1.0 ZIP from GitHub Releases](https://github.com/dschunk/windows-it-toolkit/releases/tag/ticketready-v0.1.0)**

1. Download and extract the ZIP.
2. Inspect the source if required by your organization's security policy.
3. Double-click **RUN-TicketReady.cmd**.
4. The HTML report opens in your browser. The HTML and JSON reports are saved in **Documents > TicketReady Reports**.
5. **Review both files before sharing** with support or a public forum.

The launcher uses an execution-policy exception limited to its PowerShell process because downloaded scripts may be unsigned. It does not permanently change execution policy, but do not circumvent corporate script restrictions. If enterprise policy prevents running it, ask IT for an approved method.

You can also run the script directly from an existing trusted PowerShell session:

```powershell
.\TicketReady.ps1 -NoBrowser -OutputDirectory "$HOME\Desktop\Support"
```

### What it checks

| Area | Observations |
|---|---|
| Windows | OS name, version, uptime |
| Hardware | Manufacturer, model, logical CPU count |
| Memory | Point-in-time used percentage |
| Disk | Capacity and free-space percentage per fixed volume |
| Reboot | Two standard reboot-required registry locations |
| Event Log | System critical/error event count over 24 hours (capped at 200+) |
| Network | Number of adapters reporting an active link (no internet probe) |
| Battery | Charge percentage if present |
| Processes | Optional top five process names by working-set memory |

### Useful options

```powershell
# Create reports without launching the browser.
.\TicketReady.ps1 -NoBrowser

# Specify where reports should be saved.
.\TicketReady.ps1 -NoBrowser -OutputDirectory "C:\Support"

# Include the five largest processes (may reveal identifying information).
.\TicketReady.ps1 -IncludeProcesses

# Generate fully fictional demo data, without reading Windows system details.
.\TicketReady.ps1 -Demo -NoBrowser -OutputDirectory ".\Sample"
```

## Privacy and security

Default reports omit the computer name, user name, serial number, IP and MAC addresses, wireless network names, event messages, process command lines, files, browser history, and application credentials. The script makes **no outgoing requests** and does not automatically upload reports. JSON and HTML contain the same minimized data.

**Caution:** Device model and drive labels can still expose context. The optional process names may contain personally or organizationally sensitive text. Always review reports before forwarding or posting them.

TicketReady only reads system state. It does **not** repair Windows, run a speed test, evaluate SMART drive health, scan for malware, or interpret raw Event Log messages. Low free space and high snapshot memory usage are human review hints, not diagnoses. Unknown metrics should be treated as unverified.

## For help desks

Ask a user to send the HTML report after checking it for private details. Use the JSON with your own internal ticket tooling, under your normal data-handling policies. Need deeper server, identity or multi-host evidence? Use [SchunkOps](https://github.com/dschunk/windows-it-toolkit), the parent project.

## Packaging

A Windows GitHub Actions workflow checks script parsing, generates a fictional sample report, runs a Windows smoke test, and builds the ZIP. The first release includes the tool, launcher, README, MIT license and sample HTML report; a SHA-256 checksum file accompanies it. Check the release page for workflow status before distribution.

## Contributing

Submit issues and improvements in the [Windows IT Toolkit issue tracker](https://github.com/dschunk/windows-it-toolkit/issues) with a **TicketReady:** prefix. Do not submit raw reports containing private details. Keep changes offline and read-only by default.

Independently maintained by [David Schunk](https://www.davidschunk.com/). MIT licensed via the [parent project](../../LICENSE). Not endorsed by or associated with any employer.

**Compatibility:** Intended for Windows 10/11 and supported Windows Server versions with Windows PowerShell 5.1. Not comprehensively tested across every Windows build or organizational policy.
