# Publishing SchunkOps

SchunkOps uses GitHub Actions for release validation, artifact packaging, GitHub Releases, and PowerShell Gallery publication. Release secrets never belong in the repository.

## What the pipeline does

The `Publish SchunkOps` workflow:

1. resolves the semantic version from a `v*` tag, `release/v*` branch, or manual workflow input;
2. verifies that the release version exactly matches `ModuleVersion` in `SchunkOps.psd1`;
3. runs Pester release tests and PSScriptAnalyzer error rules;
4. builds a versioned ZIP and SHA-256 checksum;
5. creates or updates the matching GitHub Release;
6. publishes the module to PowerShell Gallery when a Gallery API key is configured;
7. verifies that the exact version is visible in the Gallery.

Gallery publication is idempotent: if the requested version is already present, the publish step is skipped and verification continues.

## One-time PowerShell Gallery setup

PowerShell Gallery requires a registered publisher account and a NuGet API key. The API key is the only secret required for Gallery publication.

1. Sign in to PowerShell Gallery and complete the one-time publisher registration.
2. From the account page, obtain/reset the NuGet API key.
3. In GitHub, open the `windows-it-toolkit` repository.
4. Create or use the environment named `powershell-gallery`.
5. Add an environment secret named `PSGALLERY_API_KEY` containing the Gallery API key.
6. Optionally require manual approval for deployments to that environment.

Never paste the API key into source code, an issue, a pull request, CI logs, or public chat.

## Optional Authenticode signing

Microsoft recommends code signing for high-quality Gallery packages, but it is separate from the Gallery API key requirement. SchunkOps can publish without Authenticode signing while retaining CI validation and SHA-256 release artifacts.

To enable signing, add both environment secrets:

| Secret | Value |
|---|---|
| `CODESIGN_PFX_BASE64` | Base64 text of a password-protected code-signing PFX |
| `CODESIGN_PFX_PASSWORD` | Password protecting that PFX |

Both signing secrets must be configured together. If neither is configured, the workflow publishes the CI-validated module unsigned. If only one is configured, publication fails rather than silently using a partial signing configuration.

Create the Base64 value locally without printing it:

```powershell
[Convert]::ToBase64String(
    [IO.File]::ReadAllBytes('C:\secure\schunkops-codesign.pfx')
) | Set-Clipboard
```

## Release process

1. Update `ModuleVersion` and `ReleaseNotes` in `module/SchunkOps/SchunkOps.psd1`.
2. Update `CHANGELOG.md` and `docs/releases/v<version>.md`.
3. Merge only after **Validate SchunkOps** and the repository PowerShell validation are green.
4. Create a release branch such as `release/v1.2.0`, push a matching `v1.2.0` tag, or run the workflow manually with version `1.2.0`.
5. The GitHub Release is built independently of Gallery credentials.
6. The `publish-gallery` job then publishes and verifies the module when `PSGALLERY_API_KEY` is available.
7. If Gallery setup was missing, add the environment secret and rerun only the failed Gallery job.

## Verify a published version

```powershell
Find-Module SchunkOps -RequiredVersion 1.2.0
Install-Module SchunkOps -RequiredVersion 1.2.0 -Scope CurrentUser
Import-Module SchunkOps
Get-Command -Module SchunkOps
```

If Authenticode signing is configured:

```powershell
Get-AuthenticodeSignature (Get-Module SchunkOps -ListAvailable).Path
```

## Release integrity

Every GitHub release includes a versioned ZIP and SHA-256 checksum. CI must pass before those assets are created. The release workflow has write permission only for repository release content; the PowerShell Gallery credential is scoped to the protected `powershell-gallery` environment.
