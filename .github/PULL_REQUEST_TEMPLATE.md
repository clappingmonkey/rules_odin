<!--
  Thank you for contributing to rules_odin!

  PR title format (conventional commits — used as the squash-merge commit message):
    <type>(<scope>): <short description>

  Types: feat, fix, docs, refactor, test, chore, ci, build
  Scope (optional): rule name, toolchain, bzlmod, e2e, etc.

  Examples:
    feat(odin_binary): add cross-compilation support
    fix(toolchain): resolve odin compiler path on Windows
    docs: update MODULE.bazel usage example
    ci: bump Bazel version in test matrix

  Breaking changes: use feat! or fix! and fill out the BREAKING CHANGE section below.

  Delete this comment block before submitting.
-->

## What does this PR do?

<!-- Why is this change needed? What problem does it solve? Link to an issue if applicable. -->

## How was it tested?

<!--
  - Existing tests pass? (CI will verify)
  - New tests added? Which ones?
  - Manually tested? On which OS / Bazel version?
-->

## Checklist

- [ ] PR title follows [conventional commit](https://www.conventionalcommits.org/) format
- [ ] CI passes (`check.yaml` — lint + test matrix)
- [ ] Tests added or updated for new/changed behavior
- [ ] Documentation updated if user-facing (docstrings, README, CONTRIBUTING.md)
- [ ] No breaking changes (or BREAKING CHANGE section below is filled out)

<!--
## BREAKING CHANGE

Describe what breaks and how users should migrate:
- Before: ...
- After: ...
-->
