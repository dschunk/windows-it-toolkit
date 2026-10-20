# TicketReady v0.2.1 - (c) David Schunk, MIT license
# Offline, read-only, privacy-conscious Windows support snapshot.
[CmdletBinding()]
param(
    [string]$OutputDirectory,
    [switch]$NoBrowser,
    [switch]$IncludeProcesses,
    [switch]$IncludeDeviceModel,
    [ValidateSet('General','SlowPC','Storage','Network','Updates')]
    [string]$Issue = 'General',
    [string]$BaselinePath,
    [switch]$Demo
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Escape-Html {
    param([AllowNull()][object]$Value)
    if ($null -eq $Value) { return '' }
    [System.Net.WebUtility]::HtmlEncode([string]$Value)
}
function Try-Collect {
    param([scriptblock]$Action,[string]$Label)
    try { & $Action }
    catch {
        [void]$script:Notes.Add(('{0}: unavailable or permission restricted.' -f $Label))
        $null
    }
}
$script:Notes = New-Object 'System.Collections.Generic.List[string]'
$now = Get-Date
$os = $null; $cs = $null; $diskRaw = @(); $battery = @()
$network = $null; $errors = 'Unknown'; $reboot = 'Unknown'; $processes = @()
if ($Demo) {
    $os = [pscustomobject]@{
        Caption='Example Windows 11 Pro'; Version='10.0.26100'
        LastBootUpTime=$now.AddDays(-3)
        TotalVisibleMemorySize=16777216; FreePhysicalMemory=6291456
    }
    $cs = [pscustomobject]@{ Manufacturer='Example'; Model='Computer'; NumberOfLogicalProcessors=8 }
    $diskRaw = @([pscustomobject]@{DeviceID='C:';Size=512GB;FreeSpace=155GB},
                 [pscustomobject]@{DeviceID='D:';Size=256GB;FreeSpace=15GB})
    $battery = @([pscustomobject]@{EstimatedChargeRemaining=68})
    $network = 1; $errors='3'; $reboot='No'
    if ($IncludeProcesses) { $processes = @([pscustomobject]@{Name='ExampleBrowser';MemoryMB=321}) }
    [void]$script:Notes.Add('DEMO: all values are synthetic. No computer information was read.')
} else {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
        throw 'TicketReady must run on Windows unless -Demo is selected.'
    }
    $os = Try-Collect { Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } 'Windows information'
    $cs = Try-Collect { Get-CimInstance Win32_ComputerSystem -ErrorAction Stop } 'Hardware'
    $diskRaw = @(Try-Collect { Get-CimInstance Win32_LogicalDisk -Filter 'DriveType = 3' -ErrorAction Stop } 'Storage' | Where-Object { $null -ne $_ })
    $battery = @(Try-Collect { Get-CimInstance Win32_Battery -ErrorAction Stop } 'Battery' | Where-Object { $null -ne $_ })
    $adapterList = @(Try-Collect { Get-NetAdapter -ErrorAction Stop } 'Network adapter state' | Where-Object { $null -ne $_ })
    if ($adapterList.Count -gt 0) { $network = @($adapterList | Where-Object { $_.Status -eq 'Up' }).Count }
    try {
        $events = @(Get-WinEvent -FilterHashtable @{
            LogName='System';Level=@(1,2);StartTime=$now.AddHours(-24)
        } -MaxEvents 201 -ErrorAction Stop)
        $errors = if ($events.Count -gt 200) { '200+' } else { [string]$events.Count }
    } catch { [void]$script:Notes.Add('Recent event count unavailable or no events matched.') }
    try {
        $reboot='No'
        foreach ($key in @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired')) {
            if (Test-Path -LiteralPath $key -ErrorAction Stop) { $reboot='Yes'; break }
        }
    } catch {
        $reboot='Unknown'
        [void]$script:Notes.Add('Reboot status could not be verified.')
    }
    if ($IncludeProcesses) {
        $found = @(Try-Collect { Get-Process -ErrorAction Stop | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 } 'Process list' | Where-Object { $null -ne $_ })
        $processes = @($found | ForEach-Object {
            [pscustomobject]@{ Name=[string]$_.ProcessName;MemoryMB=[math]::Round($_.WorkingSet64/1MB,0) }
        })
    }
}
$osName='Unavailable';$osVersion='Unavailable';$uptime='Unavailable';$mem=$null;$hardware='Unavailable';$threads='Unavailable'
if ($null -ne $os) {
    $osName=[string]$os.Caption;$osVersion=[string]$os.Version
    try { $uptime=('{0:N1} days' -f ($now-[datetime]$os.LastBootUpTime).TotalDays) }
    catch { [void]$script:Notes.Add('Uptime could not be calculated.') }
    if ([double]$os.TotalVisibleMemorySize -gt 0) {
        $mem=[math]::Round(100*([double]$os.TotalVisibleMemorySize-[double]$os.FreePhysicalMemory)/[double]$os.TotalVisibleMemorySize,0)
    }
}
if ($null -ne $cs) {
    if ($IncludeDeviceModel) { $hardware=('{0} {1}' -f $cs.Manufacturer,$cs.Model).Trim() }
    else { $hardware='Hidden for privacy' }
    if ($null -ne $cs.NumberOfLogicalProcessors) { $threads=[string]$cs.NumberOfLogicalProcessors }
}
$disks=@()
foreach ($disk in $diskRaw) {
    if ($null -eq $disk.Size -or [double]$disk.Size -le 0) { continue }
    $disks += [pscustomobject]@{
        Drive=[string]$disk.DeviceID
        TotalGB=[math]::Round([double]$disk.Size/1GB,1)
        FreeGB=[math]::Round([double]$disk.FreeSpace/1GB,1)
        FreePercent=[math]::Round(100*[double]$disk.FreeSpace/[double]$disk.Size,0)
    }
}
$batteryPercent=$null
if ($battery.Count -gt 0 -and $null -ne $battery[0].EstimatedChargeRemaining) {
    $batteryPercent=[int]$battery[0].EstimatedChargeRemaining
}
$checks=New-Object 'System.Collections.Generic.List[object]'
if ($null -eq $mem) { [void]$checks.Add([pscustomobject]@{Name='Memory';Finding='Unknown';Meaning='Metric unavailable.'}) }
elseif ($mem -ge 90) { [void]$checks.Add([pscustomobject]@{Name='Memory';Finding='Review';Meaning='High in this snapshot; check sustained usage.'}) }
else { [void]$checks.Add([pscustomobject]@{Name='Memory';Finding='Observed';Meaning='One snapshot; not proof of performance.'}) }
foreach ($disk in $disks) {
    $flag=if($disk.FreePercent -lt 10){'Review'}else{'Observed'}
    [void]$checks.Add([pscustomobject]@{Name=('Disk '+$disk.Drive);Finding=$flag;Meaning=('{0}% free; capacity only, not physical disk health.' -f $disk.FreePercent)})
}
if ($disks.Count -eq 0) { [void]$checks.Add([pscustomobject]@{Name='Storage';Finding='Unknown';Meaning='Fixed-drive metrics unavailable.'}) }
$rebootFinding = if ($reboot -eq 'Yes') { 'Review' } else { $reboot }
[void]$checks.Add([pscustomobject]@{Name='Pending reboot';Finding=$rebootFinding;Meaning='Two standard registry markers, not an exhaustive check.'})
[void]$checks.Add([pscustomobject]@{Name='System errors (24h)';Finding=$errors;Meaning='Critical and error events (capped at 200+); count alone is not a diagnosis.'})
$networkText=if($null -eq $network){'Unknown'}else{[string]$network}
[void]$checks.Add([pscustomobject]@{Name='Adapters with link up';Finding=$networkText;Meaning='Link status only; no internet connectivity test.'})

