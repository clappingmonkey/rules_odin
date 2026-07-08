"""Implementation of the odin_test rule.

An odin_test compiles Odin source files containing @(test)-annotated
procedures into a test binary using `odin build -build-mode:test`.
The binary self-contains Odin's built-in test runner and is executed
by Bazel's test infrastructure.

Exit code 0 means all tests passed; non-zero means one or more failed.

Test runner configuration (threads, filtering, memory tracking, etc.)
is controlled via compile-time defines. The rule injects sensible CI
defaults that can be overridden by the user:
    - ODIN_TEST_FANCY=false  (disables ANSI animations)
"""

load("//odin/private:common.bzl", "OdinLibraryInfo", "compile_odin_binary")

# Default defines injected into every odin_test compilation.
# Users can override any of these via the `defines` attribute.
_TEST_DEFAULT_DEFINES = {
    "ODIN_TEST_FANCY": "false",
}

def _odin_test_impl(ctx):
    toolchain = ctx.toolchains["@rules_odin//odin:toolchain_type"]
    odin_info = toolchain.odininfo

    out_name = ctx.label.name + odin_info.binary_ext
    out = ctx.actions.declare_file(out_name)

    return [compile_odin_binary(
        ctx = ctx,
        srcs = ctx.files.srcs,
        build_mode = "test",
        out_file = out,
        extra_defines = _TEST_DEFAULT_DEFINES,
    )]

odin_test = rule(
    implementation = _odin_test_impl,
    doc = """Compiles and runs Odin tests using the built-in test runner.

Source files must contain at least one procedure annotated with @(test).
The test binary is compiled at build time (cacheable) and executed by
Bazel's test runner.

Test runner options are controlled via compile-time defines:
    - ODIN_TEST_THREADS: Number of worker threads (0 = auto)
    - ODIN_TEST_NAMES: Comma-separated test filter
    - ODIN_TEST_RANDOM_SEED: Fixed seed for reproducibility
    - ODIN_TEST_FANCY: ANSI progress display (default: false)
    - ODIN_TEST_FAIL_ON_BAD_MEMORY: Treat leaks as failures
    - ODIN_TEST_LOG_LEVEL: Minimum log level (debug/info/warning/error/fatal)

Example:
    load("@rules_odin//odin:defs.bzl", "odin_test")

    odin_test(
        name = "math_test",
        srcs = glob(["tests/*.odin"]),
        deps = [":mylib"],
    )
""",
    attrs = {
        "srcs": attr.label_list(
            doc = "Odin source files containing @(test) procedures. All files must be in the same directory.",
            allow_files = [".odin"],
            mandatory = True,
        ),
        "deps": attr.label_list(
            doc = "Odin library targets (odin_library) to import as collections.",
            providers = [OdinLibraryInfo],
            default = [],
        ),
        "optimization": attr.string(
            doc = "Optimization level passed to the Odin compiler.",
            default = "none",
            values = ["none", "minimal", "speed", "size", "aggressive"],
        ),
        "debug": attr.bool(
            doc = "Whether to include debug symbols (-debug flag).",
            default = True,
        ),
        "defines": attr.string_dict(
            doc = "Compile-time defines passed as -define:KEY=VALUE. Can override test runner defaults (e.g., ODIN_TEST_THREADS, ODIN_TEST_FANCY).",
            default = {},
        ),
        "extra_compiler_flags": attr.string_list(
            doc = "Additional flags passed directly to the Odin compiler.",
            default = [],
        ),
        "vet": attr.bool(
            doc = "Enable Odin vet checks (-vet flag).",
            default = False,
        ),
    },
    test = True,
    toolchains = ["@rules_odin//odin:toolchain_type"],
)
