# rules_odin

Bazel rules for the [Odin programming language](https://odin-lang.org/).

## Overview

`rules_odin` provides hermetic Bazel build rules for Odin, a data-oriented systems programming language. The ruleset automatically downloads and manages the Odin compiler toolchain, requiring no system-wide Odin installation.

## Features

- Hermetic Odin toolchain management (no system install required)
- bzlmod-first (no WORKSPACE file needed)
- Multi-platform support: Linux (x86-64, ARM64), macOS (x86-64, ARM64), Windows (x86-64)
- Bazel 7.x and 8.x compatible

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
load("@rules_odin//odin:defs.bzl", "odin_binary")

odin_binary(
    name = "hello",
    srcs = glob(["*.odin"]),
)
```

## Rules

### `odin_binary`

Compiles an Odin package (directory of `.odin` files) into an executable.

| Attribute              | Type          | Default      | Description                              |
| ---------------------- | ------------- | ------------ | ---------------------------------------- |
| `srcs`                 | label_list    | **required** | Odin source files (must share a package) |
| `optimization`         | string        | `"none"`     | One of: none, minimal, speed, size, aggressive |
| `debug`                | bool          | `True`       | Include debug symbols                    |
| `defines`              | string_dict   | `{}`         | Compile-time `-define:` values           |
| `extra_compiler_flags` | string_list   | `[]`         | Additional flags passed to `odin build`  |
| `vet`                  | bool          | `False`      | Enable `-vet` checks                     |

## Supported Odin Versions

| Version      | Status    |
| ------------ | --------- |
| dev-2026-06  | Supported |
| dev-2026-05  | Supported |

## Requirements

- Bazel 7.x or 8.x
- **Linux**: `clang` or `gcc` (for linking)
- **macOS**: Xcode Command Line Tools
- **Windows**: MSVC "Desktop development with C++" workload

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

Apache License 2.0 - see [LICENSE](LICENSE).
