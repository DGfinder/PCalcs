import Foundation

struct ObstacleEngineResult {
    let meetsObstacleClearance: Bool
    let limitingObstacle: Obstacle?
    let requiredGradientPct: Double
    let marginPct: Double
}

struct ObstacleEngine {
    static func evaluate(runwayHeadingDeg: Double,
                         obstacles: [Obstacle],
                         netOEIGradientPct: Double,
                         screenHeightM: Double) -> ObstacleEngineResult {
        var worstRequired: Double = 0
        var limiting: Obstacle? = nil
        for obs in obstacles {
            // Straight out only: assume bearing alignment within ±30 deg of runway heading considered relevant; else skip for v1
            let delta = angularDiffDeg(a: runwayHeadingDeg, b: obs.bearingDeg)
            guard abs(delta) <= 30 else { continue }
            let required = (obs.heightM + screenHeightM) / max(obs.distanceM, 1.0) * 100.0
            if required > worstRequired { worstRequired = required; limiting = obs }
        }
        let margin = netOEIGradientPct - worstRequired
        return ObstacleEngineResult(meetsObstacleClearance: margin >= 0, limitingObstacle: limiting, requiredGradientPct: worstRequired, marginPct: margin)
    }

    private static func angularDiffDeg(a: Double, b: Double) -> Double {
        var d = (a - b).truncatingRemainder(dividingBy: 360)
        if d > 180 { d -= 360 }
        if d < -180 { d += 360 }
        return d
    }
}