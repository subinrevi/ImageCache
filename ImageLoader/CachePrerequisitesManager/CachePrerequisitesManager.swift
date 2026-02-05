//
//  CachePrerequisitesManager.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 28/11/25.
//

import Foundation
import UIKit

/*
 ManagingCachePrerequisite acts as an orchestrator which handles the validation chain and returns whether an image can be cached or not. The `handler` is responsible for performing the validation steps.
 */
protocol ManagingCachePrerequisite {
    var handler: CacheValidating { get  }
    
    /// Checks if the image meets the cache criteria
    /// - Parameter image: imageData
    /// - Returns: true or false
    func isCachePrerequisiteMet(image: Data?) -> Bool
}

class ManageCachePrerequisites: ManagingCachePrerequisite  {
    var handler: CacheValidating
    private let cacheConfiguration: CacheConfiguration
    
    init(cacheConfiguration: CacheConfiguration) {
        let cacheValidator = CacheValidator()
        let imageValidator = ImageValidator()
        cacheValidator.next = imageValidator
        self.handler = cacheValidator
        self.cacheConfiguration = cacheConfiguration
    }
    
    func isCachePrerequisiteMet(image: Data?) -> Bool {
        let request = CachePrerequisitesRequest(image: image, config: self.cacheConfiguration)
        return handler.handle(request)
    }
}


protocol CacheValidating {
    
    var next: CacheValidating? { get set }
    
    ///  This method passes the request to next validator
    /// - Parameter request: Contains the image that is being validated
    /// - Returns: true or false
    func handle(_ request: CachePrerequisitesRequest) -> Bool
}

class CacheValidator: CacheValidating {
    var next: CacheValidating?
    
    func handle(_ request: CachePrerequisitesRequest) -> Bool {
        if self.isCacheSizeAvailable(request) {
            return next?.handle(request) ?? true
        }
        return false
    }
    
    private func isCacheSizeAvailable(_ request: CachePrerequisitesRequest) -> Bool {
        guard let cacheDir = Utility().getCacheDirectory() else { return false }
        let directorySize = directorySize(at: cacheDir)
        if directorySize < request.config.maxDiskStorageLimit {
            return true
        }
        return false
    }
    
    func directorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        if let enumerator = FileManager.default.enumerator(at: url,
                                                           includingPropertiesForKeys: [.fileSizeKey],
                                                           options: [],
                                                           errorHandler: nil) {
            for case let fileURL as URL in enumerator {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    size += Int64(fileSize)
                }
            }
        }
        return size
    }
}

class ImageValidator: CacheValidating {
    var next: CacheValidating?
    
    func handle(_ request: CachePrerequisitesRequest) -> Bool {
        guard let imageData = request.image else {
            return false
        }
        let size = imageSize(from: imageData)
        if request.config.supportedImageFormats.contains(detectImageType(from: imageData)) &&
            size < request.config.maxImageSize {
            return next?.handle(request) ?? true
        }
        return false
    }
    
    private func detectImageType(from data: Data) -> ImageType {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return .png }
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return .jpeg }
        if data.starts(with: [0x47, 0x49, 0x46, 0x38]) { return .gif }
        if data.starts(with: [0x52, 0x49, 0x46, 0x46]) &&
            data[8...11] == Data([0x57, 0x45, 0x42, 0x50]) { return .webp }
        if data.starts(with: [0x42, 0x4D]) { return .bmp }
        if data.starts(with: [0x49, 0x49, 0x2A, 0x00]) ||
            data.starts(with: [0x4D, 0x4D, 0x00, 0x2A]) { return .tiff }
        return .unknown
    }
    
    private func imageSize(from data: Data) -> Int64 {
        let sizeInBytes = data.count
        return Int64(sizeInBytes)
    }
}

enum ImageType: String {
    case png, jpeg, gif, webp, bmp, tiff, unknown
}


struct CachePrerequisitesRequest {
    let image: Data?
    let config: CacheConfiguration
}
