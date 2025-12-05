//
//  ExportModule.swift
//  Bloo
//
//  내보내기(Export) 전체 모듈: 데이터 모델 → 저장소 → 테이블 UI → CSV/PDF → 설정 시트
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
#if canImport(PDFKit)
import PDFKit
#endif
import UIKit

// MARK: - 데이터 모델

public struct DiaryEntry: Identifiable, Codable, Hashable {
    public let id: UUID
    public var timestamp: Date
    public var pee: Int?        // 배뇨(회수) – 없으면 nil
    public var drinkML: Int?    // 음수(ml)
    public var leak: Int?       // 누수(회수)
    public var urge: Int?       // 절박감(등급/회수)

    public init(id: UUID = UUID(),
                timestamp: Date,
                pee: Int? = nil,
                drinkML: Int? = nil,
                leak: Int? = nil,
                urge: Int? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.pee = pee
        self.drinkML = drinkML
        self.leak = leak
        self.urge = urge
    }
}

public struct DayBucket: Identifiable, Codable, Hashable {
    public let id = UUID()
    public var date: Date             // 해당 일자의 00:00
    public var entries: [DiaryEntry]

    public var totalPee: Int { entries.compactMap { $0.pee }.reduce(0, +) }
    public var totalDrink: Int { entries.compactMap { $0.drinkML }.reduce(0, +) }
    public var totalLeak: Int { entries.compactMap { $0.leak }.reduce(0, +) }
    public var totalUrge: Int { entries.compactMap { $0.urge }.reduce(0, +) }
}

// MARK: - 저장소(파일: 일자별 JSON)

public final class DiaryStore: ObservableObject {
    @Published private(set) var days: [DayBucket] = []

    private let folder: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Diary", isDirectory: true)
    }()

    public init() {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        loadAll()
    }

    // 프리뷰/테스트용 생성자
    #if DEBUG
    public init(previewDays: [DayBucket]) {
        self.days = previewDays
    }
    #endif

    public func add(_ entry: DiaryEntry) {
        let d0 = Calendar.current.startOfDay(for: entry.timestamp)
        if let i = days.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: d0) }) {
            days[i].entries.append(entry)
            saveDay(days[i])
        } else {
            let bucket = DayBucket(date: d0, entries: [entry])
            days.append(bucket)
            saveDay(bucket)
        }
    }

    public func buckets(in range: ClosedRange<Date>) -> [DayBucket] {
        days.filter { range.contains($0.date) }.sorted { $0.date < $1.date }
    }

    // MARK: Persistence
    private func path(for date: Date) -> URL {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return folder.appendingPathComponent("\(f.string(from: date)).json")
    }
    private func saveDay(_ day: DayBucket) {
        let url = path(for: day.date)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(day) { try? data.write(to: url, options: .atomic) }
    }
    private func loadAll() {
        guard let items = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        else { return }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        days = items
            .filter { $0.pathExtension == "json" }
            .compactMap { try? Data(contentsOf: $0) }
            .compactMap { try? dec.decode(DayBucket.self, from: $0) }
            .sorted { $0.date < $1.date }
    }
}

#if DEBUG
// 미리보기용 더미 데이터
public extension DiaryStore {
    static func preview() -> DiaryStore {
        let cal = Calendar.current
        let now = Date()
        func d(_ off: Int) -> Date { cal.startOfDay(for: cal.date(byAdding: .day, value: off, to: now)!) }
        func t(_ base: Date, _ h: Int, _ m: Int) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: base)! }

        let d0 = d(0), d1 = d(-1), d2 = d(-2)

        let day0 = DayBucket(date: d0, entries: [
            DiaryEntry(timestamp: t(d0, 8, 15), pee: 1, drinkML: 0, leak: 0, urge: 1),
            DiaryEntry(timestamp: t(d0, 9, 30), drinkML: 250),
            DiaryEntry(timestamp: t(d0, 12, 5), pee: 1, drinkML: 200, urge: 2),
            DiaryEntry(timestamp: t(d0, 15, 40), pee: 1, urge: 1)
        ])
        let day1 = DayBucket(date: d1, entries: [
            DiaryEntry(timestamp: t(d1, 7, 55), pee: 1, urge: 1),
            DiaryEntry(timestamp: t(d1, 10, 10), drinkML: 300),
            DiaryEntry(timestamp: t(d1, 13, 25), pee: 1, drinkML: 150, urge: 2)
        ])
        let day2 = DayBucket(date: d2, entries: [
            DiaryEntry(timestamp: t(d2, 9, 0), pee: 1, urge: 1)
        ])

        return DiaryStore(previewDays: [day2, day1, day0])
    }
}
#endif

