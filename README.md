# rules_odin

[![Check](https://github.com/clappingmonkey/rules_odin/actions/workflows/check.yaml/badge.svg)](https://github.com/clappingmonkey/rules_odin/actions/workflows/check.yaml)
[![OpenSSF Scorecard](https://api.securityscorecards.dev/v1/github.com/clappingmonkey/rules_odin/badge)](https://securityscorecards.dev/viewer/?uri=github.com/clappingmonkey/rules_odin)

Bazel rules for the [Odin programming language](https://odin-lang.org/).

## Overview

`rules_odin` provides hermetic Bazel build rules for Odin, a data-oriented systems programming language. The ruleset automatically downloads and manages the Odin compiler toolchain, requiring no system-wide Odin installation.

## Features

- Hermetic Odin toolchain management (no system install required)
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

## Rules

### `odin_binary`

Compiles an Odin package (directory of `.odin` files) into an executable.

| Attribute              | Type        | Default      | Description                                     |
| ---------------------- | ----------- | ------------ | ----------------------------------------------- |
| `srcs`                 | label_list  | **required** | Odin source files (must share a package)        |
| `deps`                 | label_list  | `[]`         | `odin_library` targets to import as collections |
| `optimization`         | string      | `"none"`     | One of: none, minimal, speed, size, aggressive  |
| `debug`                | bool        | `True`       | Include debug symbols                           |
| `defines`              | string_dict | `{}`         | Compile-time `-define:` values                  |
| `extra_compiler_flags` | string_list | `[]`         | Additional flags passed to `odin build`         |
| `vet`                  | bool        | `False`      | Enable `-vet` checks                            |

### `odin_library`

Groups Odin source files into a library that can be imported by `odin_binary` targets via Odin's collection system. The library's target name becomes the collection name.

| Attribute | Type       | Default      | Description                              |
| --------- | ---------- | ------------ | ---------------------------------------- |
| `srcs`    | label_list | **required** | Odin source files (must share a package) |

### `odin_test`

Compiles and runs Odin tests using the built-in test runner. Source files must contain at least one procedure annotated with `@(test)`. The test binary is compiled at build time (cacheable) and executed by Bazel's test runner.

| Attribute              | Type        | Default      | Description                                     |
| ---------------------- | ----------- | ------------ | ----------------------------------------------- |
| `srcs`                 | label_list  | **required** | Odin source files with `@(test)` procedures     |
| `deps`                 | label_list  | `[]`         | `odin_library` targets to import as collections |
| `optimization`         | string      | `"none"`     | One of: none, minimal, speed, size, aggressive  |
| `debug`                | bool        | `True`       | Include debug symbols                           |
| `defines`              | string_dict | `{}`         | Compile-time `-define:` values (see below)      |
| `extra_compiler_flags` | string_list | `[]`         | Additional flags passed to the Odin compiler    |
| `vet`                  | bool        | `False`      | Enable `-vet` checks                            |

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
- **Linux**: `clang` or `gcc` (for linking)
- **macOS**: Xcode Command Line Tools
- **Windows**: MSVC "Desktop development with C++" workload

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

Apache License 2.0 - see [LICENSE](LICENSE).
