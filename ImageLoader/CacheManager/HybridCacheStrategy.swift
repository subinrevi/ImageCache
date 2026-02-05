//
//  HybridCacheStrategy.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 29/11/25.
//

import Foundation

/*
 Combines both disk and local cache
 */
class HybridCacheStrategy: CachingStrategy {
    private let memoryStrategy: CachingStrategy
    private let diskStrategy: CachingStrategy
    
    private var prerequisites: ManagingCachePrerequisite
   
    
    init(memoryStrategy: CachingStrategy, diskStrategy: CachingStrategy, prerequisites : ManagingCachePrerequisite) {
        self.memoryStrategy = memoryStrategy
        self.diskStrategy = diskStrategy
        self.prerequisites = prerequisites
    }
    
    func getImage(for key: String) -> Data? {
        if let imageData = memoryStrategy.getImage(for: key) {
            return imageData
        }
        
        if let imageData = diskStrategy.getImage(for: key) {
            memoryStrategy.setImage(for: key, data: imageData)
            return imageData
        }
        return nil
    }
    
    func setImage(for key: String, data: Data) {
        guard prerequisites.isCachePrerequisiteMet(image: data) else {
            return
        }
        memoryStrategy.setImage(for: key, data: data)
        diskStrategy.setImage(for: key, data: data)
    }
    
    func clearImage(for key: String) {
        diskStrategy.clearImage(for: key)
    }
    
    func clearImages(olderThan interval: TimeInterval) {
        diskStrategy.clearImages(olderThan: interval)
    }
    
}
