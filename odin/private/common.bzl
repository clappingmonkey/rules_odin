"""Shared helpers and providers for rules_odin."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

OdinLibraryInfo = provider(
    doc = "Information about an Odin library (source aggregation for collection imports).",
    fields = {
        "srcs": "depset: Odin source files for this library.",
        "collection_name": "String: Name used in `-collection:<name>=<root>` (the label name).",
        "collection_root": "String: Parent directory of the package directory, passed as the collection root path.",
        "pkg_dir": "String: Package directory path (dirname of the source files).",
    },
)

# Debian multiarch triple per Bazel cpu, for the sysroot library search paths.
_LINUX_MULTIARCH = {
    "x86_64": "x86_64-linux-gnu",
    "aarch64": "aarch64-linux-gnu",
}

# GCC version directory inside the supported sysroot layout. Chromium's
# debian_stretch sysroots ship GCC 6 at usr/lib/gcc/<triple>/6. Other sysroot
# families (e.g. debian_bullseye/bookworm with GCC 10/12) use a different
# version dir and are not supported by _hermetic_linker_flags as written.
_SYSROOT_GCC_VERSION = "6"

# Attributes that enable opt-in hermetic Linux linking. All BYO label attrs
# default to None so non-hermetic targets are completely unaffected. The
# private attrs let the rule detect, in its implementation, whether
# --@rules_odin//odin:hermetic_linker=true (via _hermetic_linker's
# BuildSettingInfo) and which Linux arch the target is (via
# ctx.target_platform_has_constraint against _os_linux / _cpu_x86_64 /
# _cpu_aarch64). A select() default is not permitted on private attrs, so
# detection happens in the implementation instead.
HERMETIC_ATTRS = {
    "hermetic_clang": attr.label(
        doc = "Opt-in: a single hermetic clang executable used as Odin's linker driver (ODIN_CLANG_PATH). Requires --@rules_odin//odin:hermetic_linker=true and a Linux target. Bring your own, e.g. @llvm_toolchain_llvm//:bin/clang.",
        allow_single_file = True,
        default = None,
    ),
    "hermetic_toolchain_files": attr.label(
        doc = "Opt-in: filegroup of the hermetic clang/lld/lib files staged as action inputs (e.g. @llvm_toolchain_llvm//:bin).",
        allow_files = True,
        default = None,
    ),
    "hermetic_sysroot": attr.label(
        doc = "Opt-in: filegroup of the pinned sysroot tree staged as action inputs and linked against (--sysroot/-B/-L). Must follow the Chromium debian_stretch GCC-6 multiarch layout (usr/lib/gcc/<triple>/6, usr/lib/<triple>, lib/<triple>); other sysroot families require ruleset changes.",
        allow_files = True,
        default = None,
    ),
    "_hermetic_linker": attr.label(
        default = "@rules_odin//odin:hermetic_linker",
    ),
    "_os_linux": attr.label(
        default = "@platforms//os:linux",
    ),
    "_cpu_x86_64": attr.label(
        default = "@platforms//cpu:x86_64",
    ),
    "_cpu_aarch64": attr.label(
        default = "@platforms//cpu:aarch64",
    ),
}

def _resolve_hermetic_arch(ctx):
    """Return the target arch key if hermetic Linux linking is active, else "".

    Active means --@rules_odin//odin:hermetic_linker=true AND the target
    platform is Linux on x86_64 or aarch64. On macOS/Windows (or when the flag
    is false) the result is "" and the host linker path is used.
    """
    if not ctx.attr._hermetic_linker[BuildSettingInfo].value:
        return ""
    if not ctx.target_platform_has_constraint(
        ctx.attr._os_linux[platform_common.ConstraintValueInfo],
    ):
        return ""
    if ctx.target_platform_has_constraint(
        ctx.attr._cpu_x86_64[platform_common.ConstraintValueInfo],
    ):
        return "x86_64"
    if ctx.target_platform_has_constraint(
        ctx.attr._cpu_aarch64[platform_common.ConstraintValueInfo],
    ):
        return "aarch64"
    return ""

def _hermetic_linker_flags(sysroot_root, arch):
    """Assemble the clang linker-driver flags for a hermetic Linux link.

    Computed in-ruleset (not user-supplied) from the target arch. The Chromium
    debian_stretch sysroots use the GCC 6 Debian multiarch layout, and
    libc.so/libm.so/libgcc_s.so are GNU-ld linker scripts with absolute paths,
    so --sysroot is required in addition to -B/-L.

    Args:
        sysroot_root: Path to the staged sysroot tree root.
        arch: Target arch key ("x86_64" or "aarch64").

    Returns:
        List of clang flag strings to pass via -extra-linker-flags.
    """
    triple = _LINUX_MULTIARCH[arch]
    gcc_dir = "{}/usr/lib/gcc/{}/{}".format(sysroot_root, triple, _SYSROOT_GCC_VERSION)
    return [
        "--target=" + triple,
        "--sysroot=" + sysroot_root,
        "-B" + gcc_dir + "/",
        "-L" + gcc_dir,
        "-L{}/usr/lib/{}".format(sysroot_root, triple),
        "-L{}/lib/{}".format(sysroot_root, triple),
    ]

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

    # Set ODIN_ROOT so the compiler finds core/, base/, vendor/.
    env = {}
    if odin_info.compiler:
        env["ODIN_ROOT"] = odin_info.compiler.dirname

    # Opt-in hermetic Linux linking. hermetic_arch is non-empty only when
    # --@rules_odin//odin:hermetic_linker=true AND the target is Linux
    # x86_64/aarch64. Activation additionally requires this specific target to
    # opt in by setting hermetic_clang — so a global flag does not force
    # hermetic mode onto targets that have not supplied the BYO toolchain
    # (they stay on the host linker path).
    hermetic_arch = _resolve_hermetic_arch(ctx)
    hermetic_inputs = []
    use_host_env = True

    if hermetic_arch and ctx.file.hermetic_clang:
        hermetic_clang = ctx.file.hermetic_clang
        sysroot_files = ctx.files.hermetic_sysroot

        # Genuine misconfiguration: this target opted into hermetic linking
        # (hermetic_clang set) but is missing the sysroot needed to link.
        if not sysroot_files:
            fail(
                "{} '{}': hermetic linking is enabled ".format(rule_name, ctx.label.name) +
                "(--@rules_odin//odin:hermetic_linker=true on Linux, with " +
                "'hermetic_clang' set) but 'hermetic_sysroot' is not set. " +
                "Point it at a pinned sysroot filegroup, or unset " +
                "'hermetic_clang'.",
            )

        # Point Odin's linker driver at the hermetic clang and force lld. clang
        # discovers ld.lld next to its own binary, so hermetic_toolchain_files
        # must stage bin/clang and bin/ld.lld together.
        env["ODIN_CLANG_PATH"] = hermetic_clang.path
        args.add("-linker:lld")

        # Resolve the sysroot tree root. hermetic_sysroot is expected to be a
        # tree-artifact filegroup (toolchains_llvm's `sysroot` repo rule emits
        # filegroup(name="sysroot", srcs=["."])), so ctx.files typically holds a
        # single directory File whose path is the root. The loop defensively
        # picks the shortest path in case a broader filegroup is supplied.
        sysroot_root = sysroot_files[0].path
        for f in sysroot_files:
            if len(f.path) < len(sysroot_root):
                sysroot_root = f.path

        # Arch-conditional --target/--sysroot/-B/-L, computed in-ruleset.
        linker_flags = _hermetic_linker_flags(sysroot_root, hermetic_arch)
        args.add("-extra-linker-flags:" + " ".join(linker_flags))

        # Stage the clang driver itself plus the toolchain (clang+lld+libs) and
        # sysroot as action inputs. hermetic_clang is added explicitly so the
        # driver is present even if hermetic_toolchain_files is a narrower set.
        hermetic_inputs = (
            [hermetic_clang] +
            ctx.files.hermetic_toolchain_files +
            sysroot_files
        )

        # Hermetic mode: no host environment leak.
        use_host_env = False

    # Collect all inputs: sources + library dep srcs + entire SDK + any
    # hermetic toolchain/sysroot files.
    inputs = depset(
        direct = srcs + dep_srcs + hermetic_inputs,
        transitive = [odin_info.all_files],
    )

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
        use_default_shell_env = use_host_env,
    )

    return DefaultInfo(
        files = depset([out_file]),
        executable = out_file,
        runfiles = ctx.runfiles(files = [out_file]),
    )
