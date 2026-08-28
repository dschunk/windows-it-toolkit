[CmdletBinding()]
param(
    [ValidateRange(1,300)][int]$ReplicationWarningMinutes = 60
)

if (-not (Get-Module -ListAvailable ActiveDirectory)) {
    throw 'The ActiveDirectory PowerShell module is required.'
}

Import-Module ActiveDirectory
$domain = Get-ADDomain
$forest = Get-ADForest
$controllers = Get-ADDomainController -Filter *
$replication = Get-ADReplicationPartnerMetadata -Target $domain.DNSRoot -Scope Domain -ErrorAction SilentlyContinue
$cutoff = (Get-Date).AddMinutes(-$ReplicationWarningMinutes)

foreach ($dc in $controllers) {
    $partners = @($replication | Where-Object {$_.Server -like "$($dc.HostName)*"})
    $network = Test-NetConnection -ComputerName $dc.HostName -Port 389 -WarningAction SilentlyContinue
    [pscustomobject]@{
        Domain = $domain.DNSRoot
        Forest = $forest.Name
        DomainController = $dc.HostName
        Site = $dc.Site
        IPv4Address = $dc.IPv4Address
        IsGlobalCatalog = $dc.IsGlobalCatalog
        LdapReachable = $network.TcpTestSucceeded
        ReplicationPartners = $partners.Count
        ReplicationFailures = @($partners | Where-Object {$_.LastReplicationResult -ne 0}).Count
        StaleReplicationPartners = @($partners | Where-Object {$_.LastReplicationSuccess -lt $cutoff}).Count
        OldestSuccess = ($partners | Sort-Object LastReplicationSuccess | Select-Object -First 1).LastReplicationSuccess
    }
}
