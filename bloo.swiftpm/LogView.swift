import SwiftUI

struct LogView: View {
    @Environment(\.dismiss) private var dismiss

    // State
    @State private var logDate: Date = Date()
    @State private var entryKind: EntryKind = .urination
    @State private var selectedColor: UrineColor = .normal
    @State private var urinationType: UrinationType = .planned
    @State private var notes: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                categoryPicker
                if entryKind == .urination { colorSection }
                typeSection
                memoSection
                saveButton
                    .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemGroupedBackground))
        .modifier(HideScrollInsetIfAvailable())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { Text("Create New Log").font(.headline) } }
    }
}

// MARK: - Sections
extension LogView {
    private var header: some View {
        TimeHeaderPicker(date: $logDate,
                         trailingLabel: "now",
                         displayedComponents: [.hourAndMinute],
                         locale: Locale(identifier: "en_US"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var categoryPicker: some View {
        Picker("Entry Kind", selection: $entryKind) {
            ForEach(EntryKind.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color").font(.title3).bold()
            UrineColorPicker(selected: $selectedColor)
        }
    }

    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type").font(.title3).bold()
            UrinationTypePicker(selected: $urinationType)
        }
    }

    private var memoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memo").font(.title3).bold()
            NotesEditor(text: $notes, placeholder: "증상, 물 섭취량, 특이사항 등을 적어주세요")
        }
    }

    private var saveButton: some View {
        Button {
            let entry = LogEntry(kind: entryKind, color: selectedColor, type: urinationType, notes: notes, date: logDate)
            print("Saved:", entry)
            dismiss()
        } label: {
            Text("Save Log")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Capsule().fill(Color.teal))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    NavigationStack { LogView() }
}

private struct HideScrollInsetIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
