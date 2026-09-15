import AppKit
import SwiftUI

enum AnnotateTool: String, CaseIterable, Identifiable {
    case arrow
    case rect
    case text

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arrow: return "Arrow"
        case .rect: return "Rect"
        case .text: return "Text"
        }
    }

    var kind: AnnotationKind {
        switch self {
        case .arrow: return .arrow
        case .rect: return .rect
        case .text: return .text
        }
    }
}

@MainActor
final class AnnotateSession: ObservableObject {
    @Published var image: NSImage
    @Published var strokes: [Stroke] = []
    @Published var tool: AnnotateTool = .arrow
    @Published var draft: Stroke?
    @Published var title: String
    @Published var body: String
    @Published var repo: String
    @Published var errorText: String?
    @Published var warningText: String?
    @Published var statusText: String?
    @Published var isSubmitting = false
    @Published var textDraft = ""
    @Published var textAnchor: AnnoPoint?
    @Published var ocrError: String?

    private let model: AppModel

    init(image: NSImage, ocrText: String, ocrError: String?, model: AppModel) {
        self.image = image
        self.model = model
        self.ocrError = ocrError
        let trimmed = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.split(whereSeparator: \.isNewline).first.map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        self.title = firstLine.isEmpty ? "Screenshot" : firstLine
        self.body = trimmed
        self.repo = model.defaultRepo
    }

    var finalImage: NSImage {
        if strokes.isEmpty {
            return image
        }
        return AnnotationRasterizer.burn(strokes: strokes, onto: image)
    }

    func confirmAnnotations() {
        image = AnnotationRasterizer.burn(strokes: strokes, onto: image)
        strokes = []
        draft = nil
        textAnchor = nil
        textDraft = ""
    }

    func commitText() {
        guard let anchor = textAnchor else { return }
        let text = textDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        textAnchor = nil
        textDraft = ""
        guard !text.isEmpty else { return }
        strokes.append(Stroke(kind: .text, start: anchor, end: anchor, text: text))
    }

    func copyMarkdownOnly() {
        errorText = nil
        warningText = nil
        IssueSubmitter.copyMarkdownOnly(title: title, body: body)
        statusText = "Markdown copied."
    }

    func submit() {
        guard !isSubmitting else { return }
        errorText = nil
        warningText = nil
        statusText = nil
        commitText()
        isSubmitting = true
        let burned = finalImage
        let titleSnapshot = title
        let bodySnapshot = body
        let repoSnapshot = repo
        Task { @MainActor in
            do {
                let validated = try IssueSubmitter.validate(title: titleSnapshot, repo: repoSnapshot)
                let png = try IssueSubmitter.pngData(from: burned)
                _ = try IssueSubmitter.writeTempPNG(png)
                IssueSubmitter.putPNGOnPasteboard(png)
                let outcome = try await Task.detached(priority: .userInitiated) {
                    try IssueSubmitter.createIssue(
                        title: validated.title,
                        body: bodySnapshot,
                        repo: validated.repo
                    )
                }.value
                switch outcome {
                case .created(let url):
                    model.recordTitle(validated.title)
                    model.defaultRepo = validated.repo
                    statusText = url.isEmpty ? "Issue created." : url
                    model.lastStatus = statusText
                    model.bannerWarning = nil
                case .unauthenticated:
                    IssueSubmitter.putMarkdownOnPasteboard(title: validated.title, body: bodySnapshot)
                    model.recordTitle(validated.title)
                    model.defaultRepo = validated.repo
                    let message = "Copied. `gh` not logged in."
                    warningText = message
                    model.bannerWarning = message
                    model.lastStatus = message
                }
            } catch {
                errorText = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}

final class AnnotateWindowHolder: NSObject, NSWindowDelegate {
    static let shared = AnnotateWindowHolder()
    var window: NSWindow?
    var session: AnnotateSession?

    @MainActor
    func present(image: NSImage, ocrText: String, ocrError: String?, model: AppModel) {
        window?.close()
        let session = AnnotateSession(image: image, ocrText: ocrText, ocrError: ocrError, model: model)
        self.session = session
        let root = AnnotateRootView(session: session) { [weak self] in
            self?.window?.performClose(nil)
        }
        .environmentObject(model)
        let hosting = NSHostingView(rootView: root)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 760),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Capture to Issue"
        window.contentView = hosting
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 720, height: 760))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    func windowWillClose(_ notification: Notification) {
        session = nil
        window = nil
    }
}

struct AnnotateRootView: View {
    @ObservedObject var session: AnnotateSession
    var onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let error = session.errorText {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if let warning = session.warningText {
                Label(warning, systemImage: "info.circle")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if let ocrError = session.ocrError {
                Label(ocrError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if let status = session.statusText {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Picker("Tool", selection: $session.tool) {
                ForEach(AnnotateTool.allCases) { tool in
                    Text(tool.title).tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: session.tool) { _, _ in
                session.commitText()
            }

            AnnotationCanvas(session: session)
                .frame(minHeight: 280)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.separator)
                )

            HStack {
                Button("Confirm annotations") {
                    session.confirmAnnotations()
                }
                .disabled(session.strokes.isEmpty && session.draft == nil)
                Spacer()
            }

            TextField("Title", text: $session.title)
            TextField("Repo (owner/repo)", text: $session.repo)
            TextEditor(text: $session.body)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(.separator)
                )

            HStack {
                Button("Copy markdown only") {
                    session.copyMarkdownOnly()
                }
                Spacer()
                Button("Cancel") { onClose() }
                Button(session.isSubmitting ? "Submitting…" : "Submit") {
                    session.submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(session.isSubmitting)
            }
        }
        .padding(16)
        .frame(minWidth: 560, minHeight: 640)
        .animation(reduceMotion ? nil : FunTheme.spring, value: session.strokes.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: session.errorText)
        .animation(reduceMotion ? nil : FunTheme.spring, value: session.warningText)
    }
}

struct AnnotationCanvas: View {
    @ObservedObject var session: AnnotateSession

    var body: some View {
        GeometryReader { geo in
            let fitted = fittedImageRect(imageSize: session.image.size, in: geo.size)
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    context.draw(Image(nsImage: session.image), in: fitted)
                    for stroke in session.strokes {
                        draw(stroke, in: &context, fitted: fitted)
                    }
                    if let draft = session.draft {
                        draw(draft, in: &context, fitted: fitted)
                    }
                }
                .gesture(dragGesture(fitted: fitted, canvasSize: geo.size))
                .onTapGesture { location in
                    handleTap(location, fitted: fitted)
                }

                if session.textAnchor != nil {
                    TextField("Label", text: $session.textDraft)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 180)
                        .position(
                            x: fitted.minX + CGFloat(session.textAnchor?.x ?? 0) * fitted.width,
                            y: fitted.minY + CGFloat(session.textAnchor?.y ?? 0) * fitted.height
                        )
                        .onSubmit { session.commitText() }
                }
            }
        }
        .background(Color.black.opacity(0.08))
    }

