
import Foundation

class Utility {
    func getCacheDirectory() -> URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }
    
    func fileName(from urlString: String) -> String {
        if let url = URL(string: urlString) {
            return url.lastPathComponent
        }
        return UUID().uuidString + ".jpg"
    }
    
    func startTimer() -> CFAbsoluteTime {
        let start = CFAbsoluteTimeGetCurrent()
        return start
    }
    
    func endTimer() -> CFAbsoluteTime {
        let end = CFAbsoluteTimeGetCurrent()
        return end
    }
}
