// Turns the tokens in DESIGN.md's front matter (the repo root) into Swift, the way
// apps/web/tokens.mjs turns them into CSS. Writes Hutch/Generated/Tokens.swift:
// - Palette: each color role, its -dark token as the dark appearance.
// - Typography: each iPhone type level in its brand font, scaling like the closest Dynamic Type style.
// - Spacing and Radius: the numbered 4px scale and the corners.
// `swift tokens.swift` writes it; `--check` fails if it is stale.
import Foundation

let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let source = try String(contentsOf: here.appending(path: "../../DESIGN.md"), encoding: .utf8)
let target = here.appending(path: "Hutch/Generated/Tokens.swift")

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("tokens.swift: \(message)\n".utf8))
  exit(1)
}

// The front matter is plain YAML: top-level sections, then `key: value` or `key:` with nested
// `prop: value` lines. Only what's needed here is read; the website's linter checks the rest.
guard
  let front = source.split(separator: "---\n", maxSplits: 2, omittingEmptySubsequences: true).first
else {
  fail("DESIGN.md has no front matter")
}
var sections: [String: [(key: String, value: String, props: [String: String])]] = [:]
var section = ""
for raw in front.split(separator: "\n", omittingEmptySubsequences: true) {
  let line = String(raw)
  if line.trimmingCharacters(in: .whitespaces).hasPrefix("#") { continue }
  let indent = line.prefix { $0 == " " }.count
  let content = line.trimmingCharacters(in: .whitespaces)
  guard let colon = content.firstIndex(of: ":") else { continue }
  let key = content[..<colon].trimmingCharacters(in: CharacterSet(charactersIn: "\" "))
  let value = content[content.index(after: colon)...].trimmingCharacters(
    in: CharacterSet(charactersIn: "\" ")
  )
  switch indent {
  case 0: section = key
  case 2: sections[section, default: []].append((key, value, [:]))
  case 4:
    if !(sections[section]?.isEmpty ?? true) {
      sections[section]![sections[section]!.count - 1].props[key] = value
    }
  default: continue
  }
}

func camel(_ name: String) -> String {
  let parts = name.split(separator: "-")
  return parts.first.map(String.init)!
    + parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined()
}

// Colors: the -dark suffix is the dark appearance (D18). `primary` is a reference, not a role.
let colors = (sections["colors"] ?? []).filter { $0.value.hasPrefix("#") }
let dark = Dictionary(
  uniqueKeysWithValues: colors.filter { $0.key.hasSuffix("-dark") }.map {
    (String($0.key.dropLast(5)), $0.value)
  }
)
let light = colors.filter { !$0.key.hasSuffix("-dark") }
for role in dark.keys where !light.contains(where: { $0.key == role }) {
  fail("\(role)-dark has no light role \(role)")
}
if light.isEmpty { fail("no colors found") }
let hex = { (value: String) in "0x" + value.dropFirst().uppercased() }
let paletteLines = light.map { role, value, _ in
  "    static let \(camel(role)) = Color(light: \(hex(value)), dark: \(hex(dark[role] ?? value)))"
}

// Type: the closest Dynamic Type style to each level's iPhone size, at its weight. -wide and
// preview-* levels are web-only (apps/ios/DESIGN.md).
let styles: [(name: String, size: Double)] = [
  ("largeTitle", 34), ("title", 28), ("title2", 22), ("title3", 20), ("body", 17),
  ("callout", 16), ("subheadline", 15), ("footnote", 13), ("caption", 12), ("caption2", 11),
]
let weights = ["400": "regular", "500": "medium", "600": "semibold", "700": "bold"]
let levels = (sections["typography"] ?? []).filter {
  !$0.key.hasSuffix("-wide") && !$0.key.hasPrefix("preview-")
}
if levels.isEmpty { fail("no type levels found") }
// Font families are YAML anchors (`&display Bricolage…`) reused as aliases (`*display`). The
// app bundles each family's font file under its plain name: the web's "Variable" and
// "Fallback" faces and the generic system names are skipped.
var anchors: [String: String] = [:]
func family(_ value: String) -> String? {
  var list = value
  if list.hasPrefix("&"), let space = list.firstIndex(of: " ") {
    anchors[String(list[list.index(after: list.startIndex)..<space])] = String(
      list[list.index(after: space)...]
    )
    list = String(list[list.index(after: space)...])
  } else if list.hasPrefix("*") {
    list = anchors[String(list.dropFirst())] ?? ""
  }
  return list.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    .first {
      !$0.hasSuffix("Variable") && !$0.hasSuffix("Fallback") && !$0.contains("-")
        && $0 != "system-ui"
    }
}
let typeLines = levels.map { level, _, props in
  guard
    let size = props["fontSize"].flatMap({ Double($0.replacingOccurrences(of: "px", with: "")) })
  else { fail("\(level) has no fontSize") }
  guard let weight = props["fontWeight"].flatMap({ weights[$0] }) else {
    fail("\(level) has an unknown fontWeight")
  }
  guard let name = props["fontFamily"].flatMap(family) else { fail("\(level) has no font family") }
  let style = styles.min { abs($0.size - size) < abs($1.size - size) }!.name
  return
    "    static let \(camel(level)) = Font.custom(\"\(name)\", size: \(Int(size)), relativeTo: .\(style)).weight(.\(weight))"
}

let points = { (value: String) in value.replacingOccurrences(of: "px", with: "") }
let spacingLines = (sections["spacing"] ?? []).filter { Int($0.key) != nil }.map {
  "    static let s\($0.key): CGFloat = \(points($0.value))"
}
let radiusLines = (sections["rounded"] ?? []).map {
  "    static let \(camel($0.key)): CGFloat = \(points($0.value))"
}

let output = """
  // Generated by `make tokens` from DESIGN.md. Do not edit: change DESIGN.md and regenerate.
  import SwiftUI

  /// Color roles from DESIGN.md. Each follows the system's light or dark appearance.
  enum Palette {
  \(paletteLines.joined(separator: "\n"))
  }

  /// Type levels from DESIGN.md in the bundled brand fonts, each scaling with the Dynamic Type style closest to its size.
  enum Typography {
  \(typeLines.joined(separator: "\n"))
  }

  /// The 4px spacing scale from DESIGN.md: `s6` is 24 points.
  enum Spacing {
  \(spacingLines.joined(separator: "\n"))
  }

  /// Corner radii from DESIGN.md.
  enum Radius {
  \(radiusLines.joined(separator: "\n"))
  }

  private extension Color {
      init(light: UInt32, dark: UInt32) {
          self.init(uiColor: UIColor { traits in
              let rgb = traits.userInterfaceStyle == .dark ? dark : light
              return UIColor(
                  red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1
              )
          })
      }
  }

  """

if CommandLine.arguments.contains("--check") {
  let current = try? String(contentsOf: target, encoding: .utf8)
  if current != output {
    fail("Hutch/Generated/Tokens.swift is out of date with DESIGN.md. Run: make tokens")
  }
} else {
  try FileManager.default.createDirectory(
    at: target.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  try output.write(to: target, atomically: true, encoding: .utf8)
  print("Wrote \(target.path(percentEncoded: false))")
}
