
import Foundation

class ImageDownloader {
    func downloadImage(from url: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let imageURL = URL(string: url) else {
            print("Invalid URL")
            return
        }
        let task = URLSession.shared.dataTask(with: imageURL) { data, response, error in
            if let error = error {
                print("Error downloading image: \(error.localizedDescription)")
                return
            }
            guard let data = data else {
                print("Failed to get data")
                return
            }
            
            completion(.success(data))
        }
        task.resume()
    }
}
