#!/usr/bin/env bash
# Build a native app with Command Line Tools; arm64 must always succeed.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="CatchMouse"
APP_DIR="build/${APP_NAME}.app"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
SRCS=(Sources/"${APP_NAME}"/*.swift)
FRAMEWORKS=(-framework AppKit -framework Carbon -framework CoreGraphics -framework ColorSync)

architectures=(arm64)
case "${1:-arm64}" in
    arm64) ;;
    universal) architectures+=(x86_64) ;;
    *) echo "usage: $0 [arm64|universal]" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then echo "usage: $0 [arm64|universal]" >&2; exit 2; fi

mkdir -p build
staging="$(mktemp -d build/.catchmouse.XXXXXX)"
trap 'rm -rf "$staging"' EXIT
slices=()
for arch in "${architectures[@]}"; do
    echo "Compiling ${arch}…"
    xcrun swiftc -O -sdk "$SDK" -target "${arch}-apple-macos11.0" \
        "${FRAMEWORKS[@]}" "${SRCS[@]}" -o "${staging}/${APP_NAME}-${arch}"
    slices+=("${staging}/${APP_NAME}-${arch}")
done

bundle="${staging}/${APP_NAME}.app"
mkdir -p "${bundle}/Contents/MacOS" "${bundle}/Contents/Resources"
if [ "${#slices[@]}" -eq 1 ]; then
    cp "${slices[0]}" "${bundle}/Contents/MacOS/${APP_NAME}"
else
    xcrun lipo -create "${slices[@]}" -output "${bundle}/Contents/MacOS/${APP_NAME}"
fi
xcrun lipo "${bundle}/Contents/MacOS/${APP_NAME}" -verify_arch "${architectures[@]}"
cp Resources/Info.plist "${bundle}/Contents/Info.plist"
cp LICENSE "${bundle}/Contents/Resources/LICENSE"
printf 'APPL????' > "${bundle}/Contents/PkgInfo"
if [ -f Resources/icon.icns ]; then cp Resources/icon.icns "${bundle}/Contents/Resources/icon.icns"; fi
plutil -lint "${bundle}/Contents/Info.plist"
codesign --force --sign - "$bundle"
codesign --verify --strict "$bundle"

# Replace an earlier build only after compilation and verification succeed.
rm -rf "$APP_DIR"
mv "$bundle" "$APP_DIR"
echo "Built ${APP_DIR}: $(xcrun lipo -archs "${APP_DIR}/Contents/MacOS/${APP_NAME}")"
