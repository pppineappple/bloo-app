import SwiftUI

struct Drink: Identifiable {
    let id = UUID()
    let ko: String
    let en: String
}

struct HomeView: View {
    // ▶︎ 여기만 수정하면 항목/개수/순서 전부 자동 반영
    private let drinks: [Drink] = [
        .init(ko: "물", en: "Water"),
        .init(ko: "카페인", en: "Caffeine"),
        .init(ko: "소다",   en: "Soda"),
        .init(ko: "주스", en: "Juice"),
        .init(ko: "술", en: "Alcohol"),
        .init(ko: "others", en: "Others")
    ]
    
    // ▶︎ 열 수만 바꾸면 2xN, 3xN 등 손쉽게 변경
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    // Reminder settings (shared with SettingsView)
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("reminderIntervalHours") private var reminderIntervalHours: Int = 4 // default 4h for this card
    @AppStorage("reminderStartTime") private var reminderStartTime: Double = 0
    @AppStorage("reminderEndTime") private var reminderEndTime: Double = 0

    // Build today's schedule based on settings (fallback: 08:00–20:00 every 4h)
    private func scheduleTimes() -> [Date] {
        let cal = Calendar.current
        let now = Date()

        func time(_ base: Double, fallbackHour: Int) -> Date {
            if base == 0 { // fallback
                var c = cal.dateComponents([.year,.month,.day], from: now)
                c.hour = fallbackHour; c.minute = 0; c.second = 0
                return cal.date(from: c) ?? now
            } else {
                let stored = Date(timeIntervalSince1970: base)
                let h = cal.component(.hour, from: stored)
                let m = cal.component(.minute, from: stored)
                var c = cal.dateComponents([.year,.month,.day], from: now)
                c.hour = h; c.minute = m; c.second = 0
                return cal.date(from: c) ?? now
            }
        }

        let start = time(reminderStartTime, fallbackHour: 8)
        let end   = time(reminderEndTime,   fallbackHour: 20)
        let interval = reminderIntervalHours == 0 ? 4 : reminderIntervalHours

        var times: [Date] = []
        var cur = start
        if start <= end {
            while cur <= end {
                times.append(cur)
                cur = cal.date(byAdding: .hour, value: interval, to: cur) ?? cur
                if times.count > 24 { break }
            }
        } else {
            // wrap midnight
            let midnight = cal.startOfDay(for: now).addingTimeInterval(24*60*60)
            while cur < midnight {
                times.append(cur)
                cur = cal.date(byAdding: .hour, value: interval, to: cur) ?? cur
                if times.count > 24 { break }
            }
            var next = cal.startOfDay(for: now)
            while next <= end {
                times.append(next)
                next = cal.date(byAdding: .hour, value: interval, to: next) ?? next
                if times.count > 24 { break }
            }
        }
        return times
    }

    private var completedCount: Int {
        let now = Date()
        return scheduleTimes().filter { $0 <= now }.count
    }

    private var nextMinutesText: String {
        let now = Date()
        guard let next = scheduleTimes().first(where: { $0 > now }) else { return "All done for today" }
        let minutes = Int(next.timeIntervalSince(now) / 60.0)
        return "\(minutes) minutes for next cycle"
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                StreakCard(title: "You're on a roll!",
                           subtitle: nextMinutesText,
                           total: max(scheduleTimes().count, 1),
                           completed: completedCount)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(drinks) { d in
                        Button {
                            print(d.en)
                        } label: {
                            Text(d.ko)
                                .font(.system(size: 22, weight: .medium))
                                .frame(maxWidth: .infinity, minHeight: 72)
                                .background(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color(.separator), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .foregroundStyle(.black)
                        }
                    }
                }
                
                NavigationLink {
                    LogView()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.teal.opacity(0.2))
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.teal)
                            }
                            .padding(8)
                            Text("기록하기")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                    .frame(height: 120)
                }
                .background(.clear)
            }
            .padding(.horizontal, 16)
            .navigationTitle("Home")
        }
        .padding(.bottom, 36)
    }
}

struct StreakCard: View {
    let title: String
    let subtitle: String
    let total: Int
    let completed: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.title2).bold()
                Spacer()
                Image(systemName: "flame.fill").foregroundStyle(.orange)
            }
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)

            // dots row
            HStack(spacing: 16) {
                ForEach(0..<total, id: \.self) { idx in
                    VStack(spacing: 6) {
                        Text("\(idx+1)").font(.footnote).foregroundStyle(.secondary)
                        ZStack {
                            Circle()
                                .strokeBorder(Color(.separator), lineWidth: 1)
                                .background(Circle().fill(Color(.systemFill)))
                                .frame(width: 52, height: 52)
                            if idx < completed {
                                Circle()
                                    .fill(Color.orange.opacity(0.25))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }
}
