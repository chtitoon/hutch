// Turns design/tokens.json into Hutch/Tokens.swift (colors, radii, spacing, font names),
// design/light/logo.svg into the LogoMark and LogoWord template images in Hutch/Assets.xcassets,
// and design/light/icon.svg into the app icon there.
// The `color-dark` group gives each color role its dark-mode value.
// `swift tokens.swift` writes the files; `--check` fails if any is stale. Run it through `make tokens`.
import AppKit

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let design = root.appending(path: "../../design").standardized
let check = CommandLine.arguments.contains("--check")

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

// MARK: Tokens

typealias Group = [String: Any]
guard let tokens = try? JSONSerialization.jsonObject(with: Data(contentsOf: design.appending(path: "tokens.json"))) as? Group
else { fail("Can't read design/tokens.json") }

/// The groups' roles, sorted so the output is stable (JSON objects have no order once parsed).
func roles(_ group: String) -> [(name: String, value: Any)] {
    guard let node = tokens[group] as? Group else { fail("design/tokens.json has no \(group) group") }
    return node.compactMap { key, value in
        guard !key.hasPrefix("$"), let token = value as? Group, let v = token["$value"] else { return nil }
        return (key, v)
    }
    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
}

/// "ink-muted" → "inkMuted"
func camel(_ name: String) -> String {
    let parts = name.split(separator: "-")
    return parts[0] + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
}

func rgb(_ hex: Any) -> String {
    guard let hex = hex as? String, hex.count == 7, hex.hasPrefix("#"), Int(hex.dropFirst(), radix: 16) != nil
    else { fail("Not a #RRGGBB color: \(hex)") }
    return "0x" + hex.dropFirst()
}

func points(_ value: Any) -> String {
    guard let px = value as? String, px.hasSuffix("px"), let n = Int(px.dropLast(2)) else { fail("Not a px dimension: \(value)") }
    return "\(n)"
}

let dark = Dictionary(uniqueKeysWithValues: roles("color-dark").map { ($0.name, $0.value) })
let lightNames = Set(roles("color").map(\.name))
for name in dark.keys where !lightNames.contains(name) { fail("color-dark has no light role: \(name)") }

let colors = roles("color").map { role in
    let light = rgb(role.value)
    let darkValue = dark[role.name].map(rgb) ?? light
    return "    static let \(camel(role.name)) = Color(light: \(light), dark: \(darkValue))"
}
let radii = roles("radius").map { "    static let \(camel($0.name)): CGFloat = \(points($0.value))" }
let spaces = roles("space").map { "    static let s\($0.name): CGFloat = \(points($0.value))" }
let fonts = roles("font").map { role -> String in
    guard let family = (role.value as? [String])?.first else { fail("Not a font stack: \(role.name)") }
    return "    static let \(camel(role.name)) = \"\(family)\""
}

// MARK: Logo

