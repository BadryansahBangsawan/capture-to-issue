import AppKit
import Foundation

enum AnnotationKind: String, Codable, Equatable {
    case arrow
    case rect
    case text
}

struct AnnoPoint: Codable, Equatable {
    var x: Double
    var y: Double

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(_ point: CGPoint) {
        self.x = Double(point.x)
        self.y = Double(point.y)
    }
}

struct Stroke: Codable, Identifiable, Equatable {
    var id: UUID
    var kind: AnnotationKind
    var start: AnnoPoint
    var end: AnnoPoint
    var text: String

    init(id: UUID = UUID(), kind: AnnotationKind, start: AnnoPoint, end: AnnoPoint, text: String = "") {
        self.id = id
        self.kind = kind
        self.start = start
        self.end = end
        self.text = text
    }
}

enum AnnotationRasterizer {
    static func burn(strokes: [Stroke], onto image: NSImage) -> NSImage {
        guard let cgImage = image.bestCGImage else { return image }
        let pixelWidth = cgImage.width
        let pixelHeight = cgImage.height
        guard pixelWidth > 0, pixelHeight > 0 else { return image }
        let pixelSize = NSSize(width: pixelWidth, height: pixelHeight)
        let width = Double(pixelWidth)
        let height = Double(pixelHeight)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelWidth,
            pixelsHigh: pixelHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return image
        }

        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            NSGraphicsContext.restoreGraphicsState()
            return image
        }
        NSGraphicsContext.current = context

        NSImage(cgImage: cgImage, size: pixelSize).draw(
            in: NSRect(origin: .zero, size: pixelSize),
            from: .zero,
            operation: .copy,
            fraction: 1.0
        )

        let color = NSColor.systemRed
        color.setStroke()
        color.setFill()

        func map(_ point: AnnoPoint) -> NSPoint {
            NSPoint(x: point.x * width, y: (1 - point.y) * height)
        }

        for stroke in strokes {
            let p1 = map(stroke.start)
            let p2 = map(stroke.end)
            switch stroke.kind {
            case .rect:
                let rect = NSRect(
                    x: min(p1.x, p2.x),
                    y: min(p1.y, p2.y),
                    width: abs(p2.x - p1.x),
                    height: abs(p2.y - p1.y)
                )
                let path = NSBezierPath(rect: rect)
                path.lineWidth = 3
                path.stroke()
            case .arrow:
                let path = NSBezierPath()
                path.move(to: p1)
                path.line(to: p2)
                let angle = atan2(p2.y - p1.y, p2.x - p1.x)
                let head: CGFloat = 18
                path.move(to: p2)
                path.line(to: NSPoint(
                    x: p2.x - head * cos(angle - .pi / 6),
                    y: p2.y - head * sin(angle - .pi / 6)
                ))
                path.move(to: p2)
                path.line(to: NSPoint(
                    x: p2.x - head * cos(angle + .pi / 6),
                    y: p2.y - head * sin(angle + .pi / 6)
                ))
                path.lineWidth = 3
                path.lineJoinStyle = .round
                path.lineCapStyle = .round
                path.stroke()
            case .text:
                let fontSize = max(14, CGFloat(pixelHeight) * 0.03)
                let font = NSFont.systemFont(ofSize: fontSize, weight: .semibold)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let text = stroke.text as NSString
                let textSize = text.size(withAttributes: attrs)
                text.draw(at: NSPoint(x: p1.x, y: p1.y - textSize.height), withAttributes: attrs)
            }
        }

        NSGraphicsContext.restoreGraphicsState()
        let out = NSImage(size: image.size)
        out.addRepresentation(rep)
        return out
    }
}
