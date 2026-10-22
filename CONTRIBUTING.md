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
as breaking: `feat!:`, `fix!:`, or a `BREAKING CHANGE: ` footer (with a space,
not a hyphen). Other breaking forms, such as `refactor!:` or
`BREAKING-CHANGE:`, are not detected. Mark breaking changes with one of the
three supported forms.

The `Tag` workflow never pushes a major tag. It fails and prints the version
and the commit SHA it computed. Every later run fails the same way until a
maintainer tags that commit by hand with their own credentials. A tag pushed
by `GITHUB_TOKEN` would not trigger the release:

```bash
git fetch origin
git tag vX.0.0 <commit-sha-from-the-run-summary>
git push origin refs/tags/vX.0.0
```

Version tags cannot be deleted or moved, so double-check the commit before
pushing. Pushing the tag triggers
[`release.yaml`](.github/workflows/release.yaml), which creates the GitHub
Release and submits a BCR PR.
