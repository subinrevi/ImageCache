//
//  InMemoryManager.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 28/11/25.
//

import Foundation

final class InMemoryManager: CachingStrategy {
    
    private let cache = NSCache<NSString, AnyObject>()
    func getImage(for key: String) -> Data? {
        if let data = cache.object(forKey: key as NSString) as? Data {
            return data
        }
        return nil
    }
    
    func setImage(for key: String, data: Data) {
        let nsData = data as NSData
        cache.setObject(data as NSData, forKey: key as NSString, cost: nsData.length)
        print("Cache storage in bytes: \(LocalCache.shared.cache.totalCostLimit)")
    }
}
