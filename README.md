# Capture to Issue

Capture a screen region, annotate it, and file a GitHub issue with `gh`.

Menu extra for macOS 14+. It lives in the menu bar and does not show a Dock icon.

## Features

- Region overlay; Esc cancels.
- OCR + annotation before submit.
- Creates an issue with `gh issue create` in the default `owner/repo`.
- Recent captures in the panel.
- Screen Recording denied shows a red label and a Settings CTA — no crash.

## Requirements

- macOS 14 Sonoma or later
- Swift 5.9 or later
- Screen Recording permission
- `gh` authenticated if you want Submit to open a real issue

## Install

Homebrew (macOS 14+):

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask capture-to-issue
```

Opens as a menu extra (no Dock icon). The cask is ad-hoc signed. If Gatekeeper blocks it:

```bash
xattr -cr /Applications/CaptureToIssue.app
```

Build from source:

```bash
git clone https://github.com/BadryansahBangsawan/capture-to-issue.git
cd capture-to-issue
bash package-app.sh
open dist/CaptureToIssue.app
```

Enable **Open at Login** from Settings if you want it after reboot.

## Usage

- Set **Default repo (owner/repo)** in Settings.
- **Capture region**, drag, annotate, then submit. Esc dismisses the overlay.
- Without Screen Recording, capture stays disabled.

## Permissions

- **Screen Recording** — `NSScreenCaptureUsageDescription` is set. Deny is a banner, not a crash.

Denied permissions must not crash the app. You should see a banner and a button to open System Settings.

## Privacy

Screenshots stay on disk until you submit. Submit sends them to GitHub via `gh` for the repo you configured. No other upload.

Bundle ID: `engineer.badry.capturetoissue`.

## Development

```bash
swift build
swift build -c release --product CaptureToIssue
```

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`.

## License

[MIT](LICENSE)
