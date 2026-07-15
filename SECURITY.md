# Security Policy

Thank you for helping keep `rules_odin` and its users safe.

## Supported Versions

`rules_odin` is a solo-maintained project. Security fixes are provided only for
the most recent tagged release. If you are affected by a vulnerability, the
recommended remediation is to upgrade to the latest release.

| Version               | Supported          |
| --------------------- | ------------------ |
| Latest tagged release | :white_check_mark: |
| Older releases        | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues,
discussions, or pull requests.**

Report vulnerabilities privately using GitHub's Private Vulnerability Reporting:

- https://github.com/clappingmonkey/rules_odin/security/advisories/new

If you are unable to use that form, email **clappingmonkey33@gmail.com**
instead.

Please include as much of the following as you can, so the report can be
triaged quickly:

- The affected `rules_odin` version (or commit SHA).
- A minimal `BUILD.bazel` / `MODULE.bazel` reproduction, or clear reproduction
  steps.
- An assessment of the impact (what an attacker could achieve).
- Any known mitigations or workarounds.

## Response Expectations

This is a best-effort, solo-maintained project. That said, I aim to:

- **Acknowledge** your report within **5 business days**.
- Provide an **initial assessment** within **14 days**.
- Release a **fix or mitigation** within **90 days** for confirmed
  vulnerabilities, coordinating the disclosure timeline with you.

If a report is declined as out of scope (see below), you will receive a brief
explanation and, where possible, a pointer to the correct project.

## Coordinated Disclosure

`rules_odin` follows coordinated vulnerability disclosure. The reporter and
maintainer agree on a public disclosure date once a fix or mitigation is
available, targeting **90 days** from the initial report. Reporters are
credited in the resulting advisory unless they request anonymity.

## Scope

Because `rules_odin` ships only Starlark and fetches the Odin SDK from upstream
using a pinned `sha256`, the security surface is primarily the integrity of the
ruleset and its release pipeline.

**In scope** — please report:

- Malicious or compromised changes to the Starlark rules (`odin/**/*.bzl`).
- GitHub Actions workflow issues (script injection, privilege escalation,
  `pull_request_target` misuse) or compromise of the release / BCR publish
  pipeline (including handling of `BCR_PUBLISH_TOKEN`).
- Incorrect or forgeable SDK integrity hashes in
  `odin/private/versions.bzl` that could allow substitution of a malicious SDK
  archive.
- Rule or toolchain action bugs that leak host environment data or enable
  arbitrary code execution from crafted build inputs.

**Out of scope** — please report these to the appropriate upstream project:

- Vulnerabilities in the **Odin compiler or language runtime** →
  https://github.com/odin-lang/Odin
- Vulnerabilities in **Bazel** itself →
  https://github.com/bazelbuild/bazel/security/policy
- Behavior of **user-authored `.odin` source code**.
- Non-security correctness bugs (wrong flags, build failures) — please open a
  regular [GitHub issue](https://github.com/clappingmonkey/rules_odin/issues)
  instead.
