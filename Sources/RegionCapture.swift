import AppKit
import Foundation

@MainActor
final class RegionCaptureController {
    static let shared = RegionCaptureController()

    private var overlayWindow: OverlayWindow?
    private var keyMonitor: Any?
    private var continuation: CheckedContinuation<CGRect?, Never>?

    func pickRect() async -> CGRect? {
        if continuation != nil {
            finish(nil)
        }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.showOverlay()
        }
    }

    fileprivate func finish(_ rect: CGRect?) {
        hideOverlay()
        if let continuation {
            self.continuation = nil
            continuation.resume(returning: rect)
        }
    }

    private func showOverlay() {
        hideOverlay()
        NSCursor.crosshair.push()
        let union = NSScreen.screens.map(\.frame).reduce(CGRect.null) { $0.union($1) }
        let window = OverlayWindow(frame: union)
        let view = SelectionView(frame: window.contentView?.bounds ?? union)
        view.autoresizingMask = [.width, .height]
        view.onComplete = { [weak self] rect in
            self?.finish(rect)
        }
        view.onCancel = { [weak self] in
            self?.finish(nil)
        }
        window.contentView = view
        window.sharingType = .none
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        overlayWindow = window
        view.window?.makeFirstResponder(view)

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.finish(nil)
                return nil
            }
            return event
        }
    }

    private func hideOverlay() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if overlayWindow != nil {
            NSCursor.pop()
        }
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(frame: CGRect) {
        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = false
        animationBehavior = .none
        isReleasedWhenClosed = false
        acceptsMouseMovedEvents = true
    }
}

private final class SelectionView: NSView {
    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var downPoint: NSPoint?
    private var didStart = false
    private var selection = NSRect.zero
    private let hysteresis: CGFloat = 4

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        downPoint = convert(event.locationInWindow, from: nil)
        didStart = false
        selection = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = downPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        if !didStart {
            if hypot(point.x - start.x, point.y - start.y) < hysteresis {
                return
            }
            didStart = true
        }
        selection = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            downPoint = nil
            didStart = false
        }
        guard didStart, selection.width >= hysteresis, selection.height >= hysteresis else {
            selection = .zero
            needsDisplay = true
            return
        }
        let windowRect = convert(selection, to: nil)
        guard let window else { return }
        let screenRect = window.convertToScreen(windowRect)
        onComplete?(screenRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.15).setFill()
        bounds.fill()

        let hint = "Drag to select a region. Esc cancels." as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.9)
        ]
        let hintSize = hint.size(withAttributes: attrs)
        let hintPoint = NSPoint(
            x: bounds.midX - hintSize.width / 2,
            y: bounds.maxY - hintSize.height - 36
        )
        hint.draw(at: hintPoint, withAttributes: attrs)

        guard didStart, selection.width > 0, selection.height > 0 else { return }

        if let ctx = NSGraphicsContext.current?.cgContext {
            ctx.saveGState()
            ctx.setBlendMode(.clear)
            ctx.fill(selection)
            ctx.restoreGState()
        }

        NSColor.white.setStroke()
        let border = NSBezierPath(rect: selection.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        let label = "\(Int(selection.width.rounded())) × \(Int(selection.height.rounded()))" as NSString
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let labelSize = label.size(withAttributes: labelAttrs)
        var labelOrigin = NSPoint(x: selection.minX, y: selection.minY - labelSize.height - 6)
        if labelOrigin.y < bounds.minY {
            labelOrigin.y = selection.maxY + 6
        }
        label.draw(at: labelOrigin, withAttributes: labelAttrs)
    }
}
