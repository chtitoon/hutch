import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
  @Environment(\.isEnabled) private var isEnabled

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Typography.labelLg)
      .foregroundStyle(Palette.onDeep)
      .frame(maxWidth: .infinity, minHeight: Spacing.s12)
      .background(Palette.deep, in: .capsule)
      .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
  }
}

struct OutlinedButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Typography.labelLg)
      .foregroundStyle(Palette.ink)
      .frame(maxWidth: .infinity, minHeight: Spacing.s12)
      .overlay(Capsule().strokeBorder(Palette.border))
      .clipShape(.capsule)
      .opacity(configuration.isPressed ? 0.6 : 1)
  }
}

struct ChipButtonStyle: ButtonStyle {
  let isSelected: Bool

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Typography.labelMd)
      .foregroundStyle(isSelected ? Palette.background : Palette.ink)
      .padding(.horizontal, Spacing.s4)
      .frame(minHeight: Spacing.s10)
      .background(isSelected ? Palette.ink : .clear, in: .capsule)
      .overlay(Capsule().strokeBorder(isSelected ? .clear : Palette.border))
      // Without the clip, the outline's anti-aliasing leaves marks past the capsule's ends.
      .clipShape(.capsule)
      .opacity(configuration.isPressed ? 0.6 : 1)
  }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
  static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == OutlinedButtonStyle {
  static var outlined: OutlinedButtonStyle { OutlinedButtonStyle() }
}

extension ButtonStyle where Self == ChipButtonStyle {
  static func chip(isSelected: Bool) -> ChipButtonStyle { ChipButtonStyle(isSelected: isSelected) }
}
