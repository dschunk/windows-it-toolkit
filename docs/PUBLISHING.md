# Publishing SchunkOps

SchunkOps releases are validated, Authenticode-signed, and published to the
PowerShell Gallery by GitHub Actions. No signing certificate or Gallery API
key belongs in the repository.

## One-time maintainer setup

1. Create and verify the **SchunkOps** owner account on the
   [PowerShell Gallery](https://www.powershellgallery.com/).
2. Obtain a trusted code-signing certificate issued to David Schunk.
3. Export the certificate and private key to a password-protected PFX.
4. Create a GitHub environment named `powershell-gallery` and require manual
   approval for deployments to that environment.
5. Add these environment secrets:

   | Secret | Value |
   |---|---|
   | `PSGALLERY_API_KEY` | A scoped PowerShell Gallery API key |
   | `CODESIGN_PFX_BASE64` | Base64 text of the PFX file |
   | `CODESIGN_PFX_PASSWORD` | Password protecting the PFX |

On Windows PowerShell, create the Base64 value without printing it:

~~~powershell
[Convert]::ToBase64String(
    [IO.File]::ReadAllBytes('C:\secure\schunkops-codesign.pfx')
) | Set-Clipboard
~~~

Never commit the PFX, API key, password, or Base64 value.

## Release process

1. Update `ModuleVersion` and `ReleaseNotes` in
   `module/SchunkOps/SchunkOps.psd1`.
2. Update `CHANGELOG.md`.
3. Merge only after **Validate SchunkOps** is green.
4. Create and push an exact matching tag such as `v1.0.0`.
5. Approve the protected `powershell-gallery` environment deployment.
6. Verify the published package:

~~~powershell
Find-Module SchunkOps
Install-Module SchunkOps -Scope CurrentUser
Get-Command -Module SchunkOps
Get-AuthenticodeSignature (Get-Module SchunkOps -ListAvailable).Path
~~~

The release workflow rejects mismatched tags, failed tests, analyzer errors,
missing secrets, and unsuccessful Authenticode signatures.
