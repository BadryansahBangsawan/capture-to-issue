<div align="center">

# Capture to Issue

**Capture a screen region, annotate it, and file a GitHub issue with `gh issue create`.**

Menu extra for macOS 14+. Lives on the **right** of the menu bar. No Dock icon.

<br/>

[![Build](https://github.com/BadryansahBangsawan/capture-to-issue/actions/workflows/ci.yml/badge.svg)](https://github.com/BadryansahBangsawan/capture-to-issue/actions/workflows/ci.yml)
[![Latest Release](https://img.shields.io/github/v/release/BadryansahBangsawan/capture-to-issue?style=flat-square)](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)
[![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)

<br/>

| | |
|---|---|
| Product | `CaptureToIssue` |
| Bundle ID | `engineer.badry.capturetoissue` |
| Cask | `capture-to-issue` |
| Status item | SF Symbol `camera.viewfinder` |
| Panel | opaque ~360×420 pt |

</div>

---

## What you get

| Piece | Behavior |
|---|---|
| **Capture** | Region overlay via ScreenCaptureKit. Esc cancels. |
| **Annotate** | Markup plus OCR before submit. |
| **Submit** | `gh issue create` in the Settings default `owner/repo`. |
| **History** | Recent captures in the panel. Empty: **No captures**. |
| **Login** | Open at Login from Settings (`SMAppService`). |

---

## Download

| File | Use |
|---|---|
| **`CaptureToIssue.app.zip`** | Homebrew cask / unzip, drag **CaptureToIssue** onto **Applications** |

**[Releases](https://github.com/BadryansahBangsawan/capture-to-issue/releases/latest)**

---

## Install

### Homebrew

```bash
brew tap BadryansahBangsawan/mac-menu-apps
brew trust BadryansahBangsawan/mac-menu-apps
brew install --cask capture-to-issue
```

`brew trust` is required on Homebrew 6 or `brew install --cask` refuses the tap.

First open (ad-hoc signed):

```bash
xattr -cr /Applications/CaptureToIssue.app
open /Applications/CaptureToIssue.app
```

Still blocked: System Settings → Privacy & Security → Open Anyway.

Do not run `dist/CaptureToIssue.app` while `/Applications/CaptureToIssue.app` is running (same bundle ID).

---

## How to open

This is an `LSUIElement` extra. Proof it is running is the **camera.viewfinder** status item on the **right** of the menu bar, not a window from Finder or Launchpad.

1. Click that extra. The panel is opaque ~360×420 pt, not a 10px strip.
2. If the bar is full, look behind the Control Center overflow chevron **«**.
3. Double-clicking in Finder/Launchpad only changes the left-side app name. That is expected. There is no Dock icon.

---

## Usage

1. Set **Default repo (owner/repo)** in Settings.
2. **Capture region**, drag, annotate, then submit. Esc dismisses the overlay.
3. Without Screen Recording, capture stays disabled. Use **Open Screen Recording Settings**, then **Relaunch**.
4. Empty history: **No captures**.
5. **Settings** at the bottom: default repo, Open at Login, Quit.

---

## Permissions

**Screen Recording** — usage string in `Info.plist`: *Capture to Issue needs Screen Recording to capture a region of your screen.* Trust is `CGPreflightScreenCaptureAccess()`. Deny is a red **Screen Recording is required to capture a region.** — not a crash.

Ad-hoc `codesign -s -` binds Screen Recording to a **cdhash**. Reinstall is a new identity. System Settings can still show the **old** row as on.

1. Privacy & Security → Screen Recording: toggle **off**, then **on** for Capture to Issue.
2. Click **Relaunch**. macOS does not grant that right to a process that is already running.

---

## Data

| What | Where |
|---|---|
| Default repo | UserDefaults `engineer.badry.capturetoissue.defaultRepo` |
| History | `~/Library/Application Support/Capture to Issue/history.json` |
| Open at Login | `SMAppService.mainApp` (Settings toggle) |

Decode failure → empty list plus a red banner. The extra does not crash.

---

## Privacy

Screenshots and OCR stay on this Mac until you submit. Submit runs `gh issue create` against the repo you set. No other network.

---

## Uninstall

```bash
brew uninstall --cask capture-to-issue
```

Or delete `/Applications/CaptureToIssue.app`. Then:

```bash
rm -rf "$HOME/Library/Application Support/Capture to Issue"
```

Turn off **Capture to Issue** in System Settings → General → Login Items if it remains.

---

## Troubleshooting

| What you see | What to do |
|---|---|
| Finder “opens” nothing / no Dock icon | Click the **camera.viewfinder** extra on the right of the menu bar. |
| Extra missing | Overflow **«**, or `pgrep -x CaptureToIssue` then `open /Applications/CaptureToIssue.app`. |
| “Damaged” / cannot verify | `xattr -cr /Applications/CaptureToIssue.app`. `spctl --assess` is `rejected` even when it runs. |
| `brew install --cask` refuses the tap | `brew trust BadryansahBangsawan/mac-menu-apps` |
| **Screen Recording is required to capture a region.** | Toggle off/on, then **Relaunch** (cdhash). Path: System Settings → Privacy & Security → Screen Recording. After a macOS point update, re-toggle if captures stay blank. |
| Submit does nothing useful | `gh auth status`; set `owner/repo` in Settings. |
| ~10px empty strip under the bar | Reinstall from this repo. |

---

## Build from source

```bash
git clone https://github.com/BadryansahBangsawan/capture-to-issue.git
cd capture-to-issue
swift build -c release --product CaptureToIssue
bash package-app.sh
open dist/CaptureToIssue.app
```

Tag `v*` runs CI: `CaptureToIssue.app.zip`. Never commit `dist/`.

Layout: `Sources/` (SwiftPM executable), `Info.plist`, `Assets/AppIcon.icns`, `package-app.sh`. `FunTheme.swift` is copied verbatim (no shared package).

---

## FAQ

**Why is there no Dock icon?**  
It is a menu extra. Click the camera.viewfinder item on the **right** of the menu bar.

**Does this watch a screenshot folder?**  
No. It captures a region with Screen Recording.

**Where did the captures go?**  
`~/Library/Application Support/Capture to Issue/history.json`. Submit also creates a GitHub issue in the default repo.

**How do I stop it opening at login?**  
Settings in the panel, or System Settings → General → Login Items → **Capture to Issue**.

---

<div align="center">

[MIT](LICENSE)

</div>
