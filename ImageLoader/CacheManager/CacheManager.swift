//
//  CacheManager.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 28/11/25.
//

import Foundation

// Protocol to interact with Cache.
protocol CachingStrategy {
    func getImage(for key: String) -> Data?
    func setImage(for key: String, data: Data)
    func clearImage(for key: String)
    func clearImages(olderThan interval: TimeInterval)
}

//TODO: Should we make `clearImages` as mandatory instead of optional one?
extension CachingStrategy {
    func clearImage(for key: String) {}
    func clearImages(olderThan interval: TimeInterval) {}
}

/*
 This is an example of Facade design pattern where we have a middle layer which acts as an interface between underlying caches - in memory, disk and hybrid
 */
class CacheManager: CachingStrategy {
    
    private var strategy: CachingStrategy

     init(strategy: CachingStrategy) {
       self.strategy = strategy
    }
    
    func getImage(for key: String) -> Data? {
        return strategy.getImage(for: key)
    }
    
    func setImage(for key: String, data: Data) {
        self.strategy.setImage(for: key, data: data)
    }

    func clearImage(for key: String) {
        self.strategy.clearImage(for: key)
    }
    
    func clearImages(olderThan interval: TimeInterval) {
        self.strategy.clearImages(olderThan: interval)
    }
}
