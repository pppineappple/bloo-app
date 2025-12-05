import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    // Persist simple switches using AppStorage so they survive app restarts
    @AppStorage("privacyMode") private var privacyMode: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @AppStorage("quickLogMode") private var quickLogMode: Bool = false

    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Privacy & Sync
                Section {
                    Toggle(isOn: $privacyMode) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Privacy Mode")
                            }
                        } icon: {
                            Image(systemName: "eye")
                        }
                    }

                    Toggle(isOn: $iCloudSyncEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("iCloud Sync")
                            }
                        } icon: {
                            Image(systemName: "icloud")
                        }
                    }
                } header: {
                    Text("Privacy & Sync")
                }

                // MARK: Tracking
                Section {
                    Toggle(isOn: $quickLogMode) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Quick Log Mode")
                            }
                        } icon: {
                            Image(systemName: "bolt")
                        }
                    }
                } header: {
                    Text("Tracking")
                }

                // MARK: Data
                Section {
                    NavigationLink {
                        ExportPDFView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Export as PDF")
                            }
                        }
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "trash")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Delete All Data")
                            }
                        }
                    }
                    .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                        Button("Delete", role: .destructive) {
                            wipeAllData()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This cannot be undone.")
                    }
                } header: {
                    Text("Data")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .formStyle(.grouped)
        }
    }

    // MARK: - Actions
    private func wipeAllData() {
        // TODO: Replace with your persistence layer wipe (e.g., CoreData/SQLite/UserDefaults)
        privacyMode = false
        iCloudSyncEnabled = true
        quickLogMode = false
        // Add additional resets here
    }
}

// MARK: - Export Placeholder
struct ExportPDFView: View {
    @State private var isExporting = false
    @State private var exportResult: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("Export as PDF")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Create and share a PDF of your tracking history. This is a placeholder view — plug in your real export logic.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: exportPDF) {
                Label("Generate PDF", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)

            if let exportResult {
                Text(exportResult)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Export")
    }

    private func exportPDF() {
        // TODO: Implement PDF rendering of your data
        isExporting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isExporting = false
            exportResult = "Sample PDF generated (mock). Integrate real data and share sheet here."
        }
    }
}

// MARK: - Preview
#Preview("Settings") {
    SettingsView()
}

