import SwiftUI
import UserNotifications

// MARK: - SettingsView
struct SettingsView: View {
    // Persist simple switches using AppStorage so they survive app restarts
    @AppStorage("privacyMode") private var privacyMode: Bool = false
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled: Bool = true
    @AppStorage("quickLogMode") private var quickLogMode: Bool = false

    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("reminderIntervalHours") private var reminderIntervalHours: Int = 2 // 2,3,4 only
    @AppStorage("reminderStartTime") private var reminderStartTime: Double = defaultTime(hour: 8, minute: 0)
    @AppStorage("reminderEndTime") private var reminderEndTime: Double = defaultTime(hour: 20, minute: 0)

    private var startDate: Date { Date(timeIntervalSince1970: reminderStartTime) }
    private var endDate: Date { Date(timeIntervalSince1970: reminderEndTime) }

    @State private var showDeleteAlert = false

    private static func defaultTime(hour: Int, minute: Int) -> Double {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour; comps.minute = minute; comps.second = 0
        return (Calendar.current.date(from: comps) ?? Date()).timeIntervalSince1970
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Reminders
                Section {
                    Toggle(isOn: $reminderEnabled) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("2–4h Reminders")
                            }
                        } icon: {
                            Image(systemName: "bell")
                        }
                    }

                    Picker("Interval", selection: $reminderIntervalHours) {
                        Text("Every 2 hours").tag(2)
                        Text("Every 3 hours").tag(3)
                        Text("Every 4 hours").tag(4)
                    }
                    .pickerStyle(.menu)
                    .disabled(!reminderEnabled)

                    DatePicker("Start time", selection: Binding(
                        get: { startDate },
                        set: { reminderStartTime = $0.timeIntervalSince1970 }
                    ), displayedComponents: .hourAndMinute)
                    .disabled(!reminderEnabled)

                    DatePicker("End time", selection: Binding(
                        get: { endDate },
                        set: { reminderEndTime = $0.timeIntervalSince1970 }
                    ), displayedComponents: .hourAndMinute)
                    .disabled(!reminderEnabled)

                    HStack {
                        Button(role: .none) { applyReminderSchedule() } label: {
                            Label("Apply Schedule", systemImage: "calendar.badge.plus")
                        }
                        .disabled(!reminderEnabled)

                        Button(role: .destructive) { clearReminderSchedule() } label: {
                            Label("Clear", systemImage: "calendar.badge.minus")
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Choose 2, 3, or 4 hour intervals between a start and end time. We'll create daily repeating notifications at those times.")
                }

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

    private func applyReminderSchedule() {
        requestNotificationPermission { granted in
            guard granted else { return }
            scheduleReminders()
        }
    }

    private func clearReminderSchedule() {
        let ids = scheduledIdentifiers()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                completion(true)
            case .denied:
                completion(false)
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    completion(granted)
                }
            @unknown default:
                completion(false)
            }
        }
    }

    private func scheduleReminders() {
        // Clear existing first
        clearReminderSchedule()

        // Build the daily times between start and end with the chosen interval
        let calendar = Calendar.current
        var start = calendar.date(bySettingHour: calendar.component(.hour, from: startDate), minute: calendar.component(.minute, from: startDate), second: 0, of: Date()) ?? Date()
        let end = calendar.date(bySettingHour: calendar.component(.hour, from: endDate), minute: calendar.component(.minute, from: endDate), second: 0, of: Date()) ?? Date()

        var times: [Date] = []
        var current = start

        func appendIfInDay(_ d: Date) {
            let comps = calendar.dateComponents([.hour, .minute], from: d)
            if let hh = comps.hour, let mm = comps.minute {
                // create a normalized time today
                if let normalized = calendar.date(bySettingHour: hh, minute: mm, second: 0, of: Date()) {
                    times.append(normalized)
                }
            }
        }

        if start <= end {
            while current <= end {
                appendIfInDay(current)
                current = calendar.date(byAdding: .hour, value: reminderIntervalHours, to: current) ?? current
                if current == start { break }
            }
        } else {
            // Wrap across midnight: schedule from start -> 24:00 and 00:00 -> end
            let midnight = calendar.startOfDay(for: Date()).addingTimeInterval(24*60*60 - 1)
            while current <= midnight {
                appendIfInDay(current)
                current = calendar.date(byAdding: .hour, value: reminderIntervalHours, to: current) ?? current
                if current == start { break }
            }
            current = calendar.startOfDay(for: Date())
            while current <= end {
                appendIfInDay(current)
                current = calendar.date(byAdding: .hour, value: reminderIntervalHours, to: current) ?? current
            }
        }

        let center = UNUserNotificationCenter.current()
        for t in times {
            let comps = calendar.dateComponents([.hour, .minute], from: t)
            let content = UNMutableNotificationContent()
            content.title = "Time to log"
            content.body = "Quick check-in every \(reminderIntervalHours)h."
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            let id = identifierFor(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(req)
        }
    }

    private func identifierFor(hour: Int, minute: Int) -> String {
        "bloo.reminder." + String(format: "%02d:%02d", hour, minute)
    }

    private func scheduledIdentifiers() -> [String] {
        let calendar = Calendar.current
        var ids: [String] = []
        var start = calendar.date(bySettingHour: calendar.component(.hour, from: startDate), minute: calendar.component(.minute, from: startDate), second: 0, of: Date()) ?? Date()
        let end = calendar.date(bySettingHour: calendar.component(.hour, from: endDate), minute: calendar.component(.minute, from: endDate), second: 0, of: Date()) ?? Date()

        if start <= end {
            while start <= end {
                let c = calendar.dateComponents([.hour, .minute], from: start)
                ids.append(identifierFor(hour: c.hour ?? 0, minute: c.minute ?? 0))
                start = calendar.date(byAdding: .hour, value: reminderIntervalHours, to: start) ?? start
                if start == Date(timeIntervalSince1970: reminderStartTime) { break }
            }
        } else {
            let midnight = calendar.startOfDay(for: Date()).addingTimeInterval(24*60*60 - 1)
            while start <= midnight {
                let c = calendar.dateComponents([.hour, .minute], from: start)
                ids.append(identifierFor(hour: c.hour ?? 0, minute: c.minute ?? 0))
                start = calendar.date(byAdding: .hour, value: reminderIntervalHours, to: start) ?? start
                if start == Date(timeIntervalSince1970: reminderStartTime) { break }
            }
            var early = calendar.startOfDay(for: Date())
            while early <= end {
                let c = calendar.dateComponents([.hour, .minute], from: early)
                ids.append(identifierFor(hour: c.hour ?? 0, minute: c.minute ?? 0))
                early = calendar.date(byAdding: .hour, value: reminderIntervalHours, to: early) ?? early
            }
        }
        return ids
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

private func defaultTime(hour: Int, minute: Int) -> Double {
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    comps.hour = hour; comps.minute = minute; comps.second = 0
    return (Calendar.current.date(from: comps) ?? Date()).timeIntervalSince1970
}
