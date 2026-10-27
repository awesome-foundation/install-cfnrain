#!/usr/bin/env bash
# Installs cfnrain from its GitHub releases. action.yml runs this script, and passes the
# inputs as VERSION, RAIN_ALIAS, VERIFY_ATTESTATION and GH_TOKEN.
set -euo pipefail

repo=awesome-foundation/cfnrain

fail() {
  echo "::error::$1"
  exit 1
}

version=${VERSION#[vV]}
if [ "$(echo "$version" | tr '[:upper:]' '[:lower:]')" = latest ]; then
  version=$(gh release view -R "$repo" --json tagName --jq .tagName)
  version=${version#v}
fi

case "$RUNNER_OS" in
  Linux) os=linux ;;
  macOS) os=darwin ;;
  Windows) os=windows ;;
  *) fail "cfnrain has no release for $RUNNER_OS" ;;
esac

case "$RUNNER_ARCH" in
  X64) arch=amd64 ;;
  ARM64) arch=arm64 ;;
  X86) arch=386 ;;
  ARM) arch=arm ;;
  *) fail "cfnrain has no release for $RUNNER_ARCH" ;;
esac

if [ "$os" = windows ]; then
  ext=zip
  exe=.exe
else
  ext=tar.gz
  exe=
fi

archive="cfnrain_${version}_${os}_${arch}.${ext}"
download="$RUNNER_TEMP/cfnrain-download"
bin_dir="$RUNNER_TEMP/cfnrain-bin"
rm -rf "$download" "$bin_dir"
mkdir -p "$download" "$bin_dir"

echo "Downloading $archive from $repo v$version"
gh release download "v$version" -R "$repo" -p "$archive" -p checksums.txt -D "$download" ||
  fail "Cannot download $archive from $repo v$version. Is there a release for this version and platform?"

cd "$download"
expected=$(awk -v f="$archive" '$2 == f { print $1 }' checksums.txt)
[ -n "$expected" ] || fail "checksums.txt has no entry for $archive"
if command -v sha256sum >/dev/null; then
  actual=$(sha256sum "$archive" | cut -d' ' -f1)
else
  actual=$(shasum -a 256 "$archive" | cut -d' ' -f1)
fi
[ "$actual" = "$expected" ] || fail "Checksum mismatch for $archive: expected $expected, got $actual"
echo "Checksum OK: $actual"

if [ "$VERIFY_ATTESTATION" = true ]; then
  gh attestation verify "$archive" -R "$repo" ||
    fail "The build provenance of $archive does not verify"
fi

if [ "$ext" = zip ]; then
  unzip -oq "$archive" "cfnrain$exe" -d "$bin_dir"
else
  tar -xzf "$archive" -C "$bin_dir" cfnrain
fi

if [ "$RAIN_ALIAS" = true ]; then
  # A copy, not a link: Git Bash on Windows cannot make symbolic links without developer mode.
  cp "$bin_dir/cfnrain$exe" "$bin_dir/rain$exe"
fi

"$bin_dir/cfnrain$exe" --version

echo "$bin_dir" >> "$GITHUB_PATH"
echo "cfnrain-bin=$bin_dir/cfnrain$exe" >> "$GITHUB_OUTPUT"
echo "version=$version" >> "$GITHUB_OUTPUT"
