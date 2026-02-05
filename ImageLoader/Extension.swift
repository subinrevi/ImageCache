
import Foundation

extension Int {
    var seconds: TimeInterval { TimeInterval(self) }
    var minutes: TimeInterval { TimeInterval(self) * 60 }
    var hours: TimeInterval { TimeInterval(self) * 60 * 60 }
    var days: TimeInterval { TimeInterval(self) * 60 * 60 * 24 }
    
    var megabytes: Int { self * 1024 * 1024}
}

