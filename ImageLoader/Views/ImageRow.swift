//
//  ImageRow.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 19/11/25.
//

import SwiftUI

struct ImageRow: View {
    let item: ImageItem
    @StateObject private var viewModel = ViewModel()
    @State private var image: UIImage?
    private let size = CGSize(width: 140, height: 140)
    
    var body: some View {
        VStack {
            
            if let url = item.url, let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let url = item.url {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 100, height: 100)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
                
            } else if let image = item.image {
                // Display downloaded UIImage
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                
            } else {
                // Fallback placeholder
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(width: 100, height: 100)
                    .background(Color(.systemGray4))
                    .cornerRadius(8)
            }
            Spacer()
            //        } .frame(maxWidth: .infinity, maxHeight: .infinity)
            //            .padding(.vertical, 8)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
        .task(id: item.id) {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard image == nil else { return }
        
        if let url = item.url {
            let img = await GridImageLoader.load(
                url: url,
                targetSize: size
            )
            
            await MainActor.run {
                self.image = img
            }
        }
    }
}
                   
#Preview {
    ImageRow(item: ImageItem(url: URL(string: "www.apple.com"), image: UIImage.add))
}
