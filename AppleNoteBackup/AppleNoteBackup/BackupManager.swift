import Foundation
import Combine

/// Manages the backup of the Apple Notes database to an OneDrive folder.
@MainActor
class BackupManager: ObservableObject {

    // MARK: - Published state

    @Published var isBackingUp = false
    @Published var progress: Double = 0.0
    @Published var statusMessage = "Initializing…"
    @Published var lastBackupDate: Date?

    @Published var sourceFound = false
    @Published var destinationFound = false
    @Published var sourcePath = ""
    @Published var destinationPath = ""

    // MARK: - Constants

    /// Candidate paths for the Apple Notes group container (ordered by likelihood).
    private let candidateNotePaths: [String] = [
        "~/Library/Group Containers/group.com.apple.notes",
        "~/Library/Containers/com.apple.Notes/Data/Library/Notes"
    ]

    /// Candidate paths for OneDrive root folders (ordered by likelihood).
    private let candidateOneDrivePaths: [String] = [
        "~/Library/CloudStorage/OneDrive-Personal",
        "~/Library/CloudStorage/OneDrive - Personal",
        "~/OneDrive",
        "~/OneDrive - Personal",
        "~/OneDrive - Business"
    ]

    // MARK: - Init

    init() {
        detectPaths()
    }

    // MARK: - Path detection

    /// Auto-detects the Apple Notes database folder and the OneDrive root folder.
    func detectPaths() {
        let fm = FileManager.default

        // Notes database
        sourceFound = false
        for raw in candidateNotePaths {
            let path = (raw as NSString).expandingTildeInPath
            if fm.fileExists(atPath: path) {
                sourcePath = path
                sourceFound = true
                break
            }
        }

        // OneDrive root
        destinationFound = false
        for raw in candidateOneDrivePaths {
            let rootPath = (raw as NSString).expandingTildeInPath
            if fm.fileExists(atPath: rootPath) {
                destinationPath = rootPath + "/AppleNotesBackup"
                destinationFound = true
                break
            }
        }

        updateReadyStatus()
    }

    // MARK: - Manual path overrides (called from Browse buttons)

    func setSourcePath(_ path: String) {
        sourcePath = path
        sourceFound = !path.isEmpty
        updateReadyStatus()
    }

    func setDestinationPath(_ path: String) {
        destinationPath = path
        destinationFound = !path.isEmpty
        updateReadyStatus()
    }

    // MARK: - Backup

    /// Starts the backup asynchronously, updating `progress` and `statusMessage` throughout.
    func startBackup() async {
        guard sourceFound, destinationFound else {
            statusMessage = "Cannot backup: source or destination path is missing."
            return
        }

        isBackingUp = true
        progress = 0.0
        statusMessage = "Starting backup…"

        do {
            try await performBackup()
            lastBackupDate = Date()
            progress = 1.0
            statusMessage = "Backup completed successfully! ✓"
        } catch {
            statusMessage = "Backup failed: \(error.localizedDescription)"
        }

        isBackingUp = false
    }

    // MARK: - Private helpers

    private func performBackup() async throws {
        let fm = FileManager.default
        let sourceURL = URL(fileURLWithPath: sourcePath, isDirectory: true)
        let baseDestURL = URL(fileURLWithPath: destinationPath, isDirectory: true)

        // 1. Create the base destination directory if needed.
        statusMessage = "Creating backup folder…"
        progress = 0.05
        try fm.createDirectory(at: baseDestURL, withIntermediateDirectories: true, attributes: nil)

        // 2. Enumerate files in the source directory.
        statusMessage = "Scanning Notes database…"
        progress = 0.15
        let contents = try fm.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        guard !contents.isEmpty else {
            statusMessage = "No files found in the Notes database folder."
            return
        }

        // 3. Create a timestamped sub-folder inside the backup destination.
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stampedURL = baseDestURL.appendingPathComponent(dateFormatter.string(from: Date()))
        try fm.createDirectory(at: stampedURL, withIntermediateDirectories: true, attributes: nil)

        // 4. Copy each file, updating progress after each one.
        let total = Double(contents.count)
        for (index, fileURL) in contents.enumerated() {
            let name = fileURL.lastPathComponent
            statusMessage = "Copying \(name) (\(index + 1) / \(contents.count))…"

            let destFileURL = stampedURL.appendingPathComponent(name)
            if fm.fileExists(atPath: destFileURL.path) {
                try fm.removeItem(at: destFileURL)
            }
            try fm.copyItem(at: fileURL, to: destFileURL)

            // Progress spans 0.15 → 0.95 during file copies.
            progress = 0.15 + (Double(index + 1) / total) * 0.80

            // Yield briefly so the UI can update.
            try await Task.sleep(nanoseconds: 30_000_000) // 30 ms
        }

        // 5. Finalise.
        statusMessage = "Finalizing…"
        progress = 0.98
        try await Task.sleep(nanoseconds: 100_000_000) // 100 ms
    }

    private func updateReadyStatus() {
        if !sourceFound {
            statusMessage = "Apple Notes database not found. Use Browse or open the Notes app first."
        } else if !destinationFound {
            statusMessage = "OneDrive folder not found. Please install and sign in to OneDrive."
        } else {
            statusMessage = "Ready to backup."
        }
    }
}
