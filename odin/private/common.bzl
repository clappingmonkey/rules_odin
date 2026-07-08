"""Shared helpers and providers for rules_odin."""

OdinLibraryInfo = provider(
    doc = "Information about an Odin library (source aggregation for collection imports).",
    fields = {
        "srcs": "depset: Odin source files for this library.",
        "collection_name": "String: Name used in `-collection:<name>=<root>` (the label name).",
        "collection_root": "String: Parent directory of the package directory, passed as the collection root path.",
        "pkg_dir": "String: Package directory path (dirname of the source files).",
    },
)

def get_package_dir(srcs, rule_name):
    """Determine the package directory from source files.

    All source files must reside in the same directory (Odin compiles
    entire directories as a single package).

    Args:
        srcs: List of File objects (ctx.files.srcs).
        rule_name: Name of the rule (for error messages).

    Returns:
        The path to the package directory relative to the exec root.
    """
    if not srcs:
        fail("{} requires at least one source file in 'srcs'.".format(rule_name))

    dirs = {}
    for src in srcs:
        dirs[src.dirname] = True

    if len(dirs) > 1:
        fail(
            "All 'srcs' in an {} must be in the same directory ".format(rule_name) +
            "(Odin compiles entire directories as a package). " +
            "Found files in: " + ", ".join(sorted(dirs.keys())),
        )

    return srcs[0].dirname

def compile_odin_binary(ctx, srcs, build_mode, out_file, extra_defines = {}):
    """Compile Odin sources into a binary.

    Shared compilation logic for odin_binary and odin_test rules.
    Handles toolchain resolution, dependency collection, compiler
    argument assembly, and action registration.

    Args:
        ctx: Rule context. Must resolve toolchain
            "@rules_odin//odin:toolchain_type" and have attrs: deps,
            optimization, debug, vet, defines, extra_compiler_flags.
        srcs: List of source File objects (ctx.files.srcs).
        build_mode: Odin build mode string ("exe" or "test").
        out_file: Declared output File for the compiled binary.
        extra_defines: Dict of additional -define:KEY=VALUE pairs merged
            with ctx.attr.defines. User defines take precedence over
            extra_defines on key collision.

    Returns:
        DefaultInfo provider with the compiled binary.
    """
    toolchain = ctx.toolchains["@rules_odin//odin:toolchain_type"]
    odin_info = toolchain.odininfo

    rule_name = "odin_test" if build_mode == "test" else "odin_binary"
    pkg_dir = get_package_dir(srcs, rule_name)

    # Build the compiler arguments.
    args = ctx.actions.args()
    args.add("build")
    args.add(pkg_dir)
    args.add("-out:" + out_file.path)
    args.add("-build-mode:" + build_mode)

    # Optimization level.
    if ctx.attr.optimization != "none":
        args.add("-o:" + ctx.attr.optimization)

    # Debug symbols.
    if ctx.attr.debug:
        args.add("-debug")

    # Vet checks.
    if ctx.attr.vet:
        args.add("-vet")

    # Compile-time defines: merge extra_defines (lower priority) with
    # user-supplied defines (higher priority).
    merged_defines = dict(extra_defines)
    merged_defines.update(ctx.attr.defines)
    for key, value in merged_defines.items():
        args.add("-define:{}={}".format(key, value))

    # Extra compiler flags (pass-through).
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
                "{} '{}' has duplicate collection name '{}' ".format(
                    rule_name,
                    ctx.label.name,
                    name,
                ) + "from deps '{}' and '{}'. ".format(
                    seen_collections[name],
                    dep.label,
                ) + "Odin collection names must be unique within a target.",
            )
        seen_collections[name] = dep.label
        dep_srcs.extend(lib_info.srcs.to_list())
        args.add("-collection:{}={}".format(
            name,
            lib_info.collection_root,
        ))

    # Collect all inputs: sources + library dep srcs + entire SDK.
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
        outputs = [out_file],
        env = env,
        mnemonic = "OdinBuild" if build_mode == "exe" else "OdinTest",
        progress_message = "Compiling Odin {} %{{label}}".format(
            "binary" if build_mode == "exe" else "test",
        ),
        use_default_shell_env = True,
    )

    return DefaultInfo(
        files = depset([out_file]),
        executable = out_file,
        runfiles = ctx.runfiles(files = [out_file]),
    )
