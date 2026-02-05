//
//  DiskMemoryManager.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 28/11/25.
//

import Foundation

class DiskMemoryManager: CachingStrategy {
    
    func getImage(for key: String) -> Data? {
        guard let cacheDir = Utility().getCacheDirectory() else { return nil }
        let fileURL = cacheDir.appendingPathComponent(Utility().fileName(from: key))
        return try? Data(contentsOf: fileURL)
    }
    
    func setImage(for key: String, data: Data) {
        guard let cacheDir = Utility().getCacheDirectory() else { return }
        let fileURL = cacheDir.appendingPathComponent(Utility().fileName(from: key))
        do {
            try data.write(to: fileURL)
            print("Image saved to disk at \(fileURL.path)")
        } catch {
            print("Failed to save image: \(error)")
        }
    }
    
    
    func clearImage(for key: String) {
        let fileManager = FileManager.default
        guard let cacheDir = Utility().getCacheDirectory() else {
            return
        }
        let fileURL = cacheDir.appendingPathComponent(key)
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("File deleted at path: \(fileURL)")
            } catch {
                print("Failed to delete file: \(error)")
            }
        } else {
            print("File not found for key: \(key)")
        }
    }
    
    func clearImages(olderThan interval: TimeInterval) {
        let fileManager = FileManager.default
        guard let cacheDir = Utility().getCacheDirectory() else { return }
        
        //we use `contentModificationDateKey` instead of `creationDateKey`. In case the image is overwritten with new data creationDateKey may cause problems.
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles) else { return }
        
        for fileURL in files {
            if let values = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]), let date = values.contentModificationDate {
                if Date().timeIntervalSince(date) > interval {
                    try? fileManager.removeItem(at: fileURL)
                    print("File deleted at path: \(fileURL)")
                }
            }
        }
        print("File Count: \(files.count)")
    }
}
