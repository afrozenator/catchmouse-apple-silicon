# CatchMouse for Apple Silicon

Move the pointer to another display with a global keyboard shortcut. A small
Swift menu-bar app for Apple Silicon Macs running macOS 11 or later; no Rosetta,
external dependencies, or Accessibility permission needed by the app.

This is a maintained fork of [zhouyi-xiaoxiao/CatchMouse](https://github.com/zhouyi-xiaoxiao/CatchMouse),
an MIT-licensed Swift replacement for the original [round/CatchMouse](https://github.com/round/CatchMouse).
The original repository distributes an Intel-only app without source code, so
that binary cannot be recompiled for Apple Silicon. No original binary or artwork
is included here.

## Install

Download **CatchMouse-2.2.0-arm64.zip** from the
[latest release](https://github.com/afrozenator/catchmouse-apple-silicon/releases/latest).

1. Quit the old CatchMouse from its menu-bar icon.
2. Unzip the download and move **CatchMouse.app** into **Applications**, replacing
   the old copy. Keep the old app elsewhere if you want to be able to revert.
3. Open CatchMouse. It shows a cursor icon in the menu bar; it has no Dock icon.
4. Open **Preferences…** to set your shortcuts.

The download is ad-hoc signed, **not Apple Developer ID signed or notarized**.
If macOS blocks the downloaded app, use **System Settings → Privacy & Security →
Open Anyway** after attempting to open it. Building from source below is another
option. Do not disable Gatekeeper globally.

For automatic startup, add this app in **System Settings → General → Login Items**
and remove the old CatchMouse entry if present.

### Migrating from CatchMouse 1.2

Set your shortcuts again in Preferences; the old app's archived settings are not
imported. For example, record Command-1 and Command-2 if those were your old
bindings. Quit the old app first so it releases the shortcuts.

This replacement moves the cursor to the display center, supports custom
per-monitor shortcuts and cycling, and can identify displays. The old app's
cursor magnification option is not implemented.

### Build from source

Install Apple's Command Line Tools with `xcode-select --install`. Full Xcode is
not required to build the Apple Silicon version or run its regression tests.

```sh
git clone https://github.com/afrozenator/catchmouse-apple-silicon.git
cd catchmouse-apple-silicon
./scripts/test.sh
./build_app.sh
open build/CatchMouse.app
```

The default build is **arm64 only**. Verify it with:

```sh
file build/CatchMouse.app/Contents/MacOS/CatchMouse
codesign --verify --strict build/CatchMouse.app
```

To build a universal arm64 + x86_64 app, use `./build_app.sh universal` with a
toolchain that includes Intel compatibility libraries. Both architectures must
compile successfully; the script never silently falls back to Intel-only. Recent
Apple Silicon-only SDK/toolchain installations may not provide those libraries.

## Shortcuts

| Default shortcut | Action |
| --- | --- |
| Control-Command-comma | Jump to display 1 |
| Control-Command-period | Jump to display 2 |
| Control-Command-slash | Jump to display 3 |
| Control-Option-right arrow | Next display, wrapping around |
| Control-Option-left arrow | Previous display, wrapping around |

Displays are numbered by desktop position: left to right, then top to bottom.
**Identify Displays** briefly shows their numbers. Custom bindings follow each
monitor's UUID across reconnects and reordering; positional defaults follow the
current arrangement. Set extra bindings in Preferences when using more than
three displays.

Click a shortcut field and press the desired combination. Escape cancels;
Delete disables that shortcut and keeps it disabled across restarts. **Reset to
Defaults** restores all defaults. Menu commands still work for disabled shortcuts.
The menu reports duplicate shortcuts and combinations that macOS or another app
has already claimed.

## Command line

The executable inside the app can perform one action and exit:

```sh
build/CatchMouse.app/Contents/MacOS/CatchMouse --list
build/CatchMouse.app/Contents/MacOS/CatchMouse --move 2
build/CatchMouse.app/Contents/MacOS/CatchMouse --move-next
build/CatchMouse.app/Contents/MacOS/CatchMouse --move-prev
build/CatchMouse.app/Contents/MacOS/CatchMouse --preferences
```

`--help` lists options. Display numbers are one-based. Invalid arguments exit
with status 2; cursor movement failures exit with status 1.

## Development and release

```sh
swift build                          # optional SwiftPM debug build
./scripts/test.sh                    # dependency-free regression suite
./build_app.sh                       # optimized native app
swift scripts/smoke_test.swift build/CatchMouse.app/Contents/MacOS/CatchMouse
./scripts/package_app.sh             # ZIP plus SHA-256 checksum in build/
```

For a live movement test, append `--move-cursor` to the smoke-test command. It
moves the pointer to each attached display, checks next/previous wrapping, and
restores its original position. Avoid moving the physical mouse during that test.

GitHub Actions runs regression tests, builds a universal app on a compatible
macOS runner, checks CLI behavior, and uploads a ZIP and checksum as build
artifacts. Release downloads are published separately after validation.

| Source | Purpose |
| --- | --- |
| `DisplayManager.swift` | Core Graphics display coordinates and cursor movement |
| `HotKeyCenter.swift` | Carbon global shortcut registration |
| `HotKeyStore.swift`, `Shortcuts.swift` | Saved per-monitor and cycle shortcuts |
| `AppDelegate.swift`, `StatusMenuController.swift` | Menu-bar lifecycle and shortcut diagnostics |
| `PreferencesWindowController.swift` | Shortcut recording and display identification |
| `CLI.swift` | Scriptable actions |

The fork uses bundle ID `io.github.afrozenator.catchmouse`, keeping its settings
separate from both the original app and the upstream Swift replacement.

## Credits and license

The Swift implementation was written by **zhouyi-xiaoxiao**. This fork retains
its history and [MIT license](LICENSE), and adds mandatory arm64 builds, durable
shortcut disabling, shortcut conflict reporting, input validation, regression
tests, and release packaging. The original CatchMouse concept is by **ftnew.com**.
