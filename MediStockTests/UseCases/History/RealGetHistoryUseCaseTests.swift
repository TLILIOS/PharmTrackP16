import XCTest
@testable import MediStock
@MainActor
final class RealGetHistoryUseCaseTests: XCTestCase {
    
    var mockHistoryRepository: MockHistoryRepository!
    var getHistoryUseCase: RealGetHistoryUseCase!
    
    override func setUp() {
        super.setUp()
        mockHistoryRepository = MockHistoryRepository()
        getHistoryUseCase = RealGetHistoryUseCase(historyRepository: mockHistoryRepository)
    }
    
    override func tearDown() {
        mockHistoryRepository = nil
        getHistoryUseCase = nil
        super.tearDown()
    }
    
    func testExecuteSuccess() async throws {
        let now = Date()
        let oneHourAgo = now.addingTimeInterval(-3600)
        
        let expectedHistory = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Added medicine", timestamp: oneHourAgo),
            HistoryEntry(id: "2", medicineId: "med2", userId: "user2", action: "REMOVED", details: "Removed medicine", timestamp: now)
        ]
        mockHistoryRepository.historyEntries = expectedHistory
        
        let result = try await getHistoryUseCase.execute()
        
        XCTAssertEqual(result.count, 2)
        // History is sorted by timestamp descending (most recent first)
        XCTAssertEqual(result[0].id, "2")
        XCTAssertEqual(result[1].id, "1")
    }
    
    func testExecuteEmptyHistory() async throws {
        mockHistoryRepository.historyEntries = []
        
        let result = try await getHistoryUseCase.execute()
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecuteThrowsError() async {
        mockHistoryRepository.shouldThrowError = true
        
        do {
            _ = try await getHistoryUseCase.execute()
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testInitialization() {
        XCTAssertNotNil(getHistoryUseCase)
        XCTAssertTrue(getHistoryUseCase is GetHistoryUseCaseProtocol)
    }
    
    func testExecuteMultipleTimes() async throws {
        let history = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Added medicine", timestamp: Date())
        ]
        mockHistoryRepository.historyEntries = history
        
        for _ in 0..<3 {
            let result = try await getHistoryUseCase.execute()
            XCTAssertEqual(result.count, 1)
        }
    }
    
    func testExecuteWithLargeDataset() async throws {
        let baseDate = Date()
        let largeHistory = (1...100).map { index in
            HistoryEntry(
                id: "\(index)",
                medicineId: "med\(index)",
                userId: "user\(index)",
                action: "ACTION_\(index)",
                details: "Details for entry \(index)",
                timestamp: baseDate.addingTimeInterval(-Double(index))
            )
        }
        mockHistoryRepository.historyEntries = largeHistory
        
        let result = try await getHistoryUseCase.execute()
        
        XCTAssertEqual(result.count, 100)
        // History is sorted by timestamp descending (most recent first)
        // So the first entry should be the one with the smallest index (most recent)
        XCTAssertEqual(result.first?.id, "1")
        XCTAssertEqual(result.last?.id, "100")
    }
}
