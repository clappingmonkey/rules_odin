#!/usr/bin/env bash
# release_prep.sh — Called by bazel-contrib/.github release_ruleset.yaml
#
# Creates the release source archive and outputs release notes.
# The archive name MUST match the glob in release.yaml: rules_odin-*.tar.gz
#
# Environment variables available:
#   TAG — the version tag being released (e.g., v0.2.0)
#   GITHUB_WORKSPACE — repo checkout root

set -euo pipefail

TAG="${TAG:-${GITHUB_REF_NAME:-}}"

if [[ -z "$TAG" ]]; then
  echo "::error::TAG is not set. Cannot determine release version."
  exit 1
fi

# Strip the 'v' prefix for the archive name (e.g., v0.2.0 → 0.2.0)
VERSION="${TAG#v}"

ARCHIVE="rules_odin-${VERSION}.tar.gz"

echo "Creating release archive: ${ARCHIVE}"

# Create a reproducible source archive using git archive.
# --prefix ensures the extracted directory is named rules_odin-{VERSION}/
git archive \
  --format=tar.gz \
  --prefix="rules_odin-${VERSION}/" \
  --output="${ARCHIVE}" \
  HEAD

echo "Archive created: $(ls -lh "${ARCHIVE}" | awk '{print $5}')"

# Compute integrity hash (SHA256 in SRI format for MODULE.bazel snippets)
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
