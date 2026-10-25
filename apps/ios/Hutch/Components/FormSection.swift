import SwiftUI

struct FormSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  init(_ title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.s2) {
      Eyebrow(title)
      content
    }
  }
}

struct CardTextField: View {
  let title: String
  @Binding var text: String
  let prompt: String

  init(_ title: String, text: Binding<String>, prompt: String) {
    self.title = title
    self._text = text
    self.prompt = prompt
  }

  var body: some View {
    TextField(title, text: $text, prompt: Text(prompt))
      .padding(.horizontal, Spacing.s4)
      .frame(minHeight: Spacing.s12)
      .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
      .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(Palette.border))
  }
}

struct SearchField: View {
  @Binding var query: String

  var body: some View {
    HStack(spacing: Spacing.s3) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(Palette.inkMuted)
        .accessibilityHidden(true)
      TextField("Search your things", text: $query, prompt: Text("Where did I put the…"))
        .submitLabel(.search)
    }
    .padding(.horizontal, Spacing.s4)
    .frame(minHeight: Spacing.s12)
    .background(Palette.surface, in: .rect(cornerRadius: Radius.sm))
    .overlay(RoundedRectangle(cornerRadius: Radius.sm).strokeBorder(Palette.border))
  }
}
