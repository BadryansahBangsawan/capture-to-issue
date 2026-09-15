import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    static let bundleID = "engineer.badry.capturetoissue"
    static let repoKey = "engineer.badry.capturetoissue.defaultRepo"

    @Published var bannerError: String?
    @Published var bannerWarning: String?
    @Published var history: [HistoryItem] = []
    @Published var historyLoadError: String?
    @Published var defaultRepo: String {
        didSet { UserDefaults.standard.set(defaultRepo, forKey: AppModel.repoKey) }
    }
    @Published var hasScreenAccess = true
    @Published var isCapturing = false
    @Published var lastStatus: String?

    init() {
        defaultRepo = UserDefaults.standard.string(forKey: AppModel.repoKey) ?? ""
        let loaded = HistoryStore.load()
        history = loaded.items
        historyLoadError = loaded.error
    }

    func refreshPermission() async {
        switch await ScreenPermission.check() {
        case .success:
            hasScreenAccess = true
        case .failure(let error):
            hasScreenAccess = false
            bannerError = error.localizedDescription
        }
    }

    func openScreenRecordingSettings() {
        ScreenPermission.openSystemSettings()
    }

    func recordTitle(_ title: String) {
        do {
            try HistoryStore.prepend(title: title, onto: &history)
            historyLoadError = nil
        } catch {
            bannerError = error.localizedDescription
        }
    }

    func beginCapture() {
        bannerError = nil
        bannerWarning = nil
        lastStatus = nil
        guard !isCapturing else { return }
        isCapturing = true
        Task { @MainActor in
            await refreshPermission()
            guard hasScreenAccess else {
                isCapturing = false
                return
            }
            try? await Task.sleep(nanoseconds: 220_000_000)
            let rect = await RegionCaptureController.shared.pickRect()
            guard let rect else {
                isCapturing = false
                return
            }
            try? await Task.sleep(nanoseconds: 90_000_000)
            do {
                let image = try await ScreenGrabber.capture(appKitRect: rect)
                let ocr = await OCRService.recognize(image)
                var ocrText = ""
                var ocrError: String?
                switch ocr {
                case .success(let text):
                    ocrText = text
                case .failure(let error):
                    ocrError = error.localizedDescription
                }
                isCapturing = false
                AnnotateWindowHolder.shared.present(
                    image: image,
                    ocrText: ocrText,
                    ocrError: ocrError,
                    model: self
                )
            } catch {
                isCapturing = false
                bannerError = error.localizedDescription
            }
        }
    }
}
