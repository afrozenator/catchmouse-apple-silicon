#!/usr/bin/env bash
# Dependency-free regression tests; XCTest/full Xcode are not required.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .build
test_dir="$(mktemp -d .build/catchmouse-tests.XXXXXX)"
trap 'rm -rf "$test_dir"' EXIT
xcrun swiftc -parse-as-library \
    -framework Carbon -framework CoreGraphics -framework ColorSync \
    Sources/CatchMouse/KeyCombo.swift Sources/CatchMouse/HotKeyStore.swift \
    Sources/CatchMouse/Shortcuts.swift Sources/CatchMouse/DisplayManager.swift \
    Sources/CatchMouse/CLI.swift Tests/CatchMouseTests/*.swift \
    -o "$test_dir/tests"
"$test_dir/tests"
