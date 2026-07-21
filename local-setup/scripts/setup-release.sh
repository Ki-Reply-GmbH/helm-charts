#!/bin/bash

# Download and verify the Platform Mesh 0.3.0 OCM release archive.

PLATFORM_MESH_RELEASE_VERSION="0.3.0"
PLATFORM_MESH_RELEASE_ASSET="platform-mesh-${PLATFORM_MESH_RELEASE_VERSION}.ctf.tgz"
PLATFORM_MESH_RELEASE_URL="https://github.com/Ki-Reply-GmbH/helm-charts/releases/download/${PLATFORM_MESH_RELEASE_VERSION}/${PLATFORM_MESH_RELEASE_ASSET}"
# SHA-256 of the immutable descriptor archive attached to release 0.3.0.
PLATFORM_MESH_RELEASE_SHA256="550731c03f7b5ba753c079cbb69b9cc860ac26d7582af37d590d4e7a1be64b22"

RELEASE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_MESH_RELEASE_CACHE="${RELEASE_SCRIPT_DIR}/../assets/${PLATFORM_MESH_RELEASE_ASSET}"

release_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "Neither sha256sum nor shasum is installed" >&2
    return 1
  fi
}

verify_release_artifact() {
  local archive="$1"
  local actual

  [ -f "$archive" ] || return 1
  actual=$(release_sha256 "$archive") || return 1
  if [ "$actual" != "$PLATFORM_MESH_RELEASE_SHA256" ]; then
    echo "Platform Mesh release archive checksum mismatch: $archive" >&2
    echo "Expected: $PLATFORM_MESH_RELEASE_SHA256" >&2
    echo "Actual:   $actual" >&2
    return 1
  fi
}

prepare_release_artifact() {
  local archive tmp

  if [ -n "${PLATFORM_MESH_RELEASE_FILE:-}" ]; then
    archive="$PLATFORM_MESH_RELEASE_FILE"
    if ! verify_release_artifact "$archive"; then
      echo "PLATFORM_MESH_RELEASE_FILE is not the pinned Platform Mesh 0.3.0 archive" >&2
      return 1
    fi
    PLATFORM_MESH_RELEASE_ARCHIVE="$(cd "$(dirname "$archive")" && pwd)/$(basename "$archive")"
    export PLATFORM_MESH_RELEASE_ARCHIVE
    echo "Using Platform Mesh release archive: $PLATFORM_MESH_RELEASE_ARCHIVE"
    return 0
  fi

  archive="$PLATFORM_MESH_RELEASE_CACHE"
  if verify_release_artifact "$archive" 2>/dev/null; then
    PLATFORM_MESH_RELEASE_ARCHIVE="$archive"
    export PLATFORM_MESH_RELEASE_ARCHIVE
    echo "Using cached Platform Mesh release archive: $archive"
    return 0
  fi

  command -v curl >/dev/null 2>&1 || {
    echo "curl is required to download $PLATFORM_MESH_RELEASE_URL" >&2
    return 1
  }

  mkdir -p "$(dirname "$archive")"
  tmp="${archive}.part.$$"
  echo "Downloading pinned Platform Mesh OCM release 0.3.0..."
  if ! curl --fail --location --retry 3 --retry-all-errors --output "$tmp" "$PLATFORM_MESH_RELEASE_URL"; then
    rm -f "$tmp"
    return 1
  fi
  if ! verify_release_artifact "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$archive"

  PLATFORM_MESH_RELEASE_ARCHIVE="$archive"
  export PLATFORM_MESH_RELEASE_ARCHIVE
  echo "Cached Platform Mesh release archive: $archive"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  prepare_release_artifact
fi
