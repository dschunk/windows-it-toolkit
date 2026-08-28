[CmdletBinding()]
param([string[]]$ComputerName=@($env:COMPUTERNAME))

foreach($computer in $ComputerName){
    try{
        $output=& w32tm.exe /stripchart /computer:$computer /dataonly /samples:3 2>&1
        $samples=@($output | Select-String -Pattern '([+-][0-9]+\.[0-9]+)s' | ForEach-Object {[double]$_.Matches[0].Groups[1].Value})
        [pscustomobject]@{
            ComputerName=$computer;Reachable=$samples.Count -gt 0;Samples=$samples.Count
            AverageOffsetSeconds=if($samples){[math]::Round(($samples | Measure-Object -Average).Average,6)}else{$null}
            MaximumAbsoluteOffsetSeconds=if($samples){[math]::Round(($samples | ForEach-Object {[math]::Abs($_)} | Measure-Object -Maximum).Maximum,6)}else{$null}
            RawOutput=$output -join [Environment]::NewLine;Error=$null
        }
    }catch{
        [pscustomobject]@{ComputerName=$computer;Reachable=$false;Samples=0;AverageOffsetSeconds=$null;MaximumAbsoluteOffsetSeconds=$null;RawOutput=$null;Error=$_.Exception.Message}
    }
}