# These observations are a support triage starting point, not a health score.
$reviewCount = @($checks | Where-Object { $_.Finding -eq 'Review' }).Count
$unknownCount = @($checks | Where-Object { $_.Finding -eq 'Unknown' }).Count
$changes = New-Object 'System.Collections.Generic.List[object]'
$baselineUsed = $false
if (-not [string]::IsNullOrWhiteSpace($BaselinePath)) {
    if (-not (Test-Path -LiteralPath $BaselinePath -PathType Leaf)) {
        throw 'BaselinePath must point to an existing TicketReady JSON report.'
    }
    if ((Get-Item -LiteralPath $BaselinePath).Length -gt 1048576) {
        throw 'Baseline report exceeds the 1 MB limit.'
    }
    try {
        $baseline = Get-Content -LiteralPath $BaselinePath -Raw -ErrorAction Stop |
            ConvertFrom-Json -ErrorAction Stop
        if ($baseline.Product -ne 'TicketReady' -or $null -eq $baseline.Windows -or
            $null -eq $baseline.Disks) { throw 'Not a TicketReady report.' }
        $baselineUsed = $true
        if ($null -ne $baseline.Windows.MemoryUsedPercent -and $null -ne $mem) {
            $delta = [math]::Round([double]$mem - [double]$baseline.Windows.MemoryUsedPercent,0)
            $note = if ($delta -gt 0) { "Higher by $delta percentage points" }
                    elseif ($delta -lt 0) { 'Lower by ' + [math]::Abs($delta) + ' percentage points' }
                    else { 'No measured change' }
            [void]$changes.Add([pscustomobject]@{
                Metric='Memory used';Before=([string]$baseline.Windows.MemoryUsedPercent+'%')
                After=([string]$mem+'%');Note=$note
            })
        }
        foreach ($disk in $disks) {
            $matches = @($baseline.Disks | Where-Object { $_.Drive -eq $disk.Drive } |
                Select-Object -First 1)
            if ($matches.Count -eq 0 -or $null -eq $matches[0].FreeGB) { continue }
            $delta = [math]::Round([double]$disk.FreeGB - [double]$matches[0].FreeGB,1)
            $note = if ($delta -lt 0) { [string][math]::Abs($delta) + ' GB less free' }
                    elseif ($delta -gt 0) { [string]$delta + ' GB more free' }
                    else { 'No measured change' }
            [void]$changes.Add([pscustomobject]@{
                Metric=('Disk '+$disk.Drive);Before=([string]$matches[0].FreeGB+' GB')
                After=([string]$disk.FreeGB+' GB');Note=$note
            })
        }
        if ($null -ne $baseline.PendingReboot -and
            $baseline.PendingReboot -ne $reboot) {
            [void]$changes.Add([pscustomobject]@{
                Metric='Pending reboot';Before=[string]$baseline.PendingReboot
                After=$reboot;Note='Indicator changed between reports'
            })
        }
    } catch {
        throw 'Invalid TicketReady baseline. Choose a valid exported TicketReady JSON file.'
    }
}
$guideMap = @{
 General=@(
    'Write down the exact symptom, onset and any reproducible steps.',
    'Review findings and collection limits; an observation is not proof of a cause.',
    'Record recent changes and send only the reviewed report to support.'
 )
 SlowPC=@(
    'Identify whether slowdown happens at sign-in, startup or one application.',
    'Compare current memory and free space to an earlier snapshot under similar conditions.',
    'Use Task Manager and Resource Monitor with IT to correlate behavior before changes.'
 )
 Storage=@(
    'Identify which drive is low. Do not delete unknown files.',
    'Compare free space with an earlier TicketReady report to see if capacity is changing.',
    'Confirm backups and retention rules before cleanup or expansion.'
 )
 Network=@(
    'Identify whether all destinations fail or only one application or site.',
    'Note whether Wi-Fi, Ethernet or VPN is affected; do not publish private addresses.',
    'Link-up is not connectivity: ask IT to check DNS, gateway and service reachability.'
 )
 Updates=@(
    'Find the exact error code or pending restart in Windows Update.',
    'Record update identifiers and failure times for your support team.',
    'Use approved patch-management processes before retries or restarts.'
 )
}
$nextSteps = @($guideMap[$Issue])

