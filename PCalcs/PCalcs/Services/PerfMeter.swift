import Foundation
import SwiftUI

struct PerfSample: Identifiable { let id = UUID(); let name: String; let ms: Double; let timestamp: Date }

final class PerfMeter: ObservableObject {
    static let shared = PerfMeter()
    @Published private(set) var samples: [PerfSample] = []
    private init() {}

    func log(name: String, ms: Double) {
        DispatchQueue.main.async {
            var s = self.samples
            s.insert(PerfSample(name: name, ms: ms, timestamp: Date()), at: 0)
            if s.count > 20 { s.removeLast(s.count - 20) }
            self.samples = s
        }
        #if DEBUG
        if name == "whatif" && ms > 16 { print("[Perf] What-If \(ms) ms > 16 ms budget") }
        if name == "calc" && ms > 100 { print("[Perf] Calc \(ms) ms > 100 ms budget") }
        #endif
    }
}

@discardableResult
func measure<T>(_ name: String, block: () -> T) -> T {
    let start = CFAbsoluteTimeGetCurrent()
    let result = block()
    let end = CFAbsoluteTimeGetCurrent()
    PerfMeter.shared.log(name: name, ms: (end - start) * 1000)
    return result
}