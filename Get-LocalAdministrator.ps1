[CmdletBinding()]
param([string[]]$ComputerName = @($env:COMPUTERNAME))

$script = {
    try {
        Get-LocalGroupMember -Group 'Administrators' -ErrorAction Stop | ForEach-Object {
            [pscustomobject]@{
                ComputerName = $env:COMPUTERNAME
                Name = $_.Name
                ObjectClass = $_.ObjectClass
                PrincipalSource = $_.PrincipalSource
                Sid = $_.SID.Value
            }
        }
    } catch {
        Write-Error "Unable to enumerate local administrators: $($_.Exception.Message)"
    }
}

foreach ($computer in $ComputerName) {
    if ($computer -in @('.','localhost',$env:COMPUTERNAME)) {& $script}
    else {Invoke-Command -ComputerName $computer -ScriptBlock $script -ErrorAction Continue}
}
