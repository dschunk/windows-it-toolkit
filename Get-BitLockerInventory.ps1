[CmdletBinding()]
param()

if(-not (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue)){throw 'The BitLocker module is not available on this system.'}

Get-BitLockerVolume | ForEach-Object {
    [pscustomobject]@{
        MountPoint=$_.MountPoint;VolumeType=$_.VolumeType;VolumeStatus=$_.VolumeStatus
        ProtectionStatus=$_.ProtectionStatus;EncryptionMethod=$_.EncryptionMethod
        EncryptionPercentage=$_.EncryptionPercentage;LockStatus=$_.LockStatus
        AutoUnlockEnabled=$_.AutoUnlockEnabled
        KeyProtectors=@($_.KeyProtector | ForEach-Object {$_.KeyProtectorType}) -join ', '
        RecoveryPasswordPresent=@($_.KeyProtector | Where-Object KeyProtectorType -eq 'RecoveryPassword').Count -gt 0
    }
}
