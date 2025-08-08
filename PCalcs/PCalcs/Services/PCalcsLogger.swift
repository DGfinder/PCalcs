import Foundation
import os

enum PCalcsLogger {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PCalcs", category: "PCalcs")

    static func info(_ message: String) { logger.info("\(message, privacy: .public)") }
    static func error(_ message: String) { logger.error("\(message, privacy: .public)") }
}