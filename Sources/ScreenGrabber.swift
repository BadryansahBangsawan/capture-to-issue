import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit

enum CaptureError: LocalizedError {
    case noDisplay
    case emptyRect
    case imageFailed

    var errorDescription: String? {
        switch self {
        case .noDisplay:
            return "No display matched the selection."
        case .emptyRect:
            return "The selected region is empty."
        case .imageFailed:
            return "Could not create an image from the capture."
        }
    }
}

enum ScreenGrabber {
    static func capture(appKitRect: CGRect) async throws -> NSImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let screens = NSScreen.screens
        guard let screen = screens.max(by: {
            $0.frame.intersection(appKitRect).area < $1.frame.intersection(appKitRect).area
        }) else {
            throw CaptureError.noDisplay
        }
        let intersection = screen.frame.intersection(appKitRect)
        if intersection.isNull || intersection.width < 1 || intersection.height < 1 {
            throw CaptureError.emptyRect
        }

        let displayID = screen.displayID
        guard let scDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.noDisplay
        }

        let localX = intersection.origin.x - screen.frame.origin.x
        let localYFromBottom = intersection.origin.y - screen.frame.origin.y
        let localYFromTop = screen.frame.height - localYFromBottom - intersection.height
        var sourceRect = CGRect(
            x: localX,
            y: localYFromTop,
            width: intersection.width,
            height: intersection.height
        )
        sourceRect = sourceRect.intersection(CGRect(origin: .zero, size: screen.frame.size))
        if sourceRect.isNull || sourceRect.width < 1 || sourceRect.height < 1 {
            throw CaptureError.emptyRect
        }

        let scale = screen.backingScaleFactor
        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.sourceRect = sourceRect
        config.width = max(1, Int((sourceRect.width * scale).rounded()))
        config.height = max(1, Int((sourceRect.height * scale).rounded()))
        config.showsCursor = false
        config.scalesToFit = false

        let cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        return NSImage(cgImage: cgImage, size: NSSize(width: sourceRect.width, height: sourceRect.height))
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return (deviceDescription[key] as? NSNumber)?.uint32Value ?? 0
    }
}

extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite else { return 0 }
        return width * height
    }
}