$report=[pscustomobject]@{
    Product='TicketReady';Version='0.2.1';CollectedAt=$now.ToString('o')
    Demo=[bool]$Demo;IssueType=$Issue;IncludesDeviceModel=[bool]$IncludeDeviceModel
    BaselineCompared=$baselineUsed;ReviewCount=$reviewCount;UnknownCount=$unknownCount
    Changes=@($changes.ToArray());NextSteps=@($nextSteps)
    Privacy='No host/user, serial, IP/MAC, SSID, event messages or command lines; model and process names require opt-in.'
    Windows=[pscustomobject]@{Name=$osName;Version=$osVersion;Hardware=$hardware;LogicalProcessors=$threads;Uptime=$uptime;MemoryUsedPercent=$mem}
    Disks=@($disks);BatteryPercent=$batteryPercent;NetworkAdaptersUp=$network
    PendingReboot=$reboot;RecentSystemErrors=$errors;Checks=@($checks.ToArray())
    Processes=@($processes);CollectionNotes=@($script:Notes.ToArray())
}
$memText=if($null -eq $mem){'Unavailable'}else{('{0}% used' -f $mem)}
$cards=''
foreach ($item in @(
    @('Operating system',$osName,$osVersion),
    @('Memory',$memText,'Point-in-time'),
    @('Uptime',$uptime,'Since last boot'),
    @('CPU threads',$threads,'Logical processors'))) {
    $cards+=('<div class="card"><small>{0}</small><strong>{1}</strong><span>{2}</span></div>' -f (Escape-Html $item[0]),(Escape-Html $item[1]),(Escape-Html $item[2]))
}
$rows=''
foreach($check in $checks) {
    $level=if($check.Finding -eq 'Review'){'warn'}else{'pill'}
    $rows+=('<tr><th>{0}</th><td><b class="{3}">{1}</b></td><td>{2}</td></tr>' -f (Escape-Html $check.Name),(Escape-Html $check.Finding),(Escape-Html $check.Meaning),$level)
}
$drives=''
foreach($disk in $disks) {
    $drives+=('<tr><th>{0}</th><td>{1} GB</td><td>{2} GB</td><td>{3}%</td></tr>' -f (Escape-Html $disk.Drive),$disk.TotalGB,$disk.FreeGB,$disk.FreePercent)
}
if (-not $drives) {$drives='<tr><td colspan="4">Unavailable</td></tr>'}
$notes=''
foreach($note in $script:Notes) {$notes+=('<li>{0}</li>' -f (Escape-Html $note))}
if (-not $notes) {$notes='<li>No collection limitations reported.</li>'}
$stepsHtml=''
$stepNumber=0
foreach($step in $nextSteps){
    $stepNumber++
    $stepsHtml+=('<li><strong>{0}.</strong> {1}</li>' -f $stepNumber,(Escape-Html $step))
}
$compareHtml=''
if($baselineUsed){
    $compareRows=''
    foreach($item in $changes){
        $compareRows+=('<tr><th>{0}</th><td>{1}</td><td>{2}</td><td>{3}</td></tr>' -f
            (Escape-Html $item.Metric),(Escape-Html $item.Before),(Escape-Html $item.After),(Escape-Html $item.Note))
    }
    if(-not $compareRows){$compareRows='<tr><td colspan="4">No comparable metrics.</td></tr>'}
    $compareHtml='<section><h2>Before and after</h2><p>Two snapshots are not a trend; compare under similar workloads.</p><table><thead><tr><th>Metric</th><th>Previous</th><th>Current</th><th>Change</th></tr></thead><tbody>'+$compareRows+'</tbody></table></section>'
}
$reviewText=if($reviewCount -eq 1){'1 review signal'}else{[string]$reviewCount+' review signals'}
$unknownText=if($unknownCount -eq 1){'1 unverified check'}else{[string]$unknownCount+' unverified checks'}
$issueSafe=Escape-Html $Issue
$procs=''
if ($IncludeProcesses) {
    $procRows=''
    foreach($process in $processes) {
        $procRows+=('<tr><th>{0}</th><td>{1} MB</td></tr>' -f (Escape-Html $process.Name),$process.MemoryMB)
    }
    if (-not $procRows) {$procRows='<tr><td colspan="2">No process data</td></tr>'}
    $procs='<section><h2>Largest processes by memory</h2><p>Opt-in: process names may reveal private information.</p><table><tr><th>Process</th><th>Working set</th></tr>'+ $procRows +'</table></section>'
}
$demoBanner=if($Demo){'<div class="demo">SAMPLE DATA — FICTIONAL</div>'}else{''}
$batteryText=if($null -eq $batteryPercent){'Not reported'}else{[string]$batteryPercent+'%'}
$collected=Escape-Html $now.ToString('yyyy-MM-dd HH:mm')
$hardwareHtml=Escape-Html $hardware
$batteryHtml=Escape-Html $batteryText
$html=@"
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow,noarchive"><title>TicketReady — Windows support report</title>
<style>
:root{color-scheme:light;--ink:#15263d;--muted:#637188;--border:#dfe7f0}*{box-sizing:border-box}body{margin:0;background:#f4f7fb;color:var(--ink);font:15px/1.55 Segoe UI,Arial,sans-serif}main{max-width:1040px;margin:auto;padding:35px 20px 55px}h1{font-size:clamp(30px,5vw,54px);letter-spacing:-.04em;line-height:1.13;margin:10px 0}h2{font-size:21px}p{color:var(--muted)}.eyebrow{font-size:12px;color:#2768a6;text-transform:uppercase;font-weight:800;letter-spacing:.1em}.lede{font-size:18px;max-width:700px}.cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin:25px 0}.card,section{background:#fff;border:1px solid var(--border);border-radius:14px;padding:22px}.card small{display:block;color:var(--muted);font-weight:bold;text-transform:uppercase}.card strong{display:block;font-size:22px;margin:10px 0;overflow-wrap:anywhere;line-height:1.2}.card span{color:var(--muted);font-size:13px}section{margin:16px 0;overflow-x:auto}table{border-collapse:collapse;width:100%;text-align:left}td,th{padding:12px 9px;border-bottom:1px solid var(--border);vertical-align:top}tr:last-child td,tr:last-child th{border:0}th{font-weight:650}.pill,.warn{border-radius:6px;padding:4px 10px;font-size:12px;background:#e6f0fe;color:#204d80}.warn{background:#fff1d8;color:#805000}.privacy{background:#eaf2ff;padding:17px 20px;border-radius:10px;color:#24446d}.demo{display:inline-block;background:#ffe4b1;padding:8px 14px;border-radius:8px;font-weight:800}footer{margin-top:24px;color:var(--muted);font-size:13px}.summary{margin:16px 0;padding:16px 20px;border-radius:12px;background:#eaf2ff;color:#16466b;display:flex;gap:15px;flex-wrap:wrap}.summary span{font-size:13px}li{margin:8px 0}@media print{body{background:white}main{padding:0}.card,section{break-inside:avoid}}@media(max-width:800px){.cards{grid-template-columns:repeat(2,1fr)}}@media(max-width:430px){.cards{grid-template-columns:1fr}main{padding:18px 12px}section{padding:14px}}
</style></head><body><main>
$demoBanner
<div class="eyebrow">TicketReady v0.2.1 · Local first-response report</div><h1>Know what to check.<br>Before you fix.</h1>
<p class="lede">An offline, read-only support summary. Findings are triage hints, not a diagnosis.</p><p>Collected $collected · $hardwareHtml · This report was generated only on the local computer.</p>
<div class="cards">$cards</div>
<div class="summary"><strong>$reviewText</strong><span>$unknownText · Issue: $issueSafe</span></div>
<section><h2>Suggested next steps</h2><p>Read-only guidance, not a diagnosis or an automatic repair.</p><ol>$stepsHtml</ol></section>
$compareHtml
<section><h2>What to review</h2><p>Unavailable values remain unknown. A review flag is not proof of a fault.</p><table><thead><tr><th>Check</th><th>Result</th><th>Interpretation</th></tr></thead><tbody>$rows</tbody></table></section>
<section><h2>Storage capacity</h2><table><thead><tr><th>Drive</th><th>Total</th><th>Free</th><th>Free %</th></tr></thead><tbody>$drives</tbody></table></section>
<section><h2>Other observations</h2><p><strong>Battery:</strong> $batteryHtml</p><p><strong>Collection notes:</strong></p><ul>$notes</ul></section>
$procs
<div class="privacy"><strong>Privacy first.</strong> Default reports exclude hostnames, usernames, serials, IP/MAC addresses, Wi-Fi names, hardware models and raw logs. Hardware models and process names require opt-in; drive letters remain visible. Review the HTML and JSON before sharing. Nothing is uploaded.</div>
<footer>Made by David Schunk · MIT licensed · <a href="https://github.com/dschunk/windows-it-toolkit/tree/main/tools/TicketReady">Source &amp; instructions</a> · No admin elevation or network requests</footer>
</main></body></html>
"@
if (-not $OutputDirectory) {
    $documents=[Environment]::GetFolderPath('MyDocuments')
    if ([string]::IsNullOrWhiteSpace($documents)) {$documents=$env:TEMP}
    $OutputDirectory=Join-Path $documents 'TicketReady Reports'
}
if (-not (Test-Path -LiteralPath $OutputDirectory)) {
    [void](New-Item -ItemType Directory -Path $OutputDirectory -Force)
}
$path=(Resolve-Path -LiteralPath $OutputDirectory).Path
$stamp=$now.ToString('yyyyMMdd-HHmmss')
$prefix=if($Demo){'TicketReady-DEMO-'}else{'TicketReady-'}
$htmlPath=Join-Path $path ($prefix+$stamp+'.html')
$jsonPath=Join-Path $path ($prefix+$stamp+'.json')
$html | Set-Content -LiteralPath $htmlPath -Encoding UTF8
$report | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
Write-Host ('HTML report: '+$htmlPath)
Write-Host ('JSON report: '+$jsonPath)
Write-Host 'Read-only checks finished. No data was uploaded or system changes made.'
if (-not $NoBrowser) {
    try { Start-Process -FilePath $htmlPath -ErrorAction Stop }
    catch { Write-Host 'Open the HTML file manually if your browser did not open.' }
}
