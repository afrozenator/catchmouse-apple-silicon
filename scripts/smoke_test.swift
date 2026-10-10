#!/usr/bin/env swift
// Verifies the release executable. Cursor tests are opt-in and restore its position.
import Foundation
import CoreGraphics

struct SmokeFailure: Error { let message: String }
func require(_ condition: Bool, _ message: String) throws {
    if !condition { throw SmokeFailure(message: message) }
}

try require(CommandLine.arguments.count >= 2, "usage: swift scripts/smoke_test.swift <binary> [--move-cursor]")
let binary = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL

func run(_ args: [String], expected: Int32 = 0) throws -> String {
    let process = Process()
    process.executableURL = binary
    process.arguments = args
    let output = Pipe()
    process.standardOutput = output
    process.standardError = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let text = String(decoding: data, as: UTF8.self)
    try require(process.terminationStatus == expected, "\(args): exit \(process.terminationStatus), \(text)")
    return text
}

let version = try run(["--version"])
try require(version.hasPrefix("CatchMouse 2.2.0"), "version mismatch")
try require(try run(["--help"]).contains("--preferences"), "missing Preferences help")
print(try run(["--list"]), terminator: "")
for args in [["--move"], ["--move", "0"], ["--move", "999999"],
             ["--move", "abc"], ["--unknown"], ["--version", "extra"],
             ["--move", "1", "extra"], ["--preferences", "--unknown"]] {
    _ = try run(args, expected: 2)
}

if CommandLine.arguments.contains("--move-cursor") {
    var count: UInt32 = 0
    try require(CGGetActiveDisplayList(0, nil, &count) == .success && count > 0, "no active displays")
    var ids = [CGDirectDisplayID](repeating: 0, count: Int(count))
    try require(CGGetActiveDisplayList(count, &ids, &count) == .success, "display enumeration failed")
    ids = Array(ids.prefix(Int(count))).sorted {
        let a = CGDisplayBounds($0), b = CGDisplayBounds($1)
        return a.minX != b.minX ? a.minX < b.minX : a.minY < b.minY
    }
    let original = CGEvent(source: nil)!.location
    defer { CGWarpMouseCursorPosition(original); CGAssociateMouseAndMouseCursorPosition(1) }

    func checkCenter(_ index: Int) throws {
        let bounds = CGDisplayBounds(ids[index])
        let point = CGEvent(source: nil)!.location
        try require(abs(point.x - bounds.midX) <= 2 && abs(point.y - bounds.midY) <= 2,
                "display \(index + 1): expected \(bounds.midX),\(bounds.midY); got \(point)")
    }

    for index in ids.indices {
        print(try run(["--move", String(index + 1)]), terminator: "")
        try checkCenter(index)
    }
    _ = try run(["--move-next"])
    try checkCenter(0)
    _ = try run(["--move-prev"])
    try checkCenter(ids.count - 1)
    print("Cursor movement and cycle wrapping passed on \(ids.count) displays.")
}
print("Release smoke tests passed.")
