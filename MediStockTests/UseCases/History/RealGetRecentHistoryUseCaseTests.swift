import XCTest
@testable import MediStock
@MainActor
final class RealGetRecentHistoryUseCaseTests: XCTestCase {
    
    var mockHistoryRepository: MockHistoryRepository!
    var getRecentHistoryUseCase: RealGetRecentHistoryUseCase!
    
    override func setUp() {
        super.setUp()
        mockHistoryRepository = MockHistoryRepository()
        getRecentHistoryUseCase = RealGetRecentHistoryUseCase(historyRepository: mockHistoryRepository)
    }
    
    override func tearDown() {
        mockHistoryRepository = nil
        getRecentHistoryUseCase = nil
        super.tearDown()
    }
    
    func testExecuteWithLimit() async throws {
        let baseDate = Date()
        let fullHistory = (1...10).map { index in
            HistoryEntry(
                id: "\(index)",
                medicineId: "med\(index)",
                userId: "user\(index)",
                action: "ADDED",
                details: "Details \(index)",
                timestamp: Calendar.current.date(byAdding: .minute, value: index, to: baseDate) ?? baseDate
            )
        }
        mockHistoryRepository.historyEntries = fullHistory
        
        let result = try await getRecentHistoryUseCase.execute(limit: 5)
        
        XCTAssertEqual(result.count, 5)
        // Repository returns sorted by timestamp descending (newest first)
        XCTAssertEqual(result[0].id, "10")  // Most recent
        XCTAssertEqual(result[4].id, "6")   // 5th most recent
    }
    
    func testExecuteWithZeroLimit() async throws {
        let history = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Details", timestamp: Date())
        ]
        mockHistoryRepository.historyEntries = history
        
        let result = try await getRecentHistoryUseCase.execute(limit: 0)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecuteWithLimitGreaterThanAvailable() async throws {
        let history = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Details", timestamp: Date()),
            HistoryEntry(id: "2", medicineId: "med2", userId: "user2", action: "REMOVED", details: "Details", timestamp: Date())
        ]
        mockHistoryRepository.historyEntries = history
        
        let result = try await getRecentHistoryUseCase.execute(limit: 10)
        
        XCTAssertEqual(result.count, 2)
    }
    
    func testExecuteWithEmptyHistory() async throws {
        mockHistoryRepository.historyEntries = []
        
        let result = try await getRecentHistoryUseCase.execute(limit: 5)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecuteThrowsError() async {
        mockHistoryRepository.shouldThrowError = true
        
        do {
            _ = try await getRecentHistoryUseCase.execute(limit: 5)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testExecuteWithNegativeLimit() async throws {
        let history = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Details", timestamp: Date())
        ]
        mockHistoryRepository.historyEntries = history
        
        let result = try await getRecentHistoryUseCase.execute(limit: -5)
        
        // Should return empty array for negative limit
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExecuteWithOne() async throws {
        let baseDate = Date()
        let history = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Details", timestamp: baseDate),
            HistoryEntry(id: "2", medicineId: "med2", userId: "user2", action: "REMOVED", details: "Details", timestamp: Calendar.current.date(byAdding: .minute, value: 1, to: baseDate) ?? baseDate)
        ]
        mockHistoryRepository.historyEntries = history
        
        let result = try await getRecentHistoryUseCase.execute(limit: 1)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, "2")  // Most recent entry
    }
    
    func testInitialization() {
        XCTAssertNotNil(getRecentHistoryUseCase)
        XCTAssertTrue(getRecentHistoryUseCase != nil)
    }
    
    func testExecuteDifferentLimits() async throws {
        let history = (1...20).map { index in
            HistoryEntry(
                id: "\(index)",
                medicineId: "med\(index)",
                userId: "user\(index)",
                action: "ADDED",
                details: "Details \(index)",
                timestamp: Date()
            )
        }
        mockHistoryRepository.historyEntries = history
        
        let limits = [1, 5, 10, 15, 20, 25]
        
        for limit in limits {
            let result = try await getRecentHistoryUseCase.execute(limit: limit)
            let expectedCount = min(limit, history.count)
            XCTAssertEqual(result.count, expectedCount)
        }
    }
    
    func testExecuteMultipleTimes() async throws {
        let history = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Details", timestamp: Date())
        ]
        mockHistoryRepository.historyEntries = history
        
        for _ in 0..<3 {
            let result = try await getRecentHistoryUseCase.execute(limit: 1)
            XCTAssertEqual(result.count, 1)
        }
    }
}
