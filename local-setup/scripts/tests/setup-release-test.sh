#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../setup-release.sh"

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

printf 'valid release archive\n' > "$TEST_DIR/release.tgz"
PLATFORM_MESH_RELEASE_SHA256=$(release_sha256 "$TEST_DIR/release.tgz")
PLATFORM_MESH_RELEASE_CACHE="$TEST_DIR/cache/platform-mesh-0.3.0.ctf.tgz"

# A valid explicit override is accepted.
PLATFORM_MESH_RELEASE_FILE="$TEST_DIR/release.tgz"
prepare_release_artifact >/dev/null
[ "$PLATFORM_MESH_RELEASE_ARCHIVE" = "$TEST_DIR/release.tgz" ]

# A mismatched explicit override fails without modifying it.
printf 'corrupt\n' > "$TEST_DIR/corrupt.tgz"
PLATFORM_MESH_RELEASE_FILE="$TEST_DIR/corrupt.tgz"
if prepare_release_artifact >/dev/null 2>&1; then
  echo "corrupt PLATFORM_MESH_RELEASE_FILE was accepted" >&2
  exit 1
fi
[ "$(cat "$TEST_DIR/corrupt.tgz")" = "corrupt" ]

# A valid cache is reused without invoking curl.
unset PLATFORM_MESH_RELEASE_FILE
mkdir -p "$(dirname "$PLATFORM_MESH_RELEASE_CACHE")"
cp "$TEST_DIR/release.tgz" "$PLATFORM_MESH_RELEASE_CACHE"
mkdir "$TEST_DIR/no-curl"
PATH="$TEST_DIR/no-curl:/usr/bin:/bin" prepare_release_artifact >/dev/null

# A missing or corrupt cache is atomically replaced by a successful download.
mkdir "$TEST_DIR/bin"
cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/bin/bash
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--output" ]; then
    cp "$FAKE_DOWNLOAD_SOURCE" "$2"
    exit 0
  fi
  shift
done
exit 1
EOF
chmod +x "$TEST_DIR/bin/curl"
export FAKE_DOWNLOAD_SOURCE="$TEST_DIR/release.tgz"
printf 'stale\n' > "$PLATFORM_MESH_RELEASE_CACHE"
PATH="$TEST_DIR/bin:/usr/bin:/bin" prepare_release_artifact >/dev/null
verify_release_artifact "$PLATFORM_MESH_RELEASE_CACHE"

# A failed download leaves no partial cache behind.
cat > "$TEST_DIR/bin/curl" <<'EOF'
#!/bin/bash
while [ "$#" -gt 0 ]; do
  if [ "$1" = "--output" ]; then
    printf 'partial\n' > "$2"
    exit 22
  fi
  shift
done
exit 22
EOF
chmod +x "$TEST_DIR/bin/curl"
rm -f "$PLATFORM_MESH_RELEASE_CACHE"
if PATH="$TEST_DIR/bin:/usr/bin:/bin" prepare_release_artifact >/dev/null 2>&1; then
  echo "failed download was accepted" >&2
  exit 1
fi
[ ! -e "$PLATFORM_MESH_RELEASE_CACHE" ]
if find "$(dirname "$PLATFORM_MESH_RELEASE_CACHE")" -name '*.part.*' -print -quit | grep -q .; then
  echo "failed download left a partial file" >&2
  exit 1
fi

echo "setup-release tests passed"
