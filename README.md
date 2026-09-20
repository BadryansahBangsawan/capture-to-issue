<div align="center">

# Capture to Issue

**Screen-capture a region and file a GitHub issue from the menu bar.**  
macOS menu extra — lives in the menu bar, no Dock icon.

<br/>

[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/capture-to-issue?style=flat-square&color=76B900&label=latest)](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white)](https://swift.org)

<br/>

</div>

---

## Download

| Platform | File |
|---|---|
| **macOS** (Apple Silicon & Intel, macOS 14+) | `CaptureToIssue-*-macos.zip` |

[Go to Releases](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)

---

## Installation

### Homebrew (recommended)

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew install --cask capture-to-issue
```

A **Capture to Issue** icon appears in the menu bar. If Gatekeeper blocks it on first launch:

```bash
xattr -cr /Applications/CaptureToIssue.app && open /Applications/CaptureToIssue.app
```

Or: right-click the app, Open, then Open again. Still blocked? **System Settings → Privacy & Security → Open Anyway**.

### GitHub Releases

1. Download `CaptureToIssue-*-macos.zip` from [Releases](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)
2. Unzip and drag **CaptureToIssue** into Applications
3. On first launch, run the xattr command above if Gatekeeper blocks it

### Build from source

```bash
git clone https://github.com/BadryansahBangsawan/capture-to-issue.git
cd capture-to-issue
bash package-app.sh
open dist/CaptureToIssue.app
```

Requires Xcode Command Line Tools (`xcode-select --install`) and Swift 5.9+.

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Control+Shift+C` | Capture region |

---

## Notes

– Requires Screen Recording permission (prompted on first capture). If the picker never appears or captures stay blank, enable **CaptureToIssue** under **System Settings → Privacy & Security → Screen Recording**, then quit and reopen the app from the menu bar. After a macOS point update, re-toggle that checkbox if captures go blank again.
– Requires gh authenticated to submit real issues (gh auth login).
– OCR is performed locally via Vision framework — no data leaves the machine.
– Captured images are attached directly to the GitHub issue; keep regions under 10 MB to stay within the GitHub API attachment limit.
– No Dock icon; lives entirely in the menu bar.

---

<div align="center">

Made with ♥ for developers who prefer staying in the flow.

</div>
