import AppKit
import CoreGraphics
import Foundation

enum ScreenPermission {
    static let prefsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!

    static func isTrusted() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func openSystemSettings() {
        NSWorkspace.shared.open(prefsURL)
    }

    static func relaunch() {
        let path = Bundle.main.bundlePath
        let escaped = "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", "sleep 0.4; /usr/bin/open \(escaped)"]
        try? proc.run()
        NSApp.terminate(nil)
    }
}
