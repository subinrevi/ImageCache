//
//  ContentView.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 14/11/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    let columns = [
        GridItem(.adaptive(minimum: 120), spacing: 16)
    ]
    
    @StateObject private var viewModel = ViewModel()
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.imageItems) { item in
                            NavigationLink {
                                ImageDetailsView(image: item)
                            } label: {
                                ImageRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    guard let urlString = item.url?.absoluteString else {
                                        return
                                    }
                                    viewModel.clearImage(for: urlString)
                                    
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                
                // Floating Buttons
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Button(action: {
                                viewModel.clearImages(olderThan: 2)
                            }) {
                                Image(systemName: "trash.slash")
                                    .foregroundColor(.white)
                                    .font(.system(size: 22))
                                    .frame(width: 56, height: 56)
                                    .background(Color.green)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                        .padding()
                    }
                }
            }
            
        }
    }
}
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}


struct ImageItem: Identifiable {
    let id = UUID()
    var url: URL?
    var image: UIImage?
}
