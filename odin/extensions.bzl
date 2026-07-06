"""bzlmod module extension for the Odin toolchain."""

load("//odin:repositories.bzl", "odin_register_toolchains")

_DEFAULT_NAME = "odin"

_toolchain_tag = tag_class(
    doc = "Declares an Odin toolchain to download and register.",
    attrs = {
        "name": attr.string(
            doc = "Base name for toolchain repos (default: 'odin').",
            default = _DEFAULT_NAME,
        ),
        "odin_version": attr.string(
            doc = "Odin version to use (e.g., 'dev-2026-06').",
            mandatory = True,
        ),
    },
)

def _odin_extension_impl(module_ctx):
    registrations = {}

    for mod in module_ctx.modules:
        for toolchain in mod.tags.toolchain:
            name = toolchain.name

            # Only the root module may override the default name
            if name != _DEFAULT_NAME and not mod.is_root:
                fail(
                    "Only the root module may set a custom toolchain name. " +
                    "Module '{}' attempted to use name '{}'.".format(mod.name, name),
                )

            if name not in registrations:
                registrations[name] = toolchain.odin_version
            else:
                # Root module wins over transitive deps
                if mod.is_root:
                    registrations[name] = toolchain.odin_version

    for name, version in registrations.items():
        odin_register_toolchains(
            name = name,
            odin_version = version,
        )

odin = module_extension(
    implementation = _odin_extension_impl,
    doc = "Module extension for registering Odin toolchains.",
    tag_classes = {
        "toolchain": _toolchain_tag,
    },
)
