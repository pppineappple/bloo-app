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
    
    var body: some View {
        NavigationStack {
            VStack {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(drinks) { d in
                            Button {
                                print(d.en)   // 최소 동작: 영어만 출력
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
                    .padding(.horizontal, 12)
                
                Button {
                    print("Tapped!")
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
                    .frame(height: 120) // 고정 높이
                }
                .padding(.horizontal, 12) // 양옆 12 고정
                .background(.clear)
                
            }
        }
        .padding(.bottom, 36)
        .navigationTitle("Home")
    
        }
    }

