#if canImport(GRDB)
import XCTest
import GRDB
@testable import PCalcs

final class GRDBDataPackProviderTests: XCTestCase {
    private func makeInMemoryDB() throws -> DatabaseQueue {
        let dbQueue = try DatabaseQueue(path: ":memory:")
        try dbQueue.write { db in
            try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS limits (aircraft TEXT NOT NULL, key TEXT NOT NULL, value REAL NOT NULL, PRIMARY KEY (aircraft, key));
            CREATE INDEX IF NOT EXISTS idx_limits_aircraft ON limits(aircraft);
            CREATE TABLE IF NOT EXISTS v_speeds (
              aircraft TEXT NOT NULL,
              weight_kg REAL NOT NULL,
              flap INT NOT NULL,
              v1_kt REAL,
              vr_kt REAL,
              v2_kt REAL,
              vref_kt REAL,
              PRIMARY KEY (aircraft, weight_kg, flap)
            );
            CREATE INDEX IF NOT EXISTS idx_vspeeds_afw ON v_speeds(aircraft, flap, weight_kg);
            CREATE TABLE IF NOT EXISTS to_tables (
              aircraft TEXT NOT NULL,
              flap INT NOT NULL,
              bleeds_on INT NOT NULL,
              anti_ice_on INT NOT NULL,
              weight_kg REAL NOT NULL,
              pa_m REAL NOT NULL,
              oat_c REAL NOT NULL,
              todr_m REAL,
              asdr_m REAL,
              bfl_m REAL,
              oei_net_climb_pct REAL,
              PRIMARY KEY (aircraft, flap, bleeds_on, anti_ice_on, weight_kg, pa_m, oat_c)
            );
            CREATE INDEX IF NOT EXISTS idx_to_query ON to_tables(aircraft, flap, bleeds_on, anti_ice_on, weight_kg, pa_m, oat_c);
            CREATE TABLE IF NOT EXISTS ld_tables (
              aircraft TEXT NOT NULL,
              flap INT NOT NULL,
              anti_ice_on INT NOT NULL,
              weight_kg REAL NOT NULL,
              pa_m REAL NOT NULL,
              oat_c REAL NOT NULL,
              ldr_m REAL,
              PRIMARY KEY (aircraft, flap, anti_ice_on, weight_kg, pa_m, oat_c)
            );
            CREATE INDEX IF NOT EXISTS idx_ld_query ON ld_tables(aircraft, flap, anti_ice_on, weight_kg, pa_m, oat_c);
            CREATE TABLE IF NOT EXISTS corrections (
              aircraft TEXT NOT NULL,
              corr_type TEXT NOT NULL,
              axis TEXT NOT NULL,
              value REAL NOT NULL,
              effect REAL NOT NULL,
              PRIMARY KEY (aircraft, corr_type, axis, value)
            );
            CREATE INDEX IF NOT EXISTS idx_corr_type ON corrections(aircraft, corr_type, axis, value);
            """)
            // Seed
            try db.execute(sql: "INSERT INTO metadata(key,value) VALUES('data_version','TEST-1.0');")
            try db.execute(sql: "INSERT INTO limits(aircraft,key,value) VALUES('B1900D','maxTOWkg',7550),('B1900D','maxLDWkg',7200);")
            // v_speeds for flap 0 at weights 6000 and 7000
            try db.execute(sql: "INSERT INTO v_speeds(aircraft,weight_kg,flap,v1_kt,vr_kt,v2_kt,vref_kt) VALUES" +
                           "('B1900D',6000,0, 95,100,105,110)," +
                           "('B1900D',7000,0, 100,105,110,115);")
            // to_tables cube: weights 6000,7000; pas 0,1000; oats 0,20
            func insTO(_ w: Int,_ pa: Int,_ oat: Int,_ todr: Int,_ asdr: Int,_ bfl: Int,_ climb: Double) throws {
                try db.execute(sql: "INSERT INTO to_tables(aircraft,flap,bleeds_on,anti_ice_on,weight_kg,pa_m,oat_c,todr_m,asdr_m,bfl_m,oei_net_climb_pct) VALUES('B1900D',0,1,0,?,?,?,?,?,?,?)", arguments: [w, pa, oat, todr, asdr, bfl, climb])
            }
            try insTO(6000, 0, 0,   900,1000,950, 2.5)
            try insTO(6000, 0, 20,  950,1050,1000,2.4)
            try insTO(6000, 1000, 0,1000,1100,1050,2.3)
            try insTO(6000, 1000, 20,1050,1150,1100,2.2)
            try insTO(7000, 0, 0,  1000,1100,1050,2.4)
            try insTO(7000, 0, 20, 1050,1150,1100,2.3)
            try insTO(7000, 1000, 0,1100,1200,1150,2.2)
            try insTO(7000, 1000, 20,1150,1250,1200,2.1)
            // ld_tables cube: same grid; ldr grows similarly
            func insLD(_ w: Int,_ pa: Int,_ oat: Int,_ ldr: Int) throws {
                try db.execute(sql: "INSERT INTO ld_tables(aircraft,flap,anti_ice_on,weight_kg,pa_m,oat_c,ldr_m) VALUES('B1900D',0,0,?,?,?,?,?)", arguments: [w, pa, oat, ldr])
            }
            try insLD(6000, 0, 0,   800)
            try insLD(6000, 0, 20,  840)
            try insLD(6000, 1000, 0,880)
            try insLD(6000, 1000, 20,920)
            try insLD(7000, 0, 0,  900)
            try insLD(7000, 0, 20, 940)
            try insLD(7000, 1000, 0,980)
            try insLD(7000, 1000, 20,1020)
        }
        return dbQueue
    }

    func makeProvider() throws -> GRDBDataPackProvider {
        let q = try makeInMemoryDB()
        // Write DB to a temporary file because DatabaseQueue(path: ":memory:") cannot be re-opened by URL
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("DataPackTest.sqlite")
        // Export the in-memory to disk for provider init
        try q.write { db in
            let dest = try DatabaseQueue(path: tmp.path)
            try dest.write { ddb in
                try db.backup(to: ddb)
            }
        }
        return try GRDBDataPackProvider(databaseURL: tmp)
    }

    func testMetadataAndLimits() throws {
        let provider = try makeProvider()
        XCTAssertEqual(try provider.dataPackVersion(), "TEST-1.0")
        let lim = try provider.limits(aircraft: .beech1900D)
        XCTAssertEqual(lim["maxTOWkg"], 7550)
        XCTAssertEqual(lim["maxLDWkg"], 7200)
    }

    func testVSpeedsExactAndLinear() throws {
        let p = try makeProvider()
        // Exact
        let exact = try p.lookupVSpeeds(aircraft: .beech1900D, weightKg: 6000, flapSetting: 0)
        XCTAssertEqual(exact["v1_kt"], 95, accuracy: 1e-9)
        // Mid-weight 6500: average
        let mid = try p.lookupVSpeeds(aircraft: .beech1900D, weightKg: 6500, flapSetting: 0)
        XCTAssertEqual(mid["v1_kt"], 97.5, accuracy: 1e-9)
        XCTAssertEqual(mid["vref_kt"], 112.5, accuracy: 1e-9)
    }

    func testTakeoffBilinearThenLinear() throws {
        let p = try makeProvider()
        // Interior point: weight 6500, pa 500, oat 10
        let m = try p.lookupTakeoff(aircraft: .beech1900D, weightKg: 6500, pressureAltitudeM: 500, oatC: 10, flapSetting: 0, bleedsOn: true, antiIceOn: false)
        // Expect mid-point of each dimension (all planes are affine) -> average of the 8 cube corners
        // For our seeded data, the result should be exactly midway between w=6000 and w=7000 bilinear results.
        // Check TODR specifically: (6000 plane bilinear at 500/10 is 975), (7000 plane 1075), linear across weight -> 1025
        XCTAssertEqual(m["todr_m"], 1025, accuracy: 1e-9)
        XCTAssertEqual(m["asdr_m"], 1125, accuracy: 1e-9)
        XCTAssertEqual(m["bfl_m"], 1075, accuracy: 1e-9)
    }

    func testLandingBilinearThenLinear() throws {
        let p = try makeProvider()
        let m = try p.lookupLanding(aircraft: .beech1900D, weightKg: 6500, pressureAltitudeM: 500, oatC: 10, flapSetting: 0, antiIceOn: false)
        // 6000 plane bilinear at 500/10 = 860; 7000 plane = 960; linear across weight = 910
        XCTAssertEqual(m["ldr_m"], 910, accuracy: 1e-9)
    }

    func testOutOfBounds() throws {
        let p = try makeProvider()
        XCTAssertThrowsError(try p.lookupVSpeeds(aircraft: .beech1900D, weightKg: 5000, flapSetting: 0)) { err in
            guard case CalculationError.outOfCertifiedEnvelope = err else { return XCTFail("Expected outOfCertifiedEnvelope") }
        }
        XCTAssertThrowsError(try p.lookupTakeoff(aircraft: .beech1900D, weightKg: 6500, pressureAltitudeM: -100, oatC: 10, flapSetting: 0, bleedsOn: true, antiIceOn: false)) { err in
            guard case CalculationError.outOfCertifiedEnvelope = err else { return XCTFail("Expected outOfCertifiedEnvelope") }
        }
    }

    func testMissingCornerThrows() throws {
        // Create DB with a missing corner
        let db = try DatabaseQueue(path: ":memory:")
        try db.write { db in
            try db.execute(sql: "CREATE TABLE metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);")
            try db.execute(sql: "CREATE TABLE to_tables(aircraft TEXT, flap INT, bleeds_on INT, anti_ice_on INT, weight_kg REAL, pa_m REAL, oat_c REAL, todr_m REAL, asdr_m REAL, bfl_m REAL, oei_net_climb_pct REAL, PRIMARY KEY(aircraft,flap,bleeds_on,anti_ice_on,weight_kg,pa_m,oat_c));")
            try db.execute(sql: "INSERT INTO to_tables VALUES('B1900D',0,1,0,6000,0,0,1000,1100,1050,2.3);")
            try db.execute(sql: "INSERT INTO to_tables VALUES('B1900D',0,1,0,6000,0,20,1050,1150,1100,2.2);")
            try db.execute(sql: "INSERT INTO to_tables VALUES('B1900D',0,1,0,6000,1000,0,1100,1200,1150,2.1);")
            // Missing (pa=1000,oat=20)
        }
        // Persist for provider
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("DataPackMissing.sqlite")
        try db.write { db in
            let dest = try DatabaseQueue(path: tmp.path)
            try dest.write { ddb in try db.backup(to: ddb) }
        }
        let provider = try GRDBDataPackProvider(databaseURL: tmp)
        XCTAssertThrowsError(try provider.lookupTakeoff(aircraft: .beech1900D, weightKg: 6000, pressureAltitudeM: 500, oatC: 10, flapSetting: 0, bleedsOn: true, antiIceOn: false)) { err in
            guard case CalculationError.dataUnavailable(let reason) = err else { return XCTFail("Expected dataUnavailable") }
            XCTAssertTrue(reason.contains("Missing takeoff corner"))
        }
    }
}
#endif