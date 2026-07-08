"""Implementation of the odin_binary rule."""

load("//odin/private:common.bzl", "get_package_dir")
load("//odin/private:library.bzl", "OdinLibraryInfo")

def _odin_binary_impl(ctx):
    toolchain = ctx.toolchains["@rules_odin//odin:toolchain_type"]
    odin_info = toolchain.odininfo

    # Determine output binary name
    if ctx.attr.out:
        out_name = ctx.attr.out
    else:
        out_name = ctx.label.name + odin_info.binary_ext

    out = ctx.actions.declare_file(out_name)

    srcs = ctx.files.srcs
    pkg_dir = get_package_dir(srcs, "odin_binary")

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

    # Collect library deps: add their source files to inputs and
    # register each as a collection for Odin's import resolution.
    dep_srcs = []
    seen_collections = {}
    for dep in ctx.attr.deps:
        lib_info = dep[OdinLibraryInfo]
        name = lib_info.collection_name
        if name in seen_collections:
            fail(
                "odin_binary '{}' has duplicate collection name '{}' ".format(
                    ctx.label.name,
                    name,
                ) + "from deps '{}' and '{}'. ".format(
                    seen_collections[name],
                    dep.label,
                ) + "Odin collection names must be unique within a binary.",
            )
        seen_collections[name] = dep.label
        dep_srcs.extend(lib_info.srcs.to_list())
        args.add("-collection:{}={}".format(
            name,
            lib_info.collection_root,
        ))

    # Collect all inputs: sources + library dep srcs + entire SDK
    inputs = depset(
        direct = srcs + dep_srcs,
        transitive = [odin_info.all_files],
    )

    # Set ODIN_ROOT so the compiler finds core/, base/, vendor/.
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
        "deps": attr.label_list(
            doc = "Odin library targets (odin_library) to import as collections.",
            providers = [OdinLibraryInfo],
            default = [],
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
