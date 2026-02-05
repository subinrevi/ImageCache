//
//  ImageLoader.swift
//  ImageLoader
//
//  Created by Digvijay Tyagi on 28/11/25.
//

import Foundation
import UIKit

/// This protocol defines the attributes of the Cache.
/// maxImageSize: Maximum image size that can be cached
/// supportedImageFormats: JPEG, PNG, webp
/// maxDiskStorageLimit: Maximum disk capacity
public class CacheConfiguration {
    var maxImageSize: Int64
    var supportedImageFormats: [ImageType]
    var maxDiskStorageLimit: Int64
    
    init(maxImageSize: Int64, supportedImageFormats: [ImageType], maxDiskStorageLimit: Int64) {
        self.maxImageSize = maxImageSize
        self.supportedImageFormats = supportedImageFormats
        self.maxDiskStorageLimit = maxDiskStorageLimit
    }   
}

//FIXME: Made the following public since we want this to released in the form of a framework.

/// Public methods that will be exposed to to applications consuming the `ImageLoader` framework.
public protocol ImageLoading {
    /// Initialise/Configure the Image Loader cache with custom configuration
    /// - Parameter config: CacheConfiguration
    func configureCache(config: CacheConfiguration)
    
    /// Download a single image from a URL
    /// - Parameters:
    ///   - url: Image URL
    ///   - completion: Returns an Image on success or failure on error
    func requestImage(from url: String, completion : @escaping (Result <UIImage, LoaderError>) -> Void)
    
    
    /// Download multiple images from an array of URLs
    /// - Parameter urls: Array of URLs
    /// - Returns: Returns a dictionary with the URL as key and the downloaded image or error as value
    func requestImages(from urls: [URL]) -> AsyncStream<[URL: Result<UIImage, LoaderError>]>
}

public protocol ImageCacheDeletion  {
    /// Clear a single image
    /// - Parameter key: Image URL
    func clearImage(for key: String)
    
    /// Clear images older than a specific time (eg: Clear images after 24 hrs)
    /// - Parameter interval: Value for time interval
    func clearImages(olderThan interval: TimeInterval)
}

extension ImageCacheDeletion {
    func clearImage(for key: String) {}
    func clearImages(olderThan interval: TimeInterval) {}
}

public final class ImageLoader: ImageLoading {
    
    static let shared = ImageLoader()
    internal var cacheManager : CachingStrategy
    internal var networkManager : Networking
    internal var cacheConfiguration: CacheConfiguration
    
    private let imageProcessingQueue = DispatchQueue(
        label: "SampleApp.ImageLoader",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    /*
     ImageLoader is a singleton class and hence the private intializer. By default the `cacheConfiguration` will have the following values.
     */
    private init() {
        cacheConfiguration = CacheConfiguration(maxImageSize: Int64(25.megabytes), supportedImageFormats: [.jpeg, .png, .webp], maxDiskStorageLimit: Int64(200.megabytes))
        cacheManager = CacheManager(strategy: HybridCacheStrategy(memoryStrategy: InMemoryManager(), diskStrategy: DiskMemoryManager(), prerequisites: ManageCachePrerequisites(cacheConfiguration: self.cacheConfiguration)))
        networkManager = NetworkManager()
    }
    
    internal init(cacheManager: CachingStrategy, networkManager: Networking, cacheConfig: CacheConfiguration) {
        self.cacheManager = cacheManager
        self.networkManager = networkManager
        self.cacheConfiguration = cacheConfig
    }
    
    /// This method helps to override the default configuration set by the ImageLoader.
    /// - Parameter config: config object with the values to be overridden
    public func configureCache(config: CacheConfiguration) {
        self.cacheConfiguration.maxDiskStorageLimit = config.maxDiskStorageLimit
        self.cacheConfiguration.maxImageSize = config.maxDiskStorageLimit
        self.cacheConfiguration.supportedImageFormats = config.supportedImageFormats
    }

    public func requestImage(from url: String, completion: @escaping (Result<UIImage,  LoaderError>) -> Void) {
        self.loadImageData(from: url) { result in
            switch result {
            case.success(let imageData):
                let image = self.imageFromData(imageData)
                completion(.success(image))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    public func requestImages(from urls: [URL]) -> AsyncStream<[URL: Result<UIImage, LoaderError>]> {
        AsyncStream { continuation in
            // Dictionary to accumulate results internally
            var results: [URL: Result<UIImage, LoaderError>] = [:]
            
            //FIXME: SERIAL queue — critical fix
            /*
             Mutations to a Swift Dictionary from multiple threads concurrently.
             
             Correct fix
             - Use a serial queue or actor
             - Never mutate Swift collections concurrently
             
             */
            let queue = DispatchQueue(label: "imageFetcher.serial")
            let group = DispatchGroup()

            for url in urls {
                group.enter()

                // Call your existing single-image loader
                self.requestImage(from: url.absoluteString) { result in
                    queue.async {
                        // Store the result in the internal dictionary
                        results[url] = result
                        
                        // Emit a single-entry dictionary immediately
                        continuation.yield([url: result])
                        
                        group.leave()
                    }
                }
            }

            // When all downloads finish, close the stream
            group.notify(queue: .main) {
                continuation.finish()
            }
        }
    }

    private func loadImageData(from url: String, completion: @escaping (Result<Data, LoaderError>) -> Void) {
        
        // Check image is present into cache or not , if yes return the same image
        if let chachedImageData = self.getCachedImage(key: url) {
            completion(.success(chachedImageData))
            return
        }
        
        // If image is not present into cache load it from server.
        self.loadImageFromServer(from: url) { result in
            switch result {
            case.success(let imageData):
                completion(.success(imageData))
                // Save image into cache.
                self.cacheManager.setImage(for: url, data: imageData)
            case.failure(let error):
                print("Image loading from server is failed", error)
                completion(.failure(error))
            }
        }
    }
    
    /// Returns the cachedImage based on the key
    /// - Parameter key: Image URL
    /// - Returns: Image data
    private func getCachedImage(key: String) -> Data? {
        if let cacheImageData = self.cacheManager.getImage(for: key) {
            return cacheImageData
        }
        return nil
    }
    
    private func loadImageFromServer(from url: String, completion: @escaping (Result<Data, LoaderError>) -> Void) {
        imageProcessingQueue.async {
            self.networkManager.downloadImage(from: url) { result in
                switch result {
                case.success(let imageData) :
                    completion(.success(imageData))
                case.failure(let error) :
                    print(error)
                    completion(.failure(LoaderError.noData))
                }
            }
        }
    }
    
    //FIXME: Should we move this inside Utility class or extension?
    private func imageFromData(_ data: Data?) -> UIImage {
        if let imageData = data, let image = UIImage(data: imageData) {
            return image
        }
        return UIImage()
    }
}

/*
 Helps satisfy `Open Closed` principle since we are not modifying the existing ImageLoader and instead we extend the same class with additional capability (Deletion)
 */
extension ImageLoader: ImageCacheDeletion  {
    public func clearImage(for key: String) {
        self.cacheManager.clearImage(for: key)
    }
    
    public func clearImages(olderThan interval: TimeInterval) {
        cacheManager.clearImages(olderThan: interval)
    }
}
