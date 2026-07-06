"""Implementation of the odin_binary rule."""

def _get_package_dir(srcs):
    """Determine the package directory from source files.

    All source files must reside in the same directory (Odin compiles
    entire directories as a single package).

    Returns:
        The path to the package directory relative to the exec root.
    """
    if not srcs:
        fail("odin_binary requires at least one source file in 'srcs'.")

    dirs = {}
    for src in srcs:
        dirs[src.dirname] = True

    if len(dirs) > 1:
        fail(
            "All 'srcs' in an odin_binary must be in the same directory " +
            "(Odin compiles entire directories as a package). " +
            "Found files in: " + ", ".join(sorted(dirs.keys())),
        )

    return srcs[0].dirname

def _odin_binary_impl(ctx):
    toolchain = ctx.toolchains["@rules_odin//odin:toolchain_type"]
    odin_info = toolchain.odininfo

    # Determine output binary name
    if ctx.attr.out:
        out_name = ctx.attr.out
    else:
        out_name = ctx.label.name

    out = ctx.actions.declare_file(out_name)

    srcs = ctx.files.srcs
    pkg_dir = _get_package_dir(srcs)

    # Build the compiler arguments
    args = ctx.actions.args()
    args.add("build")
    args.add(pkg_dir)
    args.add("-out:" + out.path)
    args.add("-build-mode:exe")

    # Optimization level
    if ctx.attr.optimization != "none":
        args.add("-o:" + ctx.attr.optimization)

    # Debug symbols
    if ctx.attr.debug:
        args.add("-debug")

    # Vet checks
    if ctx.attr.vet:
        args.add("-vet")

    # Compile-time defines
    for key, value in ctx.attr.defines.items():
        args.add("-define:{}={}".format(key, value))

    # Extra compiler flags (pass-through)
    for flag in ctx.attr.extra_compiler_flags:
        args.add(flag)

    # Collect all inputs: sources + entire SDK (for core/base/vendor imports)
    inputs = depset(
        direct = srcs,
        transitive = [odin_info.all_files],
    )

    # Set ODIN_ROOT so the compiler finds core/, base/, vendor/.
    # ODIN_ROOT must point to the directory containing the compiler binary,
    # which is also where core/, base/, vendor/ are located after extraction.
    # We derive it from the compiler file's dirname (works inside the sandbox).
    env = {}
    if odin_info.compiler:
        env["ODIN_ROOT"] = odin_info.compiler.dirname

    ctx.actions.run(
        executable = odin_info.compiler,
        arguments = [args],
        inputs = inputs,
        outputs = [out],
        env = env,
        mnemonic = "OdinBuild",
        progress_message = "Compiling Odin binary %{label}",
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(
            files = depset([out]),
            executable = out,
            runfiles = ctx.runfiles(files = [out]),
        ),
    ]

odin_binary = rule(
    implementation = _odin_binary_impl,
    doc = "Compiles an Odin package into an executable binary.",
    attrs = {
        "srcs": attr.label_list(
            doc = "Odin source files. All files must be in the same directory (one Odin package).",
            allow_files = [".odin"],
            mandatory = True,
        ),
        "out": attr.string(
            doc = "Output binary name. Defaults to the rule name.",
            default = "",
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
            doc = "Compile-time constant definitions passed as -define:KEY=VALUE.",
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
    executable = True,
    toolchains = ["@rules_odin//odin:toolchain_type"],
)
