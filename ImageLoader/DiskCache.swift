
import Foundation

class DiskCache {
    func saveImageToDisk(data: Data, forKey key: String) {
        guard let cacheDir = Utility().getCacheDirectory() else { return }
        let fileURL = cacheDir.appendingPathComponent(Utility().fileName(from: key))
        do {
            try data.write(to: fileURL)
            print("Image saved to disk at \(fileURL.path)")
        } catch {
            print("Failed to save image: \(error)")
        }
    }
    
    func loadImageFromDisk(forKey key: String) -> Data?  {
        guard let cacheDir = Utility().getCacheDirectory() else { return nil }
        let fileURL = cacheDir.appendingPathComponent(Utility().fileName(from: key))
        return try? Data(contentsOf: fileURL)
    }
    
    //Should we call this method in a background queue since there may be lot of images and this will be a time consuming one?
    func cleanupDiskCache(_ timeInterval: Int = 30) {
        let fileManager = FileManager.default
        guard let cacheDir = Utility().getCacheDirectory() else { return }
        
        //we use `contentModificationDateKey` instead of `creationDateKey`. In case the image is overwritten with new data creationDateKey may cause problems.
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { return }
        
        for fileURL in files {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]), let date = values.contentModificationDate {
                if Date().timeIntervalSince(date) > 3.minutes {
                    try? fileManager.removeItem(at: fileURL)
                    print("File deleted at path: \(fileURL)")
                }
            }
        }
        
        print("File Count: \(files.count)")
        
    }
}
