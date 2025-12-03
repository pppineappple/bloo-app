//
//  HomeView.swift
//  bloo
//
//  Created by Shin seungah on 12/3/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Button {
                    print("Tapped!")
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.teal.opacity(0.2))
                        
                        VStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.teal)
                            
                            Text("기록하기")
                                .font(.headline)
                                .foregroundColor(.teal)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit) // ← 자동 정사각형
                }
                .padding()
            }
            .navigationTitle("Home")
        }
    }
}
