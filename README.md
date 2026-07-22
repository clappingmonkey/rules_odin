# rules_odin

[![Check](https://github.com/clappingmonkey/rules_odin/actions/workflows/check.yaml/badge.svg)](https://github.com/clappingmonkey/rules_odin/actions/workflows/check.yaml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/v1/github.com/clappingmonkey/rules_odin/badge)](https://securityscorecards.dev/viewer/?uri=github.com/clappingmonkey/rules_odin)

Bazel rules for the [Odin programming language](https://odin-lang.org/).

## Overview

`rules_odin` provides Bazel build rules for Odin, a data-oriented systems programming language. The ruleset automatically downloads and manages the Odin compiler toolchain hermetically, requiring no system-wide Odin installation. Linking is host-based by default; Linux additionally supports opt-in hermetic linking (see [Hermetic Linux linking](#hermetic-linux-linking)).

## Features

- Hermetic Odin toolchain management (no system install required)
- Opt-in hermetic Linux linking (bring-your-own clang+lld+sysroot)
- `odin_binary` rule for compiling executables
- `odin_library` rule for sharing packages via collection imports
- `odin_test` rule for running `@(test)`-annotated Odin procedures
- bzlmod-first (no WORKSPACE file needed)
- Multi-platform support: Linux (x86-64, ARM64), macOS (x86-64, ARM64), Windows (x86-64)
- Bazel 7.x, 8.x, and 9.x compatible

## Quick Start

Add to your `MODULE.bazel`:

```starlark
bazel_dep(name = "rules_odin", version = "0.1.0")

odin = use_extension("@rules_odin//odin:extensions.bzl", "odin")
odin.toolchain(odin_version = "dev-2026-06")
use_repo(odin, "odin_toolchains")

register_toolchains("@odin_toolchains//:all")
```

Then in your `BUILD.bazel`:

```starlark
load("@rules_odin//odin:defs.bzl", "odin_binary", "odin_library", "odin_test")

odin_library(
    name = "greetings",
    srcs = glob(["lib/*.odin"]),
)

odin_binary(
    name = "hello",
    srcs = glob(["hello/*.odin"]),
    deps = [":greetings"],
)

odin_test(
    name = "greetings_test",
    srcs = glob(["tests/*.odin"]),
    deps = [":greetings"],
)
```

Import the library in your Odin code using the collection name (the `odin_library` target name) and the package directory name:

```odin
import greetings "greetings:lib"  // collection:name → lib/ directory
```

## Hermetic Linux linking

The Odin compiler itself is downloaded hermetically. Linking is a separate step: Odin's linker driver shells out to a linker, and by default that linker comes from the host (`clang` on Linux, Xcode Command Line Tools on macOS, MSVC on Windows).

On **Linux (x86_64 and aarch64) only**, `rules_odin` supports an opt-in mode that points the linker driver at a user-supplied ("bring your own") hermetic clang+lld and a pinned sysroot instead, so the link uses zero host clang/ld/libc.

macOS and Windows cannot be made hermetic this way — Apple's macOS SDK and Microsoft's MSVC libraries are not redistributable — so they always use the host toolchain. This is the same posture as `rules_go`, `rules_rust`, and `zig-cc`.

| Platform | Default            | Opt-in hermetic linking |
| -------- | ------------------ | ----------------------- |
| Linux    | Host `clang`/`gcc` | Yes (x86_64, aarch64)   |
| macOS    | Host Xcode CLT     | Not possible            |
| Windows  | Host MSVC          | Not possible            |

### Opting in

`rules_odin` does not depend on a C toolchain or sysroot itself — you bring your own. A fully-working reference workspace lives in [`e2e/hermetic/`](e2e/hermetic/).

1. Add a hermetic C toolchain and a pinned Linux sysroot to your `MODULE.bazel`:

   ```starlark
   bazel_dep(name = "toolchains_llvm", version = "1.8.0")

   llvm = use_extension("@toolchains_llvm//toolchain/extensions:llvm.bzl", "llvm")
   llvm.toolchain(
       name = "llvm_toolchain",
       llvm_version = "20.1.0",
   )
   llvm.sysroot(
       name = "llvm_toolchain",
       label = "@org_chromium_sysroot_linux_x64//sysroot",
       targets = ["linux-x86_64"],
   )
   llvm.sysroot(
       name = "llvm_toolchain",
       label = "@org_chromium_sysroot_linux_arm64//sysroot",
       targets = ["linux-aarch64"],
   )
   use_repo(llvm, "llvm_toolchain_llvm")

   sysroot = use_repo_rule("@toolchains_llvm//toolchain:sysroot.bzl", "sysroot")

   sysroot(
       name = "org_chromium_sysroot_linux_x64",
       sha256 = "84656a6df544ecef62169cfe3ab6e41bb4346a62d3ba2a045dc5a0a2ecea94a3",
       urls = ["https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/2202c161310ffde63729f29d27fe7bb24a0bc540/debian_stretch_amd64_sysroot.tar.xz"],
   )

   sysroot(
       name = "org_chromium_sysroot_linux_arm64",
       sha256 = "e39b700d8858d18868544c8c84922f6adfa8419f3f42471b92024ba38eff7aca",
       urls = ["https://commondatastorage.googleapis.com/chrome-linux-sysroot/toolchain/2202c161310ffde63729f29d27fe7bb24a0bc540/debian_stretch_arm64_sysroot.tar.xz"],
   )
   ```

2. Point the `hermetic_*` attrs on your `odin_binary`/`odin_test` targets at those labels:

   ```starlark
   odin_binary(
       name = "hello",
       srcs = glob(["hello/*.odin"]),
       hermetic_clang = "@llvm_toolchain_llvm//:bin/clang",
       hermetic_toolchain_files = "@llvm_toolchain_llvm//:bin",
       hermetic_sysroot = select({
           "@platforms//cpu:x86_64": "@org_chromium_sysroot_linux_x64//sysroot",
           "@platforms//cpu:aarch64": "@org_chromium_sysroot_linux_arm64//sysroot",
           "//conditions:default": None,
       }),
       deps = [":greetings"],
   )
   ```

3. Build with the flag enabled:

   ```bash
   bazel build //... --@rules_odin//odin:hermetic_linker=true
   ```

**Behavior notes:**

- The flag is inert on macOS and Windows — safe to set unconditionally across a multi-OS `.bazelrc` or CI matrix; non-Linux platforms stay on the host linker regardless.
- Activation is **per target**: a Linux target that doesn't set `hermetic_clang` stays on the host linker even when the flag is `true`. Only targets with the `hermetic_*` attrs set link hermetically.
- The sysroot must follow the Chromium `debian_stretch` GCC-6 multiarch layout (`usr/lib/gcc/<triple>/6`, `usr/lib/<triple>`, `lib/<triple>`); other sysroot families require ruleset changes.

## Rules

### `odin_binary`

Compiles an Odin package (directory of `.odin` files) into an executable.

| Attribute                  | Type        | Default      | Description                                                                       |
| -------------------------- | ----------- | ------------ | --------------------------------------------------------------------------------- |
| `srcs`                     | label_list  | **required** | Odin source files (must share a package)                                          |
| `deps`                     | label_list  | `[]`         | `odin_library` targets to import as collections                                   |
| `optimization`             | string      | `"none"`     | One of: none, minimal, speed, size, aggressive                                    |
| `debug`                    | bool        | `True`       | Include debug symbols                                                             |
| `defines`                  | string_dict | `{}`         | Compile-time `-define:` values                                                    |
| `extra_compiler_flags`     | string_list | `[]`         | Additional flags passed to `odin build`                                           |
| `vet`                      | bool        | `False`      | Enable `-vet` checks                                                              |
| `hermetic_clang`           | label       | `None`       | Linux-only: hermetic clang for [opt-in hermetic linking](#hermetic-linux-linking) |
| `hermetic_toolchain_files` | label       | `None`       | Linux-only: hermetic clang/lld toolchain files (bin dir)                          |
| `hermetic_sysroot`         | label       | `None`       | Linux-only: pinned sysroot for hermetic linking                                   |

### `odin_library`

Groups Odin source files into a library that can be imported by `odin_binary` targets via Odin's collection system. The library's target name becomes the collection name.

| Attribute | Type       | Default      | Description                              |
| --------- | ---------- | ------------ | ---------------------------------------- |
| `srcs`    | label_list | **required** | Odin source files (must share a package) |

### `odin_test`

Compiles and runs Odin tests using the built-in test runner. Source files must contain at least one procedure annotated with `@(test)`. The test binary is compiled at build time (cacheable) and executed by Bazel's test runner.

| Attribute                  | Type        | Default      | Description                                                                       |
| -------------------------- | ----------- | ------------ | --------------------------------------------------------------------------------- |
| `srcs`                     | label_list  | **required** | Odin source files with `@(test)` procedures                                       |
| `deps`                     | label_list  | `[]`         | `odin_library` targets to import as collections                                   |
| `optimization`             | string      | `"none"`     | One of: none, minimal, speed, size, aggressive                                    |
| `debug`                    | bool        | `True`       | Include debug symbols                                                             |
| `defines`                  | string_dict | `{}`         | Compile-time `-define:` values (see below)                                        |
| `extra_compiler_flags`     | string_list | `[]`         | Additional flags passed to the Odin compiler                                      |
| `vet`                      | bool        | `False`      | Enable `-vet` checks                                                              |
| `hermetic_clang`           | label       | `None`       | Linux-only: hermetic clang for [opt-in hermetic linking](#hermetic-linux-linking) |
| `hermetic_toolchain_files` | label       | `None`       | Linux-only: hermetic clang/lld toolchain files (bin dir)                          |
| `hermetic_sysroot`         | label       | `None`       | Linux-only: pinned sysroot for hermetic linking                                   |

**Test runner defines** (passed via `defines`):

| Key                            | Default    | Description                           |
| ------------------------------ | ---------- | ------------------------------------- |
| `ODIN_TEST_FANCY`              | `false`    | ANSI progress display (auto-disabled) |
| `ODIN_TEST_THREADS`            | `0` (auto) | Worker thread count                   |
| `ODIN_TEST_NAMES`              | —          | Comma-separated test filter           |
| `ODIN_TEST_RANDOM_SEED`        | random     | Fixed seed for reproducibility        |
| `ODIN_TEST_FAIL_ON_BAD_MEMORY` | `false`    | Treat memory leaks as failures        |
| `ODIN_TEST_LOG_LEVEL`          | `info`     | Minimum log level                     |

## Supported Odin Versions

| Version     | Status    |
| ----------- | --------- |
| dev-2026-06 | Supported |
| dev-2026-05 | Supported |

See [COMPATIBILITY.md](COMPATIBILITY.md) for the full version matrix.

## Requirements

- Bazel 7.x, 8.x, or 9.x
- **Linux**: `clang` or `gcc` (for linking) — or opt in to [hermetic linking](#hermetic-linux-linking) to avoid this requirement
- **macOS**: Xcode Command Line Tools
- **Windows**: MSVC "Desktop development with C++" workload

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

Apache License 2.0 - see [LICENSE](LICENSE).
