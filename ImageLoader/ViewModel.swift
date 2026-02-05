//
//  ViewModel.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 14/11/25.
//

import Foundation
import UIKit

enum NetworkError: Error {
    case invalidURL
    case noData
    case serverError(statusCode: Int)
}

class ViewModel : ObservableObject {
    @Published var image: UIImage? = nil
    @Published var imageItems = [ImageItem]()
    let imageProcessingQueue = DispatchQueue(
        label: "SampleApp.ImageLoader",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    init(image: UIImage? = nil, imageItems: [ImageItem] = [ImageItem]()) {
        self.image = image
        self.imageItems = imageItems
        //createImageList()
        
        //Bulk Image url generation
        //let urls = generateBulkImageURLs(ids: 1...5,sizes: [(200, 300), (400, 400),(600, 800)])
//        let urls = generateBulkImageURLs(ids: 1...20, sizes: [(2000, 3000)])
//        print("Image URLs : \(urls)")
//        self.imageItems = urls.map { ImageItem(url: $0, image: nil) }
        
        let urls = imageURLsFromGithub(in: 1...14)
        loadImages(urls: urls)
    }
    
    func createImageList() {
        let imageURL_1 = "https://developer.apple.com/assets/elements/icons/swift/swift-128x128_2x.png"
        //let imageURL_2 = "https://added-azure-2k7jgwe0gw.edgeone.app/20mb.jpg"
        for index in 0...20 {
            var url = ""
            url = imageURL_1
            let item = ImageItem(url: URL(string: url), image: UIImage.add)
            imageItems.append(item)
        }
    }
    
    //MARK: Generates the image url's dynamically
    func generateBulkImageURLs(ids: some Sequence<Int>, sizes: [(width: Int, height: Int)]) -> [URL] {
        ids.flatMap { id in
            sizes.compactMap { size in
                URL(string: "https://picsum.photos/id/\(id)/\(size.width)/\(size.height)")
            }
        }
    }
    
    func imageURLsFromGithub(in range: ClosedRange<Int>) -> [URL] {
        range.compactMap {
            URL(string: "https://raw.githubusercontent.com/subinrevi/Image-cache-test-assets/main/assets/images/Image\($0).JPG")
        }
    }


    /*
     Loads the images from the given urls
     */
    func loadImages(urls: [URL]) {
        
        let config = CacheConfiguration(maxImageSize: Int64(100.megabytes), supportedImageFormats: [.bmp, .png, .jpeg], maxDiskStorageLimit: Int64(200.megabytes))
        ImageLoader.shared.configureCache(config: config)
        Task {
            for await update in ImageLoader.shared.requestImages(from: urls) {
                guard let (url, result) = update.first else { continue }

                await MainActor.run {
                    switch result {
                    case .success(let image):
                        let item = ImageItem(url: url, image: image)
                        imageItems.append(item)
                    case .failure(let error):
                        //self.removeALL()
                        print("Failed for \(url): \(error)")
                    }
                }
                
//                await MainActor.run {
//                    if let index = self.imageItems.firstIndex(where: { $0.url == url }) {
//                        switch result {
//                        case .success(let image):
//                            let item = ImageItem(url: url, image: image)
//                            self.imageItems[index] = item
//                        case .failure(let error):
//                            print("Failed for \(url): \(error)")
//                        }
//                    }
//                }
            }
        }
        
    }

    
    func loadImage(from url: String) {
        let config = CacheConfiguration(maxImageSize: Int64(100.megabytes), supportedImageFormats: [.bmp], maxDiskStorageLimit: Int64(200.megabytes))
        ImageLoader.shared.configureCache(config: config)
     
        ImageLoader.shared.requestImage(from: url) { result in
            switch result {
            case.success(let image) :
                DispatchQueue.main.async {
                    self.image = image
                }
            case.failure(let error) :
                print(error)
            }
        }
    }
   
    // Pass through method to use load method into queue.
    private func fetchImageFromCache(forKey key: String, completion: @escaping (Data?) -> Void)  {
        self.imageProcessingQueue.async {
            //See if image exists in NSCache first and if not check disk cache
            if let data = LocalCache.shared.getImageFromCache(forKey: key) {
                completion(data)
            } else {
                let data = DiskCache().loadImageFromDisk(forKey: key)
                completion(data)
            }
        }
    }
    
    func clearImage(for key: String) {
        ImageLoader.shared.clearImage(for: key)
        if let index = imageItems.firstIndex(where: { $0.url?.absoluteString == key }) {
            imageItems.remove(at: index)
        }
        
    }
    
    func clearImages(olderThan interval: TimeInterval) {
        ImageLoader.shared.clearImages(olderThan: interval)
        imageItems.removeAll()
    }
}


