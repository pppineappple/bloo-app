import SwiftUI
import UIKit

struct LogView: View {
    @State private var selectedColor: UrineColor = .normal
    @State private var urinationType: UrinationType = .planned
    @State private var notes: String = ""
    @State private var logDate: Date = .now
    @State private var isShowingTimeSheet: Bool = false
    @State private var entryKind: EntryKind = .urination

    private var nowString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f.string(from: logDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header time + hint
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Button {
                            isShowingTimeSheet = true
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(nowString)
                                    .font(.largeTitle).bold()
                                Image(systemName: "chevron.down")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .baselineOffset(2)
                            }
                        }
                        .buttonStyle(.plain)

                        Text("now")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    // Entry kind segmented control
                    VStack(alignment: .leading, spacing: 12) {
                         Picker("Entry Kind", selection: $entryKind) {
                            Text("Urination").tag(EntryKind.urination)
                            Text("Leak").tag(EntryKind.leak)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Color section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.title3).bold()
                        UrineColorPicker(selected: $selectedColor)
                    }

                    // Type section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Type")
                            .font(.title3).bold()
                        UrinationTypePicker(selected: $urinationType)
                    }

                    // Notes section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Memo")
                            .font(.title3).bold()
                        NotesEditor(text: $notes, placeholder: "증상, 물 섭취량, 특이사항 등을 적어주세요")
                    }
                }
                .padding(16)
            }

            Divider()
            Button("Save Log") {
                let entry = LogEntry(kind: entryKind, color: selectedColor, type: urinationType, notes: notes, date: logDate)
                // TODO: 실제 저장 로직 연결 (예: AppStorage/ 파일DB / CloudKit)
                print("Saved:", entry)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            .padding(16)
        }
        .navigationTitle("Create New log")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $isShowingTimeSheet) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button("Done") { isShowingTimeSheet = false }
                        .bold()
                }
                .padding(.top, 8)

                DatePicker("", selection: $logDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_US"))

                Spacer(minLength: 0)
            }
            .padding()
            .presentationDetents([.height(320)])
        }
    }
}

// MARK: - Model
enum EntryKind: String, Identifiable, CaseIterable { case urination, leak
    var id: String { rawValue }
    var title: String { self == .urination ? "Urination" : "Leak" }
}

enum UrineColor: String, CaseIterable, Identifiable {
    case clear, light, normal, dark, veryDark
    var id: String { rawValue }

    var title: String {
        switch self {
        case .clear: return "맑음"
        case .light: return "연함"
        case .normal: return "보통"
        case .dark: return "진함"
        case .veryDark: return "매우 진함"
        }
    }

    var swatch: Color {
        switch self {
        case .clear: return .yellow.opacity(0.15)
        case .light: return .yellow.opacity(0.35)
        case .normal: return .yellow
        case .dark: return .orange
        case .veryDark: return .brown
        }
    }
}

enum UrinationType: String, Identifiable { case planned, sudden
    var id: String { rawValue }
    var title: String { self == .planned ? "계획적 배뇨" : "급박한 요의" }
}

struct LogEntry: Identifiable {
    let id = UUID()
    var kind: EntryKind
    var color: UrineColor
    var type: UrinationType
    var notes: String
    var date: Date = .now
}

// MARK: - Components
struct UrineColorPicker: View {
    @Binding var selected: UrineColor
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(UrineColor.allCases) { c in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(c.swatch)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Group {
                                    // Selected thick border
                                    if selected == c {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.black, lineWidth: 2)
                                    } else {
                                        // Default subtle border
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                    }

                                    // Extra subtle outline for 'clear' color (visibility helper)
                                }
                            )
                        Text(c.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selected = c }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct UrinationTypePicker: View {
    @Binding var selected: UrinationType
    var body: some View {
        VStack(spacing: 10) {
            radioRow(title: UrinationType.planned.title, value: .planned)
            radioRow(title: UrinationType.sudden.title, value: .sudden)
        }
    }

    @ViewBuilder
    private func radioRow(title: String, value: UrinationType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selected == value ? "largecircle.fill.circle" : "circle")
                .imageScale(.large)
            Text(title)
                .font(.body)
            Spacer()
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { selected = value }
    }
}

struct NotesEditor: View {
    @Binding var text: String
    var placeholder: String
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(.secondary)
                    .padding(.top, 12)
                    .padding(.horizontal, 10)
            }
            TextEditor(text: $text)
                .frame(minHeight: 140)
                .padding(8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { LogView() }
}

// MARK: - Time Header Picker (Reusable)
public struct TimeHeaderPicker: View {
    @Binding var date: Date
    public var trailingLabel: String = "now"
    public var displayedComponents: DatePicker.Components = [.hourAndMinute] // override per usage
    public var locale: Locale = Locale(identifier: "en_US")
    public var detentHeight: CGFloat = 320
    
    @State private var isPresented: Bool = false
    
    private var timeString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
    
    public init(
        date: Binding<Date>,
        trailingLabel: String = "now",
        displayedComponents: DatePicker.Components = [.hourAndMinute],
        locale: Locale = Locale(identifier: "en_US"),
        detentHeight: CGFloat = 320
    ) {
        self._date = date
        self.trailingLabel = trailingLabel
        self.displayedComponents = displayedComponents
        self.locale = locale
        self.detentHeight = detentHeight
    }
    
    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button {
                isPresented = true
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(timeString)
                        .font(.largeTitle).bold()
                    Image(systemName: "chevron.down")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .baselineOffset(2)
                }
            }
            .buttonStyle(.plain)
            
            Text(trailingLabel)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .sheet(isPresented: $isPresented) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button("Done") { isPresented = false }
                        .bold()
                }
                .padding(.top, 8)
                
                DatePicker("",
                           selection: $date,
                           displayedComponents: displayedComponents)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, locale)
                
                Spacer(minLength: 0)
            }
            .padding()
            .presentationDetents([.height(detentHeight)])
        }
    }
}
