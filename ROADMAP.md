# SchunkOps Roadmap

SchunkOps is becoming a practical, community-tested Windows operations module
that an administrator can trust during normal maintenance and the first minutes
of an incident.

## Release 1.0 — trustworthy foundation

- [x] Stable David-branded command names
- [x] Windows PowerShell 5.1 compatibility
- [x] Pester and PSScriptAnalyzer quality gates
- [x] Discoverable command and about-topic help
- [x] Integrity-hashed incident evidence bundles
- [x] Protected Authenticode and Gallery release workflow
- [ ] Complete maintainer code-signing setup
- [ ] Publish the first PowerShell Gallery release

## Release 1.1 — fleet operations

- [ ] Consistent ComputerName and CimSession support
- [ ] Pipeline input for remote server lists
- [ ] Throttled parallel collection with explicit timeouts
- [ ] Credential-free examples using existing administrative context
- [ ] Fleet summary objects suitable for CSV and HTML reporting

## Release 1.2 — baselines and reporting

- [ ] System baseline creation and comparison
- [ ] Human-readable HTML incident summary
- [ ] Collector duration and data-quality metrics
- [ ] Optional redaction helpers for common sensitive fields
- [ ] JSON schema documentation and compatibility tests

## Good first contributions

- Add realistic, sanitized examples to command help.
- Add Pester tests for parameter validation and failure behavior.
- Test commands on supported Windows client and server versions.
- Improve accessibility and clarity in documentation.
- Propose an object-first collector for a common Windows operations problem.

Open a feature request before building a large command so its scope, safety,
permissions, output shape, and test strategy can be agreed upon.

## Design rules

Every SchunkOps command should:

1. Use safe and read-only defaults.
2. Return objects rather than presentation-only text.
3. Bound network waits and event queries.
4. Make partial failure visible.
5. Avoid credentials, private addresses, and environment-specific assumptions.
6. Include help, examples, authorship, and tests.
7. Be understandable by the next engineer.

Maintained by [David Maksim Schunk](https://github.com/dschunk).
