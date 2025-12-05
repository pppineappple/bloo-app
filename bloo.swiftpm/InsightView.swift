import SwiftUI

// MARK: - Models
enum InsightRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    var id: String { rawValue }
}

struct InsightMetrics {
    var totalEvents: Int
    var waterLiters: Double
    var waterEntries: Int
}

enum TimelineKind: Equatable {
    case urination
    case waterIntake(ml: Int)

    var title: String {
        switch self {
        case .urination: return "Urination"
        case .waterIntake: return "Water intake"
        }
    }

    var subtitle: String? {
        switch self {
        case .urination: return nil
        case .waterIntake(let ml): return "\(ml)ml"
        }
    }

    var iconName: String {
        switch self {
        case .urination: return "drop.fill"
        case .waterIntake: return "cup.and.saucer.fill"
        }
    }
}

struct TimelineEvent: Identifiable {
    let id = UUID()
    let timeText: String
    let kind: TimelineKind
}

// MARK: - View
struct InsightView: View {
    @State private var range: InsightRange = .day

    // Stub data for the preview / initial wiring. Replace with real source later.
    @State private var metrics = InsightMetrics(totalEvents: 6, waterLiters: 1.3, waterEntries: 5)
    @State private var timeline: [TimelineEvent] = [
        .init(timeText: "07:30", kind: .urination),
        .init(timeText: "08:00", kind: .waterIntake(ml: 250)),
        .init(timeText: "09:45", kind: .urination),
        .init(timeText: "10:30", kind: .waterIntake(ml: 300)),
        .init(timeText: "12:00", kind: .urination),
        .init(timeText: "12:30", kind: .waterIntake(ml: 200))
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Trends")
                        .font(.largeTitle).bold()
                    Text("Track your patterns over time")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Segmented control
                Picker("Range", selection: $range) {
                    ForEach(InsightRange.allCases) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)

                // Metric cards
                HStack(spacing: 16) {
                    MetricCard(title: "Total Events",
                               value: "\(metrics.totalEvents)",
                               subtitle: "urinations")
                    MetricCard(title: "Water Intake",
                               value: String(format: "%.1fL", metrics.waterLiters),
                               subtitle: "\(metrics.waterEntries) entries")
                }

                // Timeline section
                Text("Today's Timeline")
                    .font(.title2).bold()
                    .padding(.top, 8)

                TimelineCard(events: timeline)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Components
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 34, weight: .bold))
            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.systemBackground)))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

struct TimelineCard: View {
    let events: [TimelineEvent]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(events.indices, id: \.self) { idx in
                let event = events[idx]
                TimelineRow(event: event)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                if idx < events.count - 1 {
                    Divider().padding(.leading, 86) // keeps divider inside card after time & icon
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.15))
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }
}

struct TimelineRow: View {
    let event: TimelineEvent

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Time
            Text(event.timeText)
                .font(.title3)
                .frame(width: 64, alignment: .leading)
                .foregroundStyle(.secondary)

            // Icon
            ZStack {
                Circle().fill(Color.teal.opacity(0.15))
                    .frame(width: 42, height: 42)
                Image(systemName: event.kind.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.teal)
            }
            
            // Titles
            VStack(alignment: .leading, spacing: 4) {
                Text(event.kind.title)
                    .font(.title3)
                if let subtitle = event.kind.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        InsightView()
    }
}
