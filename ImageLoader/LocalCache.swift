
import Foundation

class LocalCache {
    let cache = NSCache<NSString, AnyObject>()
    static let shared = LocalCache()
    
    private init() {
        // Set total cost limit to 20 MB
        cache.totalCostLimit = 20 * 1024 * 1024
    }

    // For NSCache
    func saveImageToCache(data: Data, forKey key: String) {
        let nsData = data as NSData
        cache.setObject(data as NSData, forKey: key as NSString, cost: nsData.length)
        print("Cache storage in bytes: \(LocalCache.shared.cache.totalCostLimit)")
    }
    
    func getImageFromCache(forKey key: String) -> Data? {
        if let data = cache.object(forKey: key as NSString) as? Data {
            return data
        }
        return nil
    }
}
