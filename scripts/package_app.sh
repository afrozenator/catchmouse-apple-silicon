#!/usr/bin/env bash
# Package the already-built app without recompiling it.
set -euo pipefail
cd "$(dirname "$0")/.."
APP="build/CatchMouse.app"
version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
architectures="$(xcrun lipo -archs "$APP/Contents/MacOS/CatchMouse")"
xcrun lipo -verify_arch arm64 "$APP/Contents/MacOS/CatchMouse"
codesign --verify --strict "$APP"
case "$architectures" in
    arm64) kind="arm64" ;;
    *arm64*x86_64*|*x86_64*arm64*) kind="universal" ;;
    *) echo "unexpected architectures: $architectures" >&2; exit 1 ;;
esac
archive="CatchMouse-${version}-${kind}.zip"
rm -f "build/$archive"
ditto -c -k --sequesterRsrc --keepParent "$APP" "build/$archive"
(cd build && shasum -a 256 "$archive" > "${archive}.sha256")
echo "Packaged build/$archive"
