## What changed

Describe the operational problem and the approach used to solve it.

## Safety and behavior

- [ ] Defaults are read-only or protected with ShouldProcess.
- [ ] Network operations have an explicit timeout.
- [ ] Event and inventory queries have reasonable bounds.
- [ ] Partial failures are visible to the caller.
- [ ] No credentials, tokens, private hostnames, addresses, or proprietary data are included.

## PowerShell quality

- [ ] The command returns structured objects where practical.
- [ ] Parameters include validation and clear defaults.
- [ ] Comment-based help includes synopsis, description, parameters, examples, output, and notes.
- [ ] Pester tests cover the primary behavior.
- [ ] PSScriptAnalyzer reports no error-severity findings.
- [ ] Windows PowerShell 5.1 compatibility was considered.

## Verification

List the Windows versions and PowerShell editions used for testing. Include
sanitized sample output or explain why the command could not be executed in a
public test environment.

## Documentation

- [ ] README or field-guide documentation is updated.
- [ ] CHANGELOG entry is included.
- [ ] New privileges or Windows feature requirements are documented.
