# Apple Notes Auto Backup → OneDrive

A lightweight **macOS utility** built with **SwiftUI + Xcode** that backs up the Apple Notes SQLite database to your OneDrive folder and shows live progress.

---

## Features

| Feature | Details |
|---|---|
| 🔍 Auto-detect | Automatically locates the Apple Notes group-container database and your OneDrive folder |
| 📂 Manual Browse | Browse buttons to pick custom source / destination paths via a native folder picker |
| 📊 Live progress | Linear progress bar with percentage and per-file status messages |
| 🕒 Timestamp folders | Each backup is saved in a `yyyy-MM-dd_HH-mm-ss` sub-folder so backups never overwrite each other |
| ✅ Last-backup indicator | Displays how long ago the last successful backup ran |
| 🔄 Refresh | Re-scan all paths without restarting the app |

---

## Requirements

* macOS 13 Ventura or later  
* Xcode 15 or later  
* [Microsoft OneDrive](https://www.microsoft.com/en-us/microsoft-365/onedrive/download) installed and signed-in  

---

## Building in Xcode

```bash
# Clone the repo
git clone <repo-url>
cd apple_note_auto_backup_onedriver

# Open the Xcode project
open AppleNoteBackup/AppleNoteBackup.xcodeproj
```

1. Select the **AppleNoteBackup** scheme in the toolbar.  
2. Choose **My Mac** as the run destination.  
3. Press **⌘R** (Run) — Xcode will build and launch the app.

> **Note:** The app is code-signed with *Automatic* signing. Set your Development Team in  
> *Target → Signing & Capabilities* before archiving for distribution.

---

## How it works

1. **Source detection** — The app searches for the Apple Notes SQLite database at:  
   `~/Library/Group Containers/group.com.apple.notes/`  
   (falls back to `~/Library/Containers/com.apple.Notes/Data/Library/Notes/`)

2. **Destination detection** — The app searches for your OneDrive root at:  
   `~/Library/CloudStorage/OneDrive-Personal/` (and several other common locations).  
   The backup is written to `<OneDrive root>/AppleNotesBackup/<timestamp>/`.

3. **Copy with progress** — All files in the source directory are copied one by one; the progress bar updates after each file.

---

## Tips

* **Close Notes before backing up** to avoid copying an in-flight WAL journal.  
* The app stores **no credentials** and makes **no network calls** — all syncing is handled by the OneDrive desktop client.  
* App Sandbox is intentionally **disabled** so the app can read the Notes group container directly. If you need a sandboxed build for Mac App Store distribution, enable sandboxing and add `com.apple.security.files.user-selected.read-write` in the entitlements, then use the Browse buttons to grant access.

---

## License

MIT — see [LICENSE](LICENSE).
