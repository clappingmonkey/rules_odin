"""Implementation of the odin_binary rule."""

load("//odin/private:common.bzl", "HERMETIC_SPIKE_ATTRS", "OdinLibraryInfo", "compile_odin_binary")

def _odin_binary_impl(ctx):
    toolchain = ctx.toolchains["@rules_odin//odin:toolchain_type"]
    odin_info = toolchain.odininfo

    # Determine output binary name.
    if ctx.attr.out:
        out_name = ctx.attr.out
    else:
        out_name = ctx.label.name + odin_info.binary_ext

    out = ctx.actions.declare_file(out_name)

    return [compile_odin_binary(
        ctx = ctx,
        srcs = ctx.files.srcs,
        build_mode = "exe",
        out_file = out,
    )]

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
    } | HERMETIC_SPIKE_ATTRS,
    executable = True,
    toolchains = ["@rules_odin//odin:toolchain_type"],
)
