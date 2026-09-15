import AppKit
import Foundation
import ScreenCaptureKit

enum ScreenPermission {
    static let prefsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    static func check() async -> Result<Void, Error> {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    static func openSystemSettings() {
        NSWorkspace.shared.open(prefsURL)
    }
}
