[CmdletBinding()]
param(
    [ValidateSet('Inbound','Outbound','Both')][string]$Direction='Inbound',
    [switch]$EnabledOnly
)

$rules=Get-NetFirewallRule -PolicyStore ActiveStore
if($Direction -ne 'Both'){$rules=$rules | Where-Object Direction -eq $Direction}
if($EnabledOnly){$rules=$rules | Where-Object Enabled -eq 'True'}

$rules | ForEach-Object {
    $rule=$_
    $ports=@($rule | Get-NetFirewallPortFilter -ErrorAction SilentlyContinue)
    $addresses=@($rule | Get-NetFirewallAddressFilter -ErrorAction SilentlyContinue)
    foreach($port in $ports){
        [pscustomobject]@{
            DisplayName=$rule.DisplayName;Enabled=$rule.Enabled;Direction=$rule.Direction;Action=$rule.Action
            Profile=$rule.Profile;Protocol=$port.Protocol;LocalPort=$port.LocalPort;RemotePort=$port.RemotePort
            LocalAddress=($addresses.LocalAddress -join ',');RemoteAddress=($addresses.RemoteAddress -join ',')
            Program=($rule | Get-NetFirewallApplicationFilter -ErrorAction SilentlyContinue).Program
        }
    }
} | Sort-Object Direction,Action,LocalPort,DisplayName
