import Foundation
import os.log
import UIKit

/// Centralized logging for PCalcs
enum PCalcsLogger {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.penjetaviation.pcalcs", category: "default")
    
    static func info(_ message: String) {
        logger.info("\(message)")
    }
    
    static func error(_ message: String) {
        logger.error("\(message)")
    }
    
    static func warn(_ message: String) {
        logger.warning("\(message)")
    }
    
    static func debug(_ message: String) {
        logger.debug("\(message)")
    }
}

extension UIDevice {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            let scalar = UnicodeScalar(UInt8(value))
            return identifier + String(scalar)
        }
        return identifier
    }
}