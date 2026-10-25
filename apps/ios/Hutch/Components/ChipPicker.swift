import SwiftUI

/// Tapping the picked chip again clears the selection.
struct ChipPicker: View {
  let options: [String]
  @Binding var selection: String

  var body: some View {
    FlowLayout(spacing: Spacing.s2) {
      ForEach(options, id: \.self) { option in
        let isSelected = isPicked(option)
        Button(option) { selection = isSelected ? "" : option }
          .buttonStyle(.chip(isSelected: isSelected))
          .accessibilityAddTraits(isSelected ? .isSelected : [])
      }
    }
  }

  private func isPicked(_ option: String) -> Bool {
    option.caseInsensitiveCompare(selection.trimmingCharacters(in: .whitespaces)) == .orderedSame
  }
}

struct FlowLayout: Layout {
  var spacing: CGFloat

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let lines = lines(of: subviews, fitting: proposal.width ?? .infinity)
    let height = lines.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, lines.count - 1))
    return CGSize(width: proposal.width ?? lines.map(\.width).max() ?? 0, height: height)
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var y = bounds.minY
    for line in lines(of: subviews, fitting: bounds.width) {
      var x = bounds.minX
      for index in line.indices {
        let size = subviews[index].sizeThatFits(.unspecified)
        subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
        x += size.width + spacing
      }
      y += line.height + spacing
    }
  }

  private struct Line {
    var indices: [Int] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
  }

  private func lines(of subviews: Subviews, fitting width: CGFloat) -> [Line] {
    var lines: [Line] = []
    var current = Line()
    for index in subviews.indices {
      let size = subviews[index].sizeThatFits(.unspecified)
      let widthWithView =
        current.indices.isEmpty ? size.width : current.width + spacing + size.width
      if widthWithView > width, !current.indices.isEmpty {
        lines.append(current)
        current = Line()
      }
      current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
      current.height = max(current.height, size.height)
      current.indices.append(index)
    }
    if !current.indices.isEmpty {
      lines.append(current)
    }
    return lines
  }
}

#Preview {
  @Previewable @State var room = "Garage"
  ChipPicker(options: ["Garage", "Attic", "Kitchen", "Living Room", "Office"], selection: $room)
    .padding()
    .brand()
}
