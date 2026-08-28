[CmdletBinding()]
param([switch]$IncludeAdministrative)

Get-SmbShare | Where-Object {$IncludeAdministrative -or -not $_.Special} | ForEach-Object {
    $share=$_
    $access=Get-SmbShareAccess -Name $share.Name -ErrorAction SilentlyContinue
    [pscustomobject]@{
        Name=$share.Name;Path=$share.Path;Description=$share.Description;Special=$share.Special
        ContinuouslyAvailable=$share.ContinuouslyAvailable;EncryptData=$share.EncryptData
        FolderEnumerationMode=$share.FolderEnumerationMode;CachingMode=$share.CachingMode
        FullAccess=@($access | Where-Object AccessRight -eq Full | Select-Object -ExpandProperty AccountName) -join '; '
        ChangeAccess=@($access | Where-Object AccessRight -eq Change | Select-Object -ExpandProperty AccountName) -join '; '
        ReadAccess=@($access | Where-Object AccessRight -eq Read | Select-Object -ExpandProperty AccountName) -join '; '
    }
} | Sort-Object Name
