import XCTest
@testable import MediStock

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
        let expectedHistory = [
            HistoryEntry(id: "1", medicineId: "med1", userId: "user1", action: "ADDED", details: "Added medicine", timestamp: Date()),
            HistoryEntry(id: "2", medicineId: "med2", userId: "user2", action: "REMOVED", details: "Removed medicine", timestamp: Date())
        ]
        mockHistoryRepository.historyEntries = expectedHistory
        
        let result = try await getHistoryUseCase.execute()
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "1")
        XCTAssertEqual(result[1].id, "2")
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
        let largeHistory = (1...100).map { index in
            HistoryEntry(
                id: "\(index)",
                medicineId: "med\(index)",
                userId: "user\(index)",
                action: "ACTION_\(index)",
                details: "Details for entry \(index)",
                timestamp: Date()
            )
        }
        mockHistoryRepository.historyEntries = largeHistory
        
        let result = try await getHistoryUseCase.execute()
        
        XCTAssertEqual(result.count, 100)
        XCTAssertEqual(result.first?.id, "1")
        XCTAssertEqual(result.last?.id, "100")
    }
}