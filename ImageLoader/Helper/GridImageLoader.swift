
import Foundation
import SwiftUI

/*
 ISSUE:
  Images are very large (5–10 MB, thousands of pixels wide)
 SwiftUI grids show small thumbnails
 iOS still decodes the full image before resizing
 Decoding large images is CPU-heavy
 If this happens while scrolling → jank / stutter
 
 Solution:
 Loads an image already resized to the exact size you need, and does it off the main thread.
 
 */
final class GridImageLoader {
    static func load(url: URL, targetSize: CGSize, scale: CGFloat = UIScreen.main.scale) async -> UIImage? {

        await Task.detached(priority: .utility) {
            let sourceOptions = [
                kCGImageSourceShouldCache: false
            ] as CFDictionary

            guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
                return nil
            }

            let maxDimension = max(targetSize.width, targetSize.height) * scale

            let downsampleOptions = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxDimension
            ] as CFDictionary

            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                downsampleOptions
            ) else {
                return nil
            }

            return UIImage(cgImage: cgImage)
        }.value
    }
}

