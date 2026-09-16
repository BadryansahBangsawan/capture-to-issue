import AppKit
import SwiftUI

enum FunTheme {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 1.0)
    static let panelWidth: CGFloat = 360
    static let panelMinHeight: CGFloat = 420
    static let panelMaxHeight: CGFloat = 560
    static let padding: CGFloat = 16
    static let innerSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 16
    static let rowRadius: CGFloat = 8
}

/// Fills the MenuBarExtra window with an opaque chrome so desktop/terminal cannot bleed through.
final class ExtraPanelBacking: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        window.isOpaque = true
        window.backgroundColor = .windowBackgroundColor
        window.hasShadow = true
        window.contentMinSize = NSSize(width: FunTheme.panelWidth, height: FunTheme.panelMinHeight)
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override var wantsUpdateLayer: Bool { true }
}

struct ExtraPanelBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> ExtraPanelBacking {
        let view = ExtraPanelBacking()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        return view
    }

    func updateNSView(_ nsView: ExtraPanelBacking, context: Context) {
        nsView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }
}

extension View {
    /// Call once on the view `RootView.body` returns. Never only on an inner VStack (that left Repo HUD at ~10pt tall).
    func funPanel() -> some View {
        self
            .frame(width: FunTheme.panelWidth, alignment: .leading)
            .frame(minHeight: FunTheme.panelMinHeight, maxHeight: FunTheme.panelMaxHeight, alignment: .topLeading)
            .font(.system(.body))
            .padding(FunTheme.padding)
            .background(ExtraPanelBackground())
    }

    func extraRowSurface() -> some View {
        self
            .padding(FunTheme.innerSpacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(nsColor: .controlBackgroundColor),
                in: RoundedRectangle(cornerRadius: FunTheme.rowRadius, style: .continuous)
            )
    }
}

struct ExtraSearchField: View {
    let title: String
    let prompt: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            TextField(prompt, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct ExtraEmptyState: View {
    let title: String
    let detail: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ExtraSettingsFooter: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
            Divider()
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.bordered)
        }
    }
}
