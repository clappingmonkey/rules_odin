#!/usr/bin/env bash
# release_prep.sh — Called by bazel-contrib/.github release_ruleset.yaml
#
# Creates the release source archive and outputs release notes.
# The archive name MUST match the glob in release.yaml: rules_odin-*.tar.gz
#
# Called as: .github/workflows/release_prep.sh ${{ inputs.tag_name || github.ref_name }}
# The tag is passed as the first positional argument (not as an env var).

set -o errexit -o nounset -o pipefail

# Argument provided by release_ruleset.yaml.
TAG="${1:-}"

if [[ -z "$TAG" ]]; then
  echo "::error::TAG is not set. Cannot determine release version."
  exit 1
fi

# Validate tag format (semver with 'v' prefix).
if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "::error::TAG '${TAG}' does not match expected format (vMAJOR.MINOR.PATCH)."
  exit 1
fi

# Strip the 'v' prefix for module version (v0.2.0 -> 0.2.0)
VERSION="${TAG#v}"

# Archive name includes the 'v' prefix to match GitHub's source archive naming.
# This allows users to switch between released artifacts and source archives
# with minimal differences (strip_prefix stays the same).
PREFIX="rules_odin-${VERSION}"
ARCHIVE="rules_odin-${TAG}.tar.gz"

echo "Creating release archive: ${ARCHIVE}"

# Create the archive via git archive, then patch MODULE.bazel in-place.
# smlx/ccv tags HEAD as-is, so MODULE.bazel still has the old version.
# The BCR validation requires the version to match the tag exactly.
#
# We extract the full archive, patch MODULE.bazel, then re-archive.
# This avoids GNU tar --delete/--append which is not available on macOS bsdtar.
TMPDIR=$(mktemp -d)
trap 'rm -rf "${TMPDIR}"' EXIT

git archive --format=tar --prefix="${PREFIX}/" HEAD | tar -xf - -C "${TMPDIR}"

# Patch the version in MODULE.bazel to match the tag.
# Only replace the version inside the module() call, not bazel_dep versions.
# The module() block range ensures we don't touch dependency versions.
sed -i.bak "/^module(/,/^)/s/version = \"[^\"]*\"/version = \"${VERSION}\"/" "${TMPDIR}/${PREFIX}/MODULE.bazel"
rm -f "${TMPDIR}/${PREFIX}/MODULE.bazel.bak"

# Verify the patch was applied successfully.
# Check only within the module() block to avoid false-passing on
# bazel_dep versions that happen to match the tag version.
if ! sed -n '/^module(/,/^)/p' "${TMPDIR}/${PREFIX}/MODULE.bazel" | grep -q "version = \"${VERSION}\""; then
  echo "::error::Failed to patch MODULE.bazel version to ${VERSION}."
  echo "::error::Check that MODULE.bazel has a module() block with a version field."
  exit 1
fi

# Re-create the archive from the patched tree with deterministic metadata.
# GNU tar (used in CI on ubuntu-latest) supports --sort, --mtime, --owner, --group.
# On macOS, bsdtar does not support these flags; fall back to basic tar.
TAR_REPRO_OPTS=""
if tar --help 2>&1 | grep -q -- '--sort='; then
    TAR_REPRO_OPTS="--sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner"
fi
# gzip -n strips the gzip timestamp for reproducible output (portable).
tar -cf - -C "${TMPDIR}" ${TAR_REPRO_OPTS} "${PREFIX}" | gzip -n > "${ARCHIVE}"

echo "Archive created: $(ls -lh "${ARCHIVE}" | awk '{print $5}')"

SHA256=$(shasum -a 256 "${ARCHIVE}" | cut -d' ' -f1)
SRI="sha256-$(echo -n "${SHA256}" | xxd -r -p | base64)"

echo "SHA256: ${SHA256}"
echo "SRI:    ${SRI}"

# Output release notes to STDOUT — appended to GitHub Release body.
cat <<EOF

## Usage

Add to your \`MODULE.bazel\`:

\`\`\`starlark
bazel_dep(name = "rules_odin", version = "${VERSION}")
\`\`\`

## Integrity

- **SHA256**: \`${SHA256}\`
- **SRI**: \`${SRI}\`
EOF