// MARK: - iOS 공유 시트 래퍼

public struct ShareSheet: UIViewControllerRepresentable {
    public var activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil
    public var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems,
                                          applicationActivities: applicationActivities)
        vc.excludedActivityTypes = excludedActivityTypes
        return vc
    }
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export 화면 (테이블-first UI)

public struct ExportView: View {
    @EnvironmentObject private var store: DiaryStore

    // 설정 상태
    @State private var fromDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    @State private var toDate = Date()
    @State private var includeRawTable = true
    @State private var includeDailySummary = true

    // 시트 컨트롤
    @State private var showSettings = false
    @State private var showShare = false
    @State private var shareURL: URL?

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("Date/Time").font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Pee").font(.footnote).foregroundStyle(.secondary).frame(width: 56)
                Text("Drink").font(.footnote).foregroundStyle(.secondary).frame(width: 64)
                Text("Leak").font(.footnote).foregroundStyle(.secondary).frame(width: 56)
                Text("Urge").font(.footnote).foregroundStyle(.secondary).frame(width: 56)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))

            Divider()

            // 표 본문
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredBuckets(), id: \.id) { day in
                        if includeDailySummary {
                            HStack {
                                Text(dateLabel(day.date))
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(day.totalPee)").frame(width: 56)
                                Text("\(day.totalDrink)").frame(width: 64)
                                Text("\(day.totalLeak)").frame(width: 56)
                                Text("\(day.totalUrge)").frame(width: 56)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color(.systemBackground))
                        }

                        if includeRawTable {
                            ForEach(day.entries.sorted(by: { $0.timestamp < $1.timestamp }), id: \.id) { e in
                                HStack {
                                    Text(timeLabel(e.timestamp))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text(valueText(e.pee)).frame(width: 56)
                                    Text(valueText(e.drinkML)).frame(width: 64)
                                    Text(valueText(e.leak)).frame(width: 56)
                                    Text(valueText(e.urge)).frame(width: 56)
                                }
                                .font(.body.monospacedDigit())
                                .padding(.horizontal, 16).padding(.vertical, 10)

                                Divider()
                            }
                        }

                        Color(.separator).frame(height: 0.5).padding(.leading, 16)
                    }
                }
            }
        }
        .navigationTitle("Daily Reports")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { exportCSV() } label: { Label("Export CSV", systemImage: "tablecells") }
                    Button { exportPDF() } label: { Label("Export PDF", systemImage: "doc.richtext") }
                } label: { Image(systemName: "square.and.arrow.up") }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
            }
        }
        .sheet(isPresented: $showSettings) {
            ExportSettingsView(fromDate: $fromDate, toDate: $toDate,
                               includeRawTable: $includeRawTable, includeDailySummary: $includeDailySummary)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showShare) {
            if let url = shareURL { ShareSheet(activityItems: [url]) }
        }
    }

    // MARK: Helpers

    private func filteredBuckets() -> [DayBucket] {
        let start = Calendar.current.startOfDay(for: fromDate)
        let end = Calendar.current.startOfDay(for: toDate)
        return store.buckets(in: start...end)
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM dd, yy (E)"; return f.string(from: d)
    }
    private func timeLabel(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)
    }
    private func valueText(_ v: Int?) -> String { v.map { String($0) } ?? "" }

    private func tempURL(_ name: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    // MARK: CSV Export

    private func exportCSV() {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let tf = DateFormatter(); tf.dateFormat = "HH:mm"

        var lines: [String] = ["date,time,pee,drink_ml,leak,urge"]
        for b in filteredBuckets() {
            for e in b.entries.sorted(by: { $0.timestamp < $1.timestamp }) {
                lines.append("\(df.string(from: b.date)),\(tf.string(from: e.timestamp)),\(e.pee ?? 0),\(e.drinkML ?? 0),\(e.leak ?? 0),\(e.urge ?? 0)")
            }
        }
        let csv = lines.joined(separator: "\n")
        let url = tempURL("BladderDiary-\(Int(Date().timeIntervalSince1970)).csv")
        try? csv.data(using: .utf8)?.write(to: url, options: .atomic)
        shareURL = url; showShare = true
    }

    // MARK: PDF Export (간단 렌더)

    private func exportPDF() {
        #if canImport(PDFKit)
        let buckets = filteredBuckets()
        let pageImage = renderReportImage(buckets: buckets,
                                          includeRaw: includeRawTable,
                                          includeSummary: includeDailySummary)
        let pdf = PDFDocument()
        if let page = PDFPage(image: pageImage) { pdf.insert(page, at: 0) }
        let url = tempURL("BladderDiary-\(Int(Date().timeIntervalSince1970)).pdf")
        pdf.write(to: url)
        shareURL = url; showShare = true
        #endif
    }
}

