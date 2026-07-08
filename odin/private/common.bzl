"""Shared helpers for rules_odin."""

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
