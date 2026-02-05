//
//  CustomImageView.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 19/11/25.
//

import SwiftUI

struct CustomImageView: View {
    let urlString: String
    @StateObject private var viewModel = ViewModel()
    var body: some View {
        ZStack {
            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear {
            viewModel.loadImage(from: urlString)
        }
    }
    
    private func imageFromData(_ data: Data?) -> UIImage {
        let start = Utility().startTimer()
        if let imageData = data, let image = UIImage(data: imageData) {
            let end = Utility().endTimer()
            print("Time: \(end - start)")
            return image
        }
        
        return UIImage()
    }
    
}

#Preview {
    CustomImageView(urlString: "")
}
