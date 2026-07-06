"""Odin compiler version definitions with platform-specific download URLs and SHA256 hashes."""

# Platform keys follow the pattern: {os}_{arch}
# Supported platforms:
#   - linux_amd64
#   - linux_arm64
#   - macos_amd64
#   - macos_arm64
#   - windows_amd64

ODIN_VERSIONS = {
    "dev-2026-06": {
        "linux_amd64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-06/odin-linux-amd64-dev-2026-06.tar.gz",
            "sha256": "40f38b462f30914c7f07271c56c8b4b7a7a6e5d82789c8165f75ab569c3b96cc",
            "strip_prefix": "odin-linux-amd64-nightly+2026-06-08",
        },
        "linux_arm64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-06/odin-linux-arm64-dev-2026-06.tar.gz",
            "sha256": "01fc4938cb79d82064bf0b20c4745732e74cc508fdcb6669fa1fa29be8a7d8d4",
            "strip_prefix": "odin-linux-arm64-nightly+2026-06-08",
        },
        "macos_amd64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-06/odin-macos-amd64-dev-2026-06.tar.gz",
            "sha256": "0739a57559f4afe5943b06fc20d8b5791a2b9d497215e017c8c96465d30667f5",
            "strip_prefix": "odin-macos-amd64-nightly+2026-06-08",
        },
        "macos_arm64": {
            # Note: dev-2026-06 has a filename anomaly (truncated tag)
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-06/odin-macos-arm64-dev-06.tar.gz",
            "sha256": "dbce61bd8320fd9e908d6de705b7c2410146b1cb55db05514407e90a65f241a1",
            "strip_prefix": "odin-macos-arm64-nightly+2026-06-08",
        },
        "windows_amd64": {
            # Note: dev-2026-06 drops 'amd64' from Windows filename
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-06/odin-windows-dev-2026-06.zip",
            "sha256": "a01fb049f228e4068924047218e4635cb7c4f7d5bc7c11b1e1890022e3d44a7a",
            "strip_prefix": "dist",
        },
    },
    "dev-2026-05": {
        "linux_amd64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-05/odin-linux-amd64-dev-2026-05.tar.gz",
            "sha256": "cd7ec2cd1ab2840a0b7ebc18e5cb41c671bce87b12f056fddbef3f080b4dde7d",
            "strip_prefix": "odin-linux-amd64-nightly+2026-05-03",
        },
        "linux_arm64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-05/odin-linux-arm64-dev-2026-05.tar.gz",
            "sha256": "48e93e5534ac4bea52e9cb986830d414bfe8b0ce3ff08416d6131ba0b18d0435",
            "strip_prefix": "odin-linux-arm64-nightly+2026-05-03",
        },
        "macos_amd64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-05/odin-macos-amd64-dev-2026-05.tar.gz",
            "sha256": "48c43397e01fed5fe937dc0fa6031dae9a7d145e2ba52cb25cede6ba771b3ac6",
            "strip_prefix": "odin-macos-amd64-nightly+2026-05-03",
        },
        "macos_arm64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-05/odin-macos-arm64-dev-2026-05.tar.gz",
            "sha256": "0f50c8bc8ce1106786f0cc7dc22dae32aab7c40d525ba0f8629f8c0952deb20a",
            "strip_prefix": "odin-macos-arm64-nightly+2026-05-03",
        },
        "windows_amd64": {
            "url": "https://github.com/odin-lang/Odin/releases/download/dev-2026-05/odin-windows-amd64-dev-2026-05.zip",
            "sha256": "27e6021fe240ffc7944e32bc55e48bab868b9873856a5593d66f7f197e7f0562",
            "strip_prefix": "dist",
        },
    },
}

# Default version used when none is specified
DEFAULT_ODIN_VERSION = "dev-2026-06"