    private func dragGesture(fitted: CGRect, canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard session.tool != .text else { return }
                guard let start = normalize(value.startLocation, fitted: fitted),
                      let current = normalize(value.location, fitted: fitted, clamp: true)
                else { return }
                session.draft = Stroke(kind: session.tool.kind, start: start, end: current)
            }
            .onEnded { value in
                guard session.tool != .text else { return }
                guard let start = normalize(value.startLocation, fitted: fitted),
                      let current = normalize(value.location, fitted: fitted, clamp: true)
                else {
                    session.draft = nil
                    return
                }
                session.strokes.append(Stroke(kind: session.tool.kind, start: start, end: current))
                session.draft = nil
            }
    }

    private func handleTap(_ location: CGPoint, fitted: CGRect) {
        guard session.tool == .text else { return }
        session.commitText()
        guard let point = normalize(location, fitted: fitted) else { return }
        session.textAnchor = point
        session.textDraft = ""
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext, fitted: CGRect) {
        let start = denormalize(stroke.start, fitted: fitted)
        let end = denormalize(stroke.end, fitted: fitted)
        switch stroke.kind {
        case .rect:
            let rect = CGRect(
                x: min(start.x, end.x),
                y: min(start.y, end.y),
                width: abs(end.x - start.x),
                height: abs(end.y - start.y)
            )
            context.stroke(Path(rect), with: .color(.red), lineWidth: 2)
        case .arrow:
            context.stroke(arrowPath(start, end), with: .color(.red), lineWidth: 2)
        case .text:
            let text = Text(stroke.text).foregroundColor(.red).font(.system(size: 16, weight: .semibold))
            context.draw(text, at: start, anchor: .topLeading)
        }
    }

    private func arrowPath(_ a: CGPoint, _ b: CGPoint) -> Path {
        var path = Path()
        path.move(to: a)
        path.addLine(to: b)
        let angle = atan2(b.y - a.y, b.x - a.x)
        let len: CGFloat = 12
        path.move(to: b)
        path.addLine(to: CGPoint(x: b.x - len * cos(angle - .pi / 6), y: b.y - len * sin(angle - .pi / 6)))
        path.move(to: b)
        path.addLine(to: CGPoint(x: b.x - len * cos(angle + .pi / 6), y: b.y - len * sin(angle + .pi / 6)))
        return path
    }

    private func fittedImageRect(imageSize: CGSize, in container: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        let scale = min(container.width / imageSize.width, container.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: (container.width - width) / 2,
            y: (container.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func normalize(_ point: CGPoint, fitted: CGRect, clamp: Bool = false) -> AnnoPoint? {
        guard fitted.width > 0, fitted.height > 0 else { return nil }
        var x = (point.x - fitted.minX) / fitted.width
        var y = (point.y - fitted.minY) / fitted.height
        if clamp {
            x = min(max(x, 0), 1)
            y = min(max(y, 0), 1)
            return AnnoPoint(x: Double(x), y: Double(y))
        }
        guard (0...1).contains(x), (0...1).contains(y) else { return nil }
        return AnnoPoint(x: Double(x), y: Double(y))
    }

    private func denormalize(_ point: AnnoPoint, fitted: CGRect) -> CGPoint {
        CGPoint(
            x: fitted.minX + CGFloat(point.x) * fitted.width,
            y: fitted.minY + CGFloat(point.y) * fitted.height
        )
    }
}
