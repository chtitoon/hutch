import SwiftUI

struct Eyebrow: View {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var body: some View {
    Text(text.uppercased())
      .font(Typography.labelCaps)
      // label-caps' letterSpacing: 0.08em of its 14px. Tokens.swift carries no tracking yet.
      .tracking(14 * 0.08)
      .foregroundStyle(Palette.sage)
  }
}

/// Said once, on Home (non-negotiable 2). Uses the logo's mark, never a padlock (DESIGN.md).
struct PrivateBadge: View {
  var body: some View {
    Label {
      Text("On this phone only")
    } icon: {
      Image(.mark)
        .resizable()
        .scaledToFit()
        .frame(width: Spacing.s4, height: Spacing.s4)
        .foregroundStyle(Palette.sage)
    }
    .font(Typography.labelSm)
    .foregroundStyle(Palette.onSageTint)
    .padding(.horizontal, Spacing.s3)
    .padding(.vertical, Spacing.s2)
    .background(Palette.sageTint, in: .capsule)
  }
}

struct AddButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "plus")
        .font(Typography.headlineMd)
        .foregroundStyle(Palette.onDeep)
        .frame(width: Spacing.s16, height: Spacing.s16)
        .background(Palette.deep, in: .circle)
    }
    .accessibilityLabel("Add an item")
    .padding(.bottom, Spacing.s2)
  }
}

#Preview {
  VStack(spacing: Spacing.s6) {
    Eyebrow("Where it lives")
    PrivateBadge()
    AddButton {}
  }
  .brand()
}
