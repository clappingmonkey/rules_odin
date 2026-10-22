# Contributing to rules_odin

## Development Setup

1. Install [Bazelisk](https://github.com/bazelbuild/bazelisk) (manages Bazel versions automatically)
2. Clone this repository
3. Run `bazel build //...` to verify everything builds

## Project Structure

```
rules_odin/
├── odin/                  # Main Starlark rules
│   ├── defs.bzl           # Public API
│   ├── toolchain.bzl      # Toolchain provider + rule
│   ├── extensions.bzl     # bzlmod module extension
│   ├── repositories.bzl   # Repository rules
│   └── private/           # Internal implementation
├── e2e/smoke/             # End-to-end integration test
└── .github/workflows/     # CI pipelines
```

## Running Tests

```bash
# Build everything
bazel build //...

# Run the smoke test
cd e2e/smoke && bazel build //...
```

## Adding a New Odin Version

1. Get the release SHA256 hashes from the GitHub API:
   ```bash
   curl -s https://api.github.com/repos/odin-lang/Odin/releases/latest | jq '.assets[] | {name, digest}'
   ```
2. Add entries to `odin/private/versions.bzl`
3. Test with the e2e smoke workspace
4. Submit a PR

## Code Style

- Use [Buildifier](https://github.com/bazelbuild/buildtools) for formatting `.bzl` and `BUILD` files
- Follow the [Bazel Starlark style guide](https://bazel.build/rules/deploying)

## Releasing

Patch and minor releases are automated. The [`Tag`](.github/workflows/tag.yaml)
workflow runs on the 1st and 16th of each month (or on manual dispatch), computes
the next version from the [Conventional Commits](https://www.conventionalcommits.org/)
since the last tag, pushes the tag, and runs the release. The release creates a
GitHub Release and submits a BCR PR.

To preview the next version without tagging, run the workflow with `dry_run`:

```bash
gh workflow run tag.yaml --ref main -f dry_run=true
```

Only `fix:` (patch) and `feat:` (minor) commits trigger a release. Other types
such as `docs:`, `ci:`, `chore:` or `refactor:` do not.

### Major releases

A breaking change requires a major bump. The versioning tool treats only these
as breaking: `feat!:`, `fix!:`, or the text `BREAKING CHANGE: ` (with a space,
not a hyphen). Other breaking forms, such as `refactor!:` or
`BREAKING-CHANGE:`, are not detected. Mark breaking changes with one of the
three supported forms.

`BREAKING CHANGE: ` is matched **anywhere** in the commit message, not only in
the footer. Squash-merge commits include the PR description, so do not write
that text in a PR description unless the change is breaking. Prefer `!` in the
PR title (for example `feat!: ...`) to mark a breaking change.

The `Tag` workflow never pushes a major tag. On a major bump it fails, and the
run summary shows the computed version, the commit SHA, and a best-effort list
of the commits that look breaking, with the matching lines from their
messages. Scheduled runs and dispatches keep failing until a maintainer pushes
a release tag on that commit by hand, with their own credentials (a tag pushed
by `GITHUB_TOKEN` would not trigger the release). The summary prints the exact
commands. For an intended breaking change:

```bash
git fetch origin
git -c tag.gpgSign=false tag vX.0.0 <commit-sha-from-the-run-summary>
git push origin refs/tags/vX.0.0
```

If the listed commits show the bump is accidental, push the intended version
instead: the next patch after the latest release tag (the summary prints it),
or the next minor if there are `feat:` commits. The version must be higher
than every existing release tag.

Either way:

- The tag must be **lightweight** (not annotated or signed) and on the commit
  from the summary. The versioning tool ignores annotated tags, so the bump
  would not be cleared. `-c tag.gpgSign=false` prevents signing from your git
  config.
- Pushing the tag triggers [`release.yaml`](.github/workflows/release.yaml),
  which creates the GitHub Release and submits a BCR PR. Version tags cannot be
  deleted or moved, so double-check the commit and version first.
- Later runs count only the commits after this tag, so an accidental breaking
  commit no longer forces a major bump.
