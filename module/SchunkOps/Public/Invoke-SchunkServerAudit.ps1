function Invoke-SchunkServerAudit {
    <#
    .SYNOPSIS
    Runs a coordinated, read-only Windows Server health audit.

    .DESCRIPTION
    Combines SchunkOps server health, reboot state, service failures, event triage,
    listening ports, Windows Update health, and optional IIS/Hyper-V checks into
    one structured object. When HtmlPath is supplied, writes a portable HTML
    report while still returning the audit object.

    .PARAMETER EventLookbackHours
    Number of hours of recent event and service-failure history to inspect.

    .PARAMETER CriticalServices
    Service names that should be highlighted by the core server-health check.

    .PARAMETER IncludeIis
    Include IIS site, binding, and application-pool health when WebAdministration
    is available.

    .PARAMETER IncludeHyperV
    Include Hyper-V host, VM, switch, disk, and checkpoint health when the Hyper-V
    module is available.

    .PARAMETER HtmlPath
    Optional path for a self-contained HTML report.

    .EXAMPLE
    Invoke-SchunkServerAudit

    .EXAMPLE
    Invoke-SchunkServerAudit -IncludeIis -IncludeHyperV -HtmlPath C:\Reports\server-audit.html

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author: David Maksim Schunk
    Project: https://github.com/dschunk/windows-it-toolkit
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateRange(1, 720)]
        [int]$EventLookbackHours = 24,

        [string[]]$CriticalServices = @('WinRM', 'EventLog', 'W32Time'),

        [switch]$IncludeIis,

        [switch]$IncludeHyperV,

        [string]$HtmlPath
    )

    $started = Get-Date

    $audit = [ordered]@{
        ComputerName        = $env:COMPUTERNAME
        CollectedAt         = $started
        ServerHealth        = Get-SchunkServerHealth -CriticalServices $CriticalServices -EventLookbackHours $EventLookbackHours
        PendingReboot       = Get-SchunkPendingReboot
        ServiceFailures     = @(Get-SchunkServiceFailure -LookbackHours $EventLookbackHours)
        EventTriage         = @(Get-SchunkEventTriage -Hours $EventLookbackHours)
        ListeningPorts      = @(Get-SchunkListeningPort)
        WindowsUpdateHealth = Get-SchunkWindowsUpdateHealth
        IisHealth           = $null
        HyperVHealth        = $null
    }

    if ($IncludeIis) {
        try {
            $audit.IisHealth = Get-SchunkIisHealth
        }
        catch {
            $audit.IisHealth = [pscustomobject]@{ Available = $false; Error = $_.Exception.Message }
        }
    }

    if ($IncludeHyperV) {
        try {
            $audit.HyperVHealth = Get-SchunkHyperVHealth
        }
        catch {
            $audit.HyperVHealth = [pscustomobject]@{ Available = $false; Error = $_.Exception.Message }
        }
    }

    $auditObject = [pscustomobject]$audit
    $auditObject | Add-Member -NotePropertyName DurationSeconds -NotePropertyValue ([math]::Round(((Get-Date) - $started).TotalSeconds, 2))

    if ($HtmlPath -and $PSCmdlet.ShouldProcess($HtmlPath, 'Write SchunkOps Windows Server audit report')) {
        $parent = Split-Path -Parent $HtmlPath
        if ($parent -and -not (Test-Path -LiteralPath $parent)) {
            $null = New-Item -ItemType Directory -Path $parent -Force
        }

        $encode = {
            param($Value)
            [System.Net.WebUtility]::HtmlEncode(($Value | ConvertTo-Json -Depth 10))
        }

        $health = & $encode $auditObject.ServerHealth
        $reboot = & $encode $auditObject.PendingReboot
        $updates = & $encode $auditObject.WindowsUpdateHealth
        $services = & $encode $auditObject.ServiceFailures
        $events = & $encode $auditObject.EventTriage
        $ports = & $encode $auditObject.ListeningPorts
        $iis = & $encode $auditObject.IisHealth
        $hyperv = & $encode $auditObject.HyperVHealth

        $html = @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>SchunkOps Server Audit - $($auditObject.ComputerName)</title>
<style>
body{font-family:Segoe UI,Arial,sans-serif;margin:0;background:#f4f6f8;color:#17202a}
header{background:#0b1f3a;color:white;padding:32px} main{max-width:1100px;margin:auto;padding:24px}
section{background:white;margin:0 0 18px;padding:20px;border-radius:10px;box-shadow:0 1px 4px rgba(0,0,0,.08)}
h1,h2{margin-top:0} pre{white-space:pre-wrap;word-break:break-word;background:#f7f8fa;padding:14px;border-radius:8px;overflow:auto}
.meta{opacity:.82} footer{max-width:1100px;margin:auto;padding:8px 24px 32px;color:#566}
</style>
</head>
<body>
<header><h1>SchunkOps Windows Server Audit</h1><div class="meta">$($auditObject.ComputerName) · $($auditObject.CollectedAt.ToString('u')) · $($auditObject.DurationSeconds)s</div></header>
<main>
<section><h2>Server health</h2><pre>$health</pre></section>
<section><h2>Pending reboot</h2><pre>$reboot</pre></section>
<section><h2>Windows Update</h2><pre>$updates</pre></section>
<section><h2>Service failures</h2><pre>$services</pre></section>
<section><h2>Event triage</h2><pre>$events</pre></section>
<section><h2>Listening ports</h2><pre>$ports</pre></section>
<section><h2>IIS</h2><pre>$iis</pre></section>
<section><h2>Hyper-V</h2><pre>$hyperv</pre></section>
</main>
<footer>Generated by SchunkOps · David Maksim Schunk · Read-only collection except for this report file.</footer>
</body>
</html>
"@
        Set-Content -LiteralPath $HtmlPath -Value $html -Encoding UTF8
        $auditObject | Add-Member -NotePropertyName HtmlReport -NotePropertyValue (Resolve-Path -LiteralPath $HtmlPath).Path
    }

    $auditObject
}
