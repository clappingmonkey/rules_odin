#!/usr/bin/env bash
# Validates that odin_test exits non-zero when @(test) procedures fail.
# This proves Bazel correctly reports FAILED for odin_test targets.

# --- begin runfiles.bash initialization v3 ---
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null ||
  source "$0.runfiles/$f" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
  {
    echo >&2 "ERROR: cannot find $f"
    exit 1
  }
# --- end runfiles.bash initialization v3 ---

set -e

# Resolve the binary path from the rlocationpath passed as $1.
BINARY="$(rlocation "$1")"
if [[ ! -x "$BINARY" ]]; then
  echo "ERROR: binary not found or not executable: $BINARY"
  exit 1
fi

# Run the failing test binary and capture its exit code.
set +e
"$BINARY" >/dev/null 2>&1
EXIT_CODE=$?
set -e

# Assert non-zero exit (test failure must propagate).
if [[ "$EXIT_CODE" -eq 0 ]]; then
  echo "FAIL: expected non-zero exit code from failing odin_test binary, got 0"
  echo "      odin_test is NOT propagating failure correctly!"
  exit 1
fi

echo "PASS: odin_test correctly propagated failure (exit code $EXIT_CODE)"
