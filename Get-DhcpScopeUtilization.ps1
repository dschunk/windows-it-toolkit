[CmdletBinding()]
param([string]$ComputerName=$env:COMPUTERNAME)

if(-not (Get-Module -ListAvailable DhcpServer)){throw 'The DhcpServer PowerShell module is required.'}
Import-Module DhcpServer

Get-DhcpServerv4Scope -ComputerName $ComputerName | ForEach-Object {
    $scope=$_
    $stats=Get-DhcpServerv4ScopeStatistics -ComputerName $ComputerName -ScopeId $scope.ScopeId
    [pscustomobject]@{
        Server=$ComputerName;ScopeId=$scope.ScopeId;Name=$scope.Name;State=$scope.State
        StartRange=$scope.StartRange;EndRange=$scope.EndRange;SubnetMask=$scope.SubnetMask
        InUse=$stats.InUse;Free=$stats.Free;Reserved=$stats.Reserved
        PercentageInUse=[math]::Round($stats.PercentageInUse,2)
        LeaseDuration=$scope.LeaseDuration
    }
} | Sort-Object PercentageInUse -Descending