// MARK: - 보고서 렌더(이미지 → PDF 페이지)

private func renderReportImage(buckets: [DayBucket], includeRaw: Bool, includeSummary: Bool) -> UIImage {
    let w: CGFloat = 612 // ~ US Letter width @72dpi
    let left: CGFloat = 24
    let lineH: CGFloat = 22
    var y: CGFloat = 32

    let rows = buckets.reduce(0) { acc, b in
        acc + 1 + (includeSummary ? 1 : 0) + (includeRaw ? b.entries.count : 0)
    }
    let h = max(792, 32 + CGFloat(rows) * (lineH + 2) + 40)

    let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
    return renderer.image { ctx in
        UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

        func drawText(_ text: String, _ x: CGFloat, _ y: CGFloat, weight: UIFont.Weight = .regular) {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: weight),
                .foregroundColor: UIColor.black
            ]
            text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
        }

        drawText("Bladder Diary Report", left, y, weight: .semibold); y += 28

        let df = DateFormatter(); df.dateFormat = "MMM dd, yyyy"
        let tf = DateFormatter(); tf.dateFormat = "h:mm a"

        for day in buckets {
            drawText(df.string(from: day.date), left, y, weight: .semibold); y += lineH

            if includeSummary {
                drawText("Total", left + 8, y)
                drawText("Pee \(day.totalPee)", left + 160, y)
                drawText("Drink \(day.totalDrink)", left + 260, y)
                drawText("Leak \(day.totalLeak)", left + 380, y)
                drawText("Urge \(day.totalUrge)", left + 480, y)
                y += lineH
            }

            if includeRaw {
                for e in day.entries.sorted(by: { $0.timestamp < $1.timestamp }) {
                    drawText(tf.string(from: e.timestamp), left + 8, y)
                    if let v = e.pee { drawText("Pee \(v)", left + 160, y) }
                    if let v = e.drinkML { drawText("Drink \(v)", left + 260, y) }
                    if let v = e.leak { drawText("Leak \(v)", left + 380, y) }
                    if let v = e.urge { drawText("Urge \(v)", left + 480, y) }
                    y += lineH
                }
            }

            y += 6
            UIColor.lightGray.setFill()
            ctx.fill(CGRect(x: left, y: y, width: w - left*2, height: 0.5))
            y += 10
        }
    }
}

// MARK: - 설정 시트

public struct ExportSettingsView: View {
    @Binding var fromDate: Date
    @Binding var toDate: Date
    @Binding var includeRawTable: Bool
    @Binding var includeDailySummary: Bool

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("범위")) {
                    DatePicker("시작", selection: $fromDate, displayedComponents: .date)
                    DatePicker("끝", selection: $toDate, displayedComponents: .date)
                }
                Section(header: Text("포함 항목")) {
                    Toggle("원시 로그(시간별 기록표)", isOn: $includeRawTable)
                    Toggle("일자 합계(pee/drink/leak/urge)", isOn: $includeDailySummary)
                }
            }
            .navigationTitle("설정")
        }
    }
}

// MARK: - 미리보기

#if DEBUG
public struct ExportView_Previews: PreviewProvider {
    public static var previews: some View {
        NavigationStack { ExportView().environmentObject(DiaryStore.preview()) }
    }
}
#endif