// The logo file is shapes painted in order on a background square: the first path is the square,
// and paths in the background color are holes in the shape before them. The first colored shape
// is the mark; the rest are the wordmark. Each part becomes one even-odd path, so holes stay holes.
guard let logoSVG = try? String(contentsOf: design.appending(path: "light/logo.svg"), encoding: .utf8)
else { fail("Can't read design/light/logo.svg") }
let paths = logoSVG.matches(of: #/<path[^>]* fill="([^"]*)"[^>]* d="([^"]*)"/#).map { (fill: String($0.1), d: String($0.2)) }
guard let background = paths.first?.fill, paths.count > 2 else { fail("design/light/logo.svg doesn't look like the logo") }
var parts: [[String]] = []
for path in paths.dropFirst() {
    if path.fill == background, !parts.isEmpty { parts[parts.count - 1].append(path.d) }
    else if path.fill != background { parts.append([path.d]) }
}
let mark = parts[0].joined(separator: " ")
let word = parts.dropFirst().joined().joined(separator: " ")

// The drawn area within the file's 2048×1331 canvas, as the website's Logo.astro crops it.
let canvas = (x: 304, y: 460, width: 1440, height: 413)
func logoImage(_ d: String) -> String {
    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="\(canvas.x) \(canvas.y) \(canvas.width) \(canvas.height)" width="\(canvas.width)" height="\(canvas.height)">
    <!-- Generated from design/light/logo.svg by `make tokens`. Do not edit. -->
    <path fill-rule="evenodd" d="\(d)"/>
    </svg>

    """
}
func imageSet(_ name: String) -> String {
    """
    {
      "images" : [ { "filename" : "\(name).svg", "idiom" : "universal" } ],
      "info" : { "author" : "xcode", "version" : 1 },
      "properties" : { "preserves-vector-representation" : true, "template-rendering-intent" : "template" }
    }

    """
}

// MARK: App icon

// design/light/icon.svg is the mark on a background square, painted the same way as the logo.
// The icon redraws its shapes in token colors: the mark in sage-on-deep on the forest, in light and
// dark mode alike, like the app's logo screen. The tinted variant is the mark alone, in white, on
// transparency, for iOS to tint. Each is rendered to a 1024-point PNG, the only size iOS needs.
guard let iconSVG = try? String(contentsOf: design.appending(path: "light/icon.svg"), encoding: .utf8)
else { fail("Can't read design/light/icon.svg") }
let iconPaths = iconSVG.matches(of: #/<path[^>]* d="([^"]*)"/#).map { String($0.1) }
guard iconPaths.count > 1, iconSVG.contains(#"viewBox="0 0 2048 2048""#) else { fail("design/light/icon.svg doesn't look like the icon") }
let iconMark = iconPaths.dropFirst().joined(separator: " ")

func hex(_ group: String, _ role: String) -> String {
    let value = (tokens[group] as? Group)?[role] as? Group
    guard let color = value?["$value"] as? String else { fail("design/tokens.json has no \(group).\(role)") }
    return color
}
func iconImage(background: String?, mark: String) -> Data {
    let backdrop = background.map { #"<rect width="2048" height="2048" fill="\#($0)"/>"# } ?? ""
    let svg = #"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2048 2048" width="1024" height="1024">\#(backdrop)<path fill-rule="evenodd" fill="\#(mark)" d="\#(iconMark)"/></svg>"#
    // The App Store rejects an opaque icon that has an alpha channel, so those render without one.
    let alpha: CGImageAlphaInfo = background == nil ? .premultipliedLast : .noneSkipLast
    let png = NSMutableData()
    guard let image = NSImage(data: Data(svg.utf8)),
          let context = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: alpha.rawValue),
          let output = CGImageDestinationCreateWithData(png, "public.png" as CFString, 1, nil)
    else { fail("Can't render the app icon") }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
    image.draw(in: NSRect(x: 0, y: 0, width: 1024, height: 1024))
    NSGraphicsContext.restoreGraphicsState()
    CGImageDestinationAddImage(output, context.makeImage()!, nil)
    guard CGImageDestinationFinalize(output) else { fail("Can't encode the app icon") }
    return png as Data
}
let forestIcon = iconImage(background: hex("color", "deep"), mark: hex("color", "sage-on-deep"))
let appIconSet = """
{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ], "filename" : "AppIcon-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ], "filename" : "AppIcon-tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}

"""

// MARK: Output

let swift = """
// Generated from design/tokens.json and design/light/logo.svg by `make tokens`. Do not edit.
import SwiftUI

/// Color roles from design/tokens.json. Each switches to its `color-dark` value in dark mode.
enum Palette {
\(colors.joined(separator: "\n"))
}

/// Corner radii, in points.
enum Radius {
\(radii.joined(separator: "\n"))
}

/// The 4-point spacing scale: `s4` is 4 × 4 = 16 points.
enum Space {
\(spaces.joined(separator: "\n"))
}

/// Font family names. Bundle the fonts before using them (M1).
enum FontFamily {
\(fonts.joined(separator: "\n"))
}

/// The shared canvas of the LogoMark and LogoWord images.
enum LogoCanvas {
    static let aspectRatio: CGFloat = \(canvas.width).0 / \(canvas.height).0
}

private extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

"""

let assets = "Hutch/Assets.xcassets"
let outputs: [(path: String, content: Data)] = [
    ("Hutch/Tokens.swift", Data(swift.utf8)),
    ("\(assets)/Contents.json", Data("{\n  \"info\" : { \"author\" : \"xcode\", \"version\" : 1 }\n}\n".utf8)),
    ("\(assets)/LogoMark.imageset/Contents.json", Data(imageSet("LogoMark").utf8)),
    ("\(assets)/LogoMark.imageset/LogoMark.svg", Data(logoImage(mark).utf8)),
    ("\(assets)/LogoWord.imageset/Contents.json", Data(imageSet("LogoWord").utf8)),
    ("\(assets)/LogoWord.imageset/LogoWord.svg", Data(logoImage(word).utf8)),
    ("\(assets)/AppIcon.appiconset/Contents.json", Data(appIconSet.utf8)),
    ("\(assets)/AppIcon.appiconset/AppIcon.png", forestIcon),
    ("\(assets)/AppIcon.appiconset/AppIcon-dark.png", forestIcon),
    ("\(assets)/AppIcon.appiconset/AppIcon-tinted.png", iconImage(background: nil, mark: "#FFFFFF")),
]

for (path, content) in outputs {
    let file = root.appending(path: path)
    if check {
        if (try? Data(contentsOf: file)) != content {
            fail("apps/ios/\(path) is out of date with design/. Run `make tokens`.")
        }
    } else {
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: file, options: .atomic)
    }
}
if !check {
    print("Wrote \(colors.count) colors (\(dark.count) with dark values), \(radii.count) radii, \(spaces.count) spaces, the logo images and the app icon")
}
