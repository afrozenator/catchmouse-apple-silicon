import CoreGraphics
import Foundation

let appVersion = "2.2.0"

private let helpText = """
CatchMouse \(appVersion) — jump the mouse cursor between displays.

Running with no arguments launches the menu-bar agent. The verbs below are
scriptable equivalents that move the cursor once and exit:

  --list, -l            List displays (number, id, size, position, main).
  --move <n>            Warp the cursor to the centre of display <n> (1-based).
  --move-next, -n       Warp the cursor to the next display (wraps around).
  --move-prev, -p       Warp the cursor to the previous display (wraps around).
  --version, -v         Print the version.
  --help, -h            Print this help.
  --preferences        Open the menu-bar app's Preferences window.

Global hotkeys when running as the menu-bar agent (defaults — customise each in
the menu-bar app's Preferences…):
  ⌃⌘, / ⌃⌘. / ⌃⌘/      Jump to the left / centre / right display.
  ⌃⌥→ / ⌃⌥←            Cycle to the next / previous display.
"""

/// Handles scriptable verbs. Returns a process exit code.
func runCLI(arguments: [String]) -> Int32 {
    guard let verb = arguments.first else { return 2 }
    let expectedCount = verb == "--move" ? 2 : 1
    guard arguments.count == expectedCount else {
        FileHandle.standardError.write(Data("invalid arguments; see --help\n".utf8))
        return 2
    }
    let displays = DisplayManager()
    func cursor() -> CGPoint { CGEvent(source: nil)?.location ?? .zero }
    func warn(_ message: String) { FileHandle.standardError.write(Data((message + "\n").utf8)) }
    func describe(_ point: CGPoint) -> String { "(\(Int(point.x)),\(Int(point.y)))" }

    switch verb {
    case "--list", "-l":
        let ids = displays.orderedDisplays()
        if ids.isEmpty { print("No displays detected."); return 0 }
        for (index, id) in ids.enumerated() {
            let b = CGDisplayBounds(id)
            let main = (id == CGMainDisplayID()) ? "\tmain" : ""
            print("\(index + 1)\tid=\(id)\t\(Int(b.width))x\(Int(b.height))\t@\(describe(CGPoint(x: b.minX, y: b.minY)))\(main)")
        }
        return 0

    case "--move":
        guard arguments.count > 1, let n = Int(arguments[1]) else {
            warn("usage: --move <displayNumber>"); return 2
        }
        let ids = displays.orderedDisplays()
        guard n >= 1, n <= ids.count else {
            warn("display \(n) out of range (1...\(ids.count))"); return 2
        }
        let from = cursor()
        guard displays.moveCursor(to: ids[n - 1]) == .success else {
            warn("could not move cursor to display \(n)"); return 1
        }
        usleep(40_000)
        print("moved to display \(n): \(describe(from)) -> \(describe(cursor()))")
        return 0

    case "--move-next", "-n":
        let from = cursor()
        guard displays.moveToAdjacentDisplay(forward: true) == .success else {
            warn("could not move cursor to next display"); return 1
        }
        usleep(40_000)
        print("next: \(describe(from)) -> \(describe(cursor()))")
        return 0

    case "--move-prev", "-p":
        let from = cursor()
        guard displays.moveToAdjacentDisplay(forward: false) == .success else {
            warn("could not move cursor to previous display"); return 1
        }
        usleep(40_000)
        print("prev: \(describe(from)) -> \(describe(cursor()))")
        return 0

    case "--version", "-v":
        print("CatchMouse \(appVersion)")
        return 0

    case "--help", "-h":
        print(helpText)
        return 0

    default:
        warn("unknown option: \(arguments[0])\n")
        warn(helpText)
        return 2
    }
}
