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

Releases are cut by tagging a commit:

```bash
git tag v0.x.0
git push origin v0.x.0
```

The CI will automatically create a GitHub Release and submit a BCR PR.
