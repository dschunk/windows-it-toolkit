[CmdletBinding()]
param(
    [string[]]$ComputerName,
    [ValidateRange(100,30000)][int]$TimeoutMilliseconds=2000
)

if(-not $ComputerName){
    if(-not (Get-Module -ListAvailable ActiveDirectory)){throw 'Specify ComputerName or install the ActiveDirectory module.'}
    Import-Module ActiveDirectory
    $ComputerName=@(Get-ADDomainController -Filter * | Select-Object -ExpandProperty HostName)
}

$ports=[ordered]@{DNS=53;Kerberos=88;RPC=135;LDAP=389;SMB=445;KerberosPassword=464;LDAPS=636;GlobalCatalog=3268;GlobalCatalogTLS=3269}
foreach($computer in $ComputerName){
    foreach($service in $ports.Keys){
        $client=[Net.Sockets.TcpClient]::new();$started=Get-Date;$open=$false;$errorText=$null
        try{$task=$client.ConnectAsync($computer,$ports[$service]);$open=$task.Wait($TimeoutMilliseconds) -and $client.Connected;if(-not $open){$errorText='Timeout'}}
        catch{$errorText=$_.Exception.GetBaseException().Message}
        finally{$client.Dispose()}
        [pscustomobject]@{DomainController=$computer;Service=$service;Port=$ports[$service];Open=$open;Milliseconds=[math]::Round(((Get-Date)-$started).TotalMilliseconds);Error=$errorText}
    }
}
