import Foundation
import PerfCalcCore

public protocol DataPackManaging {
    var provider: DataPackProvider { get }
    func loadBundledIfNeeded() throws
    func currentVersion() -> String
}

public final class DataPackManager: DataPackManaging {
    private let internalProvider: DataPackProvider

    public init(provider: DataPackProvider = StubDataPackProvider()) {
        self.internalProvider = provider
    }

    public var provider: DataPackProvider { internalProvider }

    public func loadBundledIfNeeded() throws {
        // Stub: In production, locate bundled or synced SQLite file, validate signature, and prepare GRDB database pool
        // Validate signature (stub)
        _ = validateSignature()
    }

    public func currentVersion() -> String {
        (try? internalProvider.dataPackVersion()) ?? "UNKNOWN"
    }

    private func validateSignature() -> Bool {
        // TODO: implement cryptographic signature verification of the Data Pack
        return true
    }
}