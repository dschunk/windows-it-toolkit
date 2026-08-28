[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$Name,
    [string[]]$Server,
    [ValidateSet('A','AAAA','CNAME','MX','TXT','NS','SRV')][string]$Type='A'
)

foreach ($target in $Name) {
    $servers = if ($Server) {$Server} else {@($null)}
    foreach ($dnsServer in $servers) {
        $timer=[Diagnostics.Stopwatch]::StartNew()
        try {
            $params=@{Name=$target;Type=$Type;DnsOnly=$true;ErrorAction='Stop'}
            if ($dnsServer) {$params.Server=$dnsServer}
            $answer=Resolve-DnsName @params
            $timer.Stop()
            [pscustomobject]@{Name=$target;Server=if($dnsServer){$dnsServer}else{'System default'};Type=$Type;Success=$true;Milliseconds=$timer.ElapsedMilliseconds;Answer=($answer.IPAddress,$answer.NameHost,$answer.NameExchange|Where-Object {$_}) -join ', ';Error=$null}
        } catch {
            $timer.Stop()
            [pscustomobject]@{Name=$target;Server=if($dnsServer){$dnsServer}else{'System default'};Type=$Type;Success=$false;Milliseconds=$timer.ElapsedMilliseconds;Answer=$null;Error=$_.Exception.Message}
        }
    }
}
