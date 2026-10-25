// Draws the app icon from the logo's mark, the way apps/web/tokens.mjs draws the favicon:
// the mark from design/light/icon.svg (every path after the background square), in sage,
// from DESIGN.md's tokens. Writes Hutch/Assets.xcassets/AppIcon.appiconset:
// - light: sage mark on the warm off-white background;
// - dark: the dark sage on a clear background, which iOS puts on its own dark;
// - tinted: a grey mark on clear, which iOS tints.
// `swift icon.swift` writes it; `make tokens` runs it.
import AppKit
import Foundation

let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let design = try String(contentsOf: here.appending(path: "../../DESIGN.md"), encoding: .utf8)
let iconSVG = try String(contentsOf: here.appending(path: "../../design/light/icon.svg"), encoding: .utf8)
let target = here.appending(path: "Hutch/Assets.xcassets/AppIcon.appiconset")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("icon.swift: \(message)\n".utf8))
    exit(1)
}

func token(_ name: String) -> String {
    let pattern = try! Regex("\\n  \(name): \"(#[0-9A-Fa-f]{6})\"")
    guard let match = design.firstMatch(of: pattern), let value = match.output[1].substring else { fail("no color \(name)") }
    return String(value)
}

let paths = iconSVG.matches(of: try! Regex("<path[^>]* d=\"([^\"]*)\"")).compactMap { $0.output[1].substring.map(String.init) }
guard paths.count > 1 else { fail("no mark in design/light/icon.svg") }
let mark = paths.dropFirst().joined(separator: " ")

// The mark sits in 583…1463 × 495…1375 (the favicon's box). The icon leaves room around it:
// the mark takes about 62% of the width, centered.
let side = 1420.0
let box = "\(1023 - side / 2) \(935 - side / 2) \(side) \(side)"

func render(_ name: String, mark color: String, background: String?) {
    let backdrop = background.map { "<rect x=\"-10000\" y=\"-10000\" width=\"30000\" height=\"30000\" fill=\"\($0)\"/>" } ?? ""
    let svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"\(box)\" width=\"1024\" height=\"1024\">\(backdrop)<path fill=\"\(color)\" fill-rule=\"evenodd\" d=\"\(mark)\"/></svg>"
    guard let image = NSImage(data: Data(svg.utf8)) else { fail("couldn't draw \(name)") }
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 1024, pixelsHigh: 1024, bitsPerSample: 8, samplesPerPixel: 4,
                                  hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
    NSGraphicsContext.restoreGraphicsState()
    guard let png = bitmap.representation(using: .png, properties: [:]) else { fail("couldn't encode \(name)") }
    try! png.write(to: target.appending(path: name))
}

try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
render("light.png", mark: token("sage"), background: token("background"))
render("dark.png", mark: token("sage-dark"), background: nil)
render("tinted.png", mark: "#8C8C8C", background: nil)

let contents = """
{
  "images" : [
    { "filename" : "light.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ], "filename" : "tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""
try contents.write(to: target.appending(path: "Contents.json"), atomically: true, encoding: .utf8)
print("Wrote \(target.path)")
