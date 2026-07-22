# Compatibility

Supported version matrix for `rules_odin`.

## Bazel Versions

| Bazel Version | Status    | Notes                    |
| ------------- | --------- | ------------------------ |
| 9.x (9.1.1)   | Supported | Latest, recommended      |
| 8.x (8.7.0)   | Supported | LTS, used for local dev  |
| 7.x (7.7.1)   | Supported | Will be dropped when EOL |

## Odin Compiler Versions

| Odin Version | Status    | Notes                     |
| ------------ | --------- | ------------------------- |
| dev-2026-06  | Supported | Default toolchain version |
| dev-2026-05  | Supported |                           |

## Platforms

| Platform         | Status    | CI Tested | Notes                                          |
| ---------------- | --------- | --------- | ---------------------------------------------- |
| Linux (x86_64)   | Supported | Yes       | ubuntu-24.04                                   |
| Linux (arm64)    | Supported | Yes       | ubuntu-24.04-arm                               |
| macOS (arm64)    | Supported | Yes       | macos-latest (Apple Silicon)                   |
| macOS (x86_64)   | Untested  | No        | Toolchain entry exists, no CI runner available |
| Windows (x86_64) | Supported | Yes       | windows-latest                                 |

## Build System

| System                | Status        | Notes                |
| --------------------- | ------------- | -------------------- |
| bzlmod (MODULE.bazel) | Supported     | Primary, recommended |
| WORKSPACE             | Not supported |                      |

## Host Requirements

rules_odin downloads the Odin compiler hermetically, but by default the
**linker** must be available on the host:

| Platform | Required Host Tool                                  |
| -------- | --------------------------------------------------- |
| Linux    | `clang` (via system package manager)                |
| macOS    | Xcode Command Line Tools (`xcode-select --install`) |
| Windows  | MSVC Build Tools (Visual Studio)                    |

On **Linux only**, this is opt-in rather than mandatory: setting
`--@rules_odin//odin:hermetic_linker=true` and supplying a bring-your-own
`toolchains_llvm` clang+lld and pinned sysroot (via the `hermetic_clang`,
`hermetic_toolchain_files`, and `hermetic_sysroot` attrs on `odin_binary`/`odin_test`)
removes the host `clang`/`gcc` requirement entirely. macOS and Windows always
require the host toolchain — their SDKs/libraries are not redistributable. See
[README.md § Hermetic Linux linking](README.md#hermetic-linux-linking) for
setup details.
