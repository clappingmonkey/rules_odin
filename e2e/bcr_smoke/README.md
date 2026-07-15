# BCR Test Module

This directory is the `bcr_test_module` referenced by
[`.bcr/presubmit.yml`](../../.bcr/presubmit.yml). The Bazel Central Registry
(BCR) runs it during presubmit to validate each published `rules_odin` version.

## How BCR uses it

During presubmit, BCR extracts the `rules_odin` source at the released tag and
runs this module (already present at `e2e/bcr_smoke/` in the archive) from
within that tree. This module binds `rules_odin` back to the extracted source
with:

```starlark
bazel_dep(name = "rules_odin")
local_path_override(
    module_name = "rules_odin",
    path = "../..",
)
```

The `bazel_dep` intentionally declares **no version**: the `local_path_override`
resolves `rules_odin` to the exact source being published, replacing registry
resolution entirely. This follows the idiomatic BCR test module pattern and
avoids per-release edits.

## Relationship to `e2e/smoke/`

`e2e/smoke/` is the canonical local development smoke test and also uses
`local_path_override(path = "../..")`. This module mirrors its sources but is
driven by BCR presubmit rather than the repository's own CI.
