"""Repository rules for downloading and registering the Odin SDK."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//odin/private:toolchains_repo.bzl", "toolchains_repo")
load("//odin/private:versions.bzl", "DEFAULT_ODIN_VERSION", "ODIN_VERSIONS")

_ODIN_SDK_BUILD_FILE = Label("//odin/private:odin_sdk.BUILD.bazel")

def odin_register_toolchains(name = "odin", odin_version = None):
    """Download Odin SDK archives and register toolchains for all available platforms.

    Args:
        name: Base name for the generated repositories. The SDK repos will be
              named "{name}_{platform}" and the hub repo "{name}_toolchains".
        odin_version: Odin version tag (e.g., "dev-2026-06").
                      Defaults to DEFAULT_ODIN_VERSION.
    """
    if not odin_version:
        odin_version = DEFAULT_ODIN_VERSION

    if odin_version not in ODIN_VERSIONS:
        fail("Unknown Odin version '{}'. Available: {}".format(
            odin_version,
            ", ".join(sorted(ODIN_VERSIONS.keys())),
        ))

    version_info = ODIN_VERSIONS[odin_version]
    registered_platforms = []
    sdk_repos = {}

    for platform, platform_info in version_info.items():
        repo_name = "{name}_{platform}".format(name = name, platform = platform)

        http_archive(
            name = repo_name,
            url = platform_info["url"],
            sha256 = platform_info["sha256"],
            strip_prefix = platform_info.get("strip_prefix", ""),
            build_file = _ODIN_SDK_BUILD_FILE,
        )

        registered_platforms.append(platform)
        sdk_repos[platform] = repo_name

    # Create the hub repo that contains all toolchain declarations
    toolchains_repo(
        name = name + "_toolchains",
        odin_version = odin_version,
        platforms = registered_platforms,
        sdk_repos = sdk_repos,
    )
