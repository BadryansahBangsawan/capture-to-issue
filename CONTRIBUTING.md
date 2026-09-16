# Contributing

Thanks for improving Capture to Issue.

End users install with `brew tap BadryansahBangsawan/mac-menu-apps` and `brew install --cask capture-to-issue`. This file is for source contributors.

## Build

macOS 14 or later and Swift 5.9+ (Xcode or Command Line Tools):

```bash
swift build
bash package-app.sh
open dist/CaptureToIssue.app
```

Do not commit `dist/`, `.build/`, `.swiftpm/`, or secrets.

## Changes

- Keep the app a menu extra (`LSUIElement`). Do not add a Dock icon.
- Surface failures as a red label with a useful message. Do not `fatalError` on runtime paths, swallow errors with `try?`, or use empty `catch`.
- Match existing SwiftUI / AppKit patterns in `Sources/`. Do not add a shared package or extra targets.
- App Sandbox stays off. Do not add a paid Team ID requirement.

## Pull requests

Open against `main`. Describe the user-visible change and how you ran the app after packaging.
