"""OdinInfo provider and odin_toolchain rule definition."""

OdinInfo = provider(
    doc = "Information about the Odin compiler toolchain.",
    fields = {
        "compiler": "File: The odin compiler executable.",
        "sdk_root": "String: Path to the SDK root directory (set as ODIN_ROOT).",
        "sdk_files": "depset: All files in the Odin SDK (core/, base/, vendor/).",
        "all_files": "depset: All toolchain files (compiler + SDK).",
        "version": "String: The Odin version tag (e.g., 'dev-2026-06').",
    },
)

def _to_manifest_path(ctx, file):
    """Convert a File to its manifest/runfiles path."""
    if file.short_path.startswith("../"):
        return "external/" + file.short_path[3:]
    else:
        return ctx.workspace_name + "/" + file.short_path

def _odin_toolchain_impl(ctx):
    if ctx.attr.compiler and ctx.attr.compiler_path:
        fail("Cannot set both 'compiler' and 'compiler_path'.")
    if not ctx.attr.compiler and not ctx.attr.compiler_path:
        fail("Must set one of 'compiler' or 'compiler_path'.")

    compiler_files = []
    compiler_path = ctx.attr.compiler_path
    compiler_file = None

    if ctx.attr.compiler:
        compiler_files = ctx.attr.compiler.files.to_list()
        compiler_file = compiler_files[0]
        compiler_path = _to_manifest_path(ctx, compiler_file)

    sdk_files = []
    if ctx.attr.sdk:
        sdk_files = ctx.attr.sdk.files.to_list()

    # Determine the SDK root path.
    # The SDK root is the directory containing the compiler binary,
    # which is also where core/, base/, vendor/ live.
    sdk_root = ctx.attr.sdk_root
    if not sdk_root and compiler_file:
        sdk_root = compiler_file.dirname

    all_files = compiler_files + sdk_files

    # Template variable for use in genrules: $(ODIN_BIN)
    template_variables = platform_common.TemplateVariableInfo({
        "ODIN_BIN": compiler_path,
    })

    odin_info = OdinInfo(
        compiler = compiler_file,
        sdk_root = sdk_root,
        sdk_files = depset(sdk_files),
        all_files = depset(all_files),
        version = ctx.attr.version,
    )

    toolchain_info = platform_common.ToolchainInfo(
        odininfo = odin_info,
    )

    return [
        DefaultInfo(
            files = depset(all_files),
            runfiles = ctx.runfiles(files = all_files),
        ),
        toolchain_info,
        template_variables,
    ]

odin_toolchain = rule(
    implementation = _odin_toolchain_impl,
    doc = "Defines an Odin compiler toolchain.",
    attrs = {
        "compiler": attr.label(
            doc = "Label for the hermetically-downloaded Odin compiler binary.",
            mandatory = False,
            allow_single_file = True,
        ),
        "compiler_path": attr.string(
            doc = "Absolute path to a pre-installed Odin compiler (non-hermetic).",
            mandatory = False,
        ),
        "sdk": attr.label(
            doc = "Label for the Odin SDK filegroup (core/, base/, vendor/).",
            mandatory = False,
        ),
        "sdk_root": attr.string(
            doc = "Path to the SDK root directory. If unset, derived from compiler location.",
            mandatory = False,
        ),
        "version": attr.string(
            doc = "Odin version tag (e.g., 'dev-2026-06').",
            default = "",
        ),
    },
)
