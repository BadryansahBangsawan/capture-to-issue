import AppKit
import Foundation
import Vision

enum OCRError: LocalizedError {
    case noCGImage

    var errorDescription: String? {
        switch self {
        case .noCGImage:
            return "Could not read the captured image for OCR."
        }
    }
}

enum OCRService {
    static func recognize(_ image: NSImage) async -> Result<String, Error> {
        await Task.detached(priority: .userInitiated) {
            do {
                guard let cgImage = image.bestCGImage else {
                    throw OCRError.noCGImage
                }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try handler.perform([request])
                let lines = (request.results ?? []).compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                return .success(lines.joined(separator: "\n"))
            } catch {
                return .failure(error)
            }
        }.value
    }
}

extension NSImage {
    var bestCGImage: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        if let cgImage = cgImage(forProposedRect: &rect, context: nil, hints: nil) {
            return cgImage
        }
        for rep in representations {
            if let bitmap = rep as? NSBitmapImageRep, let cgImage = bitmap.cgImage {
                return cgImage
            }
        }
        return nil
    }
}
