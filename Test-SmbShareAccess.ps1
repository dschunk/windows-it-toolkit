[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Path,
    [switch]$WriteTest
)

foreach ($share in $Path) {
    $started = Get-Date
    $readable = $false
    $writeable = $null
    $errorText = $null
    try {
        $null = Get-ChildItem -LiteralPath $share -ErrorAction Stop | Select-Object -First 1
        $readable = $true
        if ($WriteTest) {
            $probe = Join-Path $share ".access-probe-$([guid]::NewGuid().ToString('N')).tmp"
            try {
                Set-Content -LiteralPath $probe -Value 'SMB access probe' -Encoding UTF8 -ErrorAction Stop
                Remove-Item -LiteralPath $probe -Force -ErrorAction Stop
                $writeable = $true
            } catch {$writeable=$false; throw}
        }
    } catch {$errorText=$_.Exception.GetBaseException().Message}

    [pscustomobject]@{
        Path=$share;Readable=$readable;WriteTestRequested=[bool]$WriteTest;Writeable=$writeable
        ResponseMilliseconds=[math]::Round(((Get-Date)-$started).TotalMilliseconds);Error=$errorText
    }
}
