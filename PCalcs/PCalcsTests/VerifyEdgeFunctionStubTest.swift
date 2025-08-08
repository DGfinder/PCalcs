import XCTest
@testable import PCalcs

final class VerifyEdgeFunctionStubTest: XCTestCase {
    func testBuildVerifyRequest() throws {
        let mgr = CloudSyncManager()
        let id = UUID()
        let req = try mgr.buildVerifyRequest(id: id)
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertNotNil(req.url)
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        let body = try XCTUnwrap(req.httpBody)
        let obj = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(obj?["id"], id.uuidString)
    }
}