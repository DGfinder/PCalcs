import Foundation

enum WindMath {
    static func components(runwayHeadingDeg: Double, windDirDeg: Double?, windKt: Int?) -> (headKt: Double, crossKt: Double, right: Bool)? {
        guard let dir = windDirDeg, let spd = windKt else { return nil }
        let rel = ((Double(dir) - runwayHeadingDeg) * .pi / 180)
        let head = Double(spd) * cos(rel)
        let cross = Double(spd) * sin(rel)
        return (head, abs(cross), cross < 0)
    }
}