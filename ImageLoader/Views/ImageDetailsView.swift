//
//  ImageDetailsView.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 22/11/25.
//

import SwiftUI

struct ImageDetailsView: View {
      let image: ImageItem
      var body: some View {
          VStack(spacing: 20) {
              ImageRow(item: image)
          }
          .padding()
      }
}

#Preview {
    ImageDetailsView(image: ImageItem(url: URL(string: "www.apple.com"), image: UIImage.add))
}
