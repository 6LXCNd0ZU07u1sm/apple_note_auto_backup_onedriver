import SwiftUI

struct ContentView: View {
    @StateObject private var backup = BackupManager()

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    sourceRow
                    destinationRow
                    statusCard
                    actionButtons
                }
                .padding(20)
            }
        }
        .frame(minWidth: 540, idealWidth: 580, minHeight: 480, idealHeight: 500)
    }

    // MARK: - Sub-views

    private var headerView: some View {
        HStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Apple Notes Backup")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Backup your Notes database to OneDrive")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var sourceRow: some View {
        pathCard(
            label: "Apple Notes Database",
            icon: "cylinder.split.1x2",
            path: backup.sourcePath,
            found: backup.sourceFound,
            placeholder: "Not found – tap Browse to locate manually"
        ) {
            selectFolder(
                title: "Select the Apple Notes Group Container folder",
                handler: backup.setSourcePath
            )
        }
    }

    private var destinationRow: some View {
        pathCard(
            label: "OneDrive Backup Folder",
            icon: "cloud",
            path: backup.destinationPath,
            found: backup.destinationFound,
            placeholder: "Not found – tap Browse to select an OneDrive folder"
        ) {
            selectFolder(
                title: "Select your OneDrive folder",
                canCreate: true,
                handler: { url in backup.setDestinationPath(url + "/AppleNotesBackup") }
            )
        }
    }

    private var statusCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Label(backup.statusMessage, systemImage: "info.circle")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                if backup.isBackingUp {
                    ProgressView(value: backup.progress) {
                        Text("\(Int(backup.progress * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .progressViewStyle(.linear)
                    .animation(.easeInOut(duration: 0.15), value: backup.progress)
                }

                if let date = backup.lastBackupDate {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Last successful backup: ")
                            .font(.caption)
                        Text(date, style: .relative) + Text(" ago")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
        } label: {
            Label("Status", systemImage: "waveform.path.ecg")
                .font(.headline)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                backup.detectPaths()
            } label: {
                Label("Refresh Paths", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(backup.isBackingUp)

            Button {
                Task { await backup.startBackup() }
            } label: {
                Group {
                    if backup.isBackingUp {
                        HStack(spacing: 8) {
                            ProgressView().scaleEffect(0.75)
                            Text("Backing up…")
                        }
                    } else {
                        Label("Start Backup", systemImage: "arrow.up.to.line.circle.fill")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(backup.isBackingUp || !backup.sourceFound || !backup.destinationFound)
        }
    }

    // MARK: - Path card builder

    private func pathCard(
        label: String,
        icon: String,
        path: String,
        found: Bool,
        placeholder: String,
        onBrowse: @escaping () -> Void
    ) -> some View {
        GroupBox {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: found ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(found ? .green : .red)
                    .font(.title3)

                Text(found ? path : placeholder)
                    .font(.caption)
                    .foregroundColor(found ? .primary : .secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Browse", action: onBrowse)
                    .buttonStyle(.bordered)
                    .disabled(backup.isBackingUp)
            }
            .padding(.vertical, 4)
        } label: {
            Label(label, systemImage: icon)
                .font(.headline)
        }
    }

    // MARK: - Folder picker

    private func selectFolder(
        title: String,
        canCreate: Bool = false,
        handler: @escaping (String) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = canCreate
        panel.message = title
        panel.prompt = "Select"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        handler(url.path)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
