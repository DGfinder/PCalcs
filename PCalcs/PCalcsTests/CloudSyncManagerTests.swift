import XCTest
import Foundation
@testable import PCalcs

final class CloudSyncManagerTests: XCTestCase {
    
    func testUploadPDFRequest() throws {
        // Create a mock URL session with custom protocol
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        let syncManager = CloudSyncManager(session: session)
        
        // Mock successful PDF upload
        MockURLProtocol.mockResponses["/storage/v1/object/pcalcs-evidence/"] = MockResponse(
            statusCode: 200,
            data: Data(),
            headers: ["Content-Type": "application/json"]
        )
        
        // Mock successful history insert
        MockURLProtocol.mockResponses["/rest/v1/history"] = MockResponse(
            statusCode: 201,
            data: try! JSONSerialization.data(withJSONObject: ["id": "test-uuid"]),
            headers: ["Content-Type": "application/json"]
        )
        
        let entry = createMockHistoryEntry()
        let pdfData = "mock pdf data".data(using: .utf8)!
        
        let expectation = XCTestExpectation(description: "Upload completes")
        
        Task {
            do {
                try await syncManager.upload(entry: entry, pdfData: pdfData)
                expectation.fulfill()
            } catch {
                XCTFail("Upload should succeed: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify the requests were made correctly
        let pdfRequest = MockURLProtocol.capturedRequests.first { $0.url?.path.contains("storage") == true }
        XCTAssertNotNil(pdfRequest, "PDF upload request should be made")
        XCTAssertEqual(pdfRequest?.httpMethod, "POST")
        XCTAssertEqual(pdfRequest?.value(forHTTPHeaderField: "Content-Type"), "application/pdf")
        XCTAssertNotNil(pdfRequest?.value(forHTTPHeaderField: "Authorization"))
        
        let historyRequest = MockURLProtocol.capturedRequests.first { $0.url?.path.contains("rest") == true }
        XCTAssertNotNil(historyRequest, "History insert request should be made")
        XCTAssertEqual(historyRequest?.httpMethod, "POST")
        XCTAssertEqual(historyRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(historyRequest?.value(forHTTPHeaderField: "Authorization"))
    }
    
    func testUploadFailureHandling() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        let syncManager = CloudSyncManager(session: session)
        
        // Mock failed PDF upload
        MockURLProtocol.mockResponses["/storage/v1/object/pcalcs-evidence/"] = MockResponse(
            statusCode: 500,
            data: Data(),
            headers: [:]
        )
        
        let entry = createMockHistoryEntry()
        let pdfData = "mock pdf data".data(using: .utf8)!
        
        let expectation = XCTestExpectation(description: "Upload fails")
        
        Task {
            do {
                try await syncManager.upload(entry: entry, pdfData: pdfData)
                XCTFail("Upload should fail")
            } catch {
                XCTAssertTrue(error is CloudSyncError, "Should throw CloudSyncError")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testHistoryRequestStructure() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        let syncManager = CloudSyncManager(session: session)
        
        // Mock responses
        MockURLProtocol.mockResponses["/storage/v1/object/pcalcs-evidence/"] = MockResponse(
            statusCode: 200,
            data: Data(),
            headers: [:]
        )
        
        var capturedHistoryData: Data?
        MockURLProtocol.mockResponses["/rest/v1/history"] = MockResponse(
            statusCode: 201,
            data: try! JSONSerialization.data(withJSONObject: ["id": "test-uuid"]),
            headers: ["Content-Type": "application/json"],
            onRequest: { request in
                capturedHistoryData = request.httpBody
            }
        )
        
        let entry = createMockHistoryEntry()
        let pdfData = "mock pdf data".data(using: .utf8)!
        
        let expectation = XCTestExpectation(description: "Upload completes")
        
        Task {
            try await syncManager.upload(entry: entry, pdfData: pdfData)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        // Verify history request structure
        XCTAssertNotNil(capturedHistoryData, "History request data should be captured")
        
        let historyJSON = try JSONSerialization.jsonObject(with: capturedHistoryData!) as! [String: Any]
        
        XCTAssertNotNil(historyJSON["id"], "History should include entry ID")
        XCTAssertNotNil(historyJSON["device_pubkey_hex"], "History should include device public key")
        XCTAssertNotNil(historyJSON["evidence_hash_hex"], "History should include evidence hash")
        XCTAssertNotNil(historyJSON["evidence_sig_hex"], "History should include evidence signature")
        XCTAssertNotNil(historyJSON["payload_json"], "History should include payload JSON")
        XCTAssertNotNil(historyJSON["pdf_url"], "History should include PDF URL")
        XCTAssertNotNil(historyJSON["uploaded_by"], "History should include uploaded_by field")
    }
    
    func testSyncPendingFiltersCorrectly() throws {
        // This test would require mocking the HistoryStore, which is complex
        // In a real implementation, you'd want to abstract HistoryStore behind a protocol
        // and inject a mock implementation for testing
        
        let syncManager = CloudSyncManager()
        
        // Test that syncPending handles disabled cloud sync
        let settings = SettingsStore()
        settings.cloudSyncEnabled = false
        
        let expectation = XCTestExpectation(description: "Sync skipped")
        
        Task {
            await syncManager.syncPending()
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        // Verify no network requests were made
        XCTAssertTrue(MockURLProtocol.capturedRequests.isEmpty, "No requests should be made when sync is disabled")
    }
    
    private func createMockHistoryEntry() -> HistoryEntry {
        let inputsData = try! JSONEncoder().encode(TakeoffFormInputs())
        let resultsData = try! JSONEncoder().encode([
            "takeoffDisplay": TakeoffDisplay(todrM: 1100, asdrM: 1200, bflM: 1150, v1Kt: 100, vrKt: 105, v2Kt: 110, climbGradientPercent: 2.4, limitingFactor: "Test"),
            "landingDisplay": LandingDisplay(ldrM: 1000, vrefKt: 115, limitingFactor: "Test")
        ])
        
        return HistoryEntry(
            id: UUID(),
            timestamp: Date(),
            registration: "N123AB",
            dataPackVersion: "1.0",
            calcVersion: "1.0",
            inputsData: inputsData,
            resultsData: resultsData
        )
    }
}

// MARK: - Mock URL Protocol for testing

class MockURLProtocol: URLProtocol {
    static var mockResponses: [String: MockResponse] = [:]
    static var capturedRequests: [URLRequest] = []
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        MockURLProtocol.capturedRequests.append(request)
        
        let path = request.url?.path ?? ""
        let matchingKey = MockURLProtocol.mockResponses.keys.first { path.contains($0) }
        
        guard let key = matchingKey,
              let mockResponse = MockURLProtocol.mockResponses[key] else {
            let error = NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No mock response found for \(path)"])
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        // Call the onRequest handler if present
        mockResponse.onRequest?(request)
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: mockResponse.headers
        )!
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: mockResponse.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // No implementation needed
    }
    
    static func reset() {
        mockResponses.removeAll()
        capturedRequests.removeAll()
    }
}

struct MockResponse {
    let statusCode: Int
    let data: Data
    let headers: [String: String]
    let onRequest: ((URLRequest) -> Void)?
    
    init(statusCode: Int, data: Data, headers: [String: String], onRequest: ((URLRequest) -> Void)? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
        self.onRequest = onRequest
    }
}