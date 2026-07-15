# BCR Smoke Test Workspace

This workspace validates `rules_odin` in the Bazel Central Registry (BCR) CI.

Unlike `e2e/smoke/` which uses `local_path_override(path = "../..")`, this
workspace consumes `rules_odin` purely via `bazel_dep(name = "rules_odin",
version = "0.1.0")` — matching the real BCR user experience.

The `e2e/smoke/` workspace remains the canonical local development test;
this workspace mirrors its sources but is exercised by BCR presubmit CI
(see `.bcr/presubmit.yml`).
