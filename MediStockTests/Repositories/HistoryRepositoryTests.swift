import XCTest
@testable import MediStock

@MainActor
final class HistoryRepositoryTests: XCTestCase {
    
    private var repository: HistoryRepository!
    private var mockDataService: MockHistoryDataServiceAdapter!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockHistoryDataServiceAdapter()
        repository = HistoryRepository(dataService: mockDataService)
    }
    
    override func tearDown() {
        repository = nil
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - Test: History Pagination Edge Cases
    
    func testHistoryPaginationEdgeCases() async throws {
        // Given: Setup history entries with various dates
        let baseDate = Date()
        let entries = (0..<55).map { index in
            HistoryEntry(
                id: "history-\(index)",
                medicineId: "med-\(index % 10)",
                userId: "user1",
                action: "Stock ajusté",
                details: "Ajustement de stock #\(index)",
                timestamp: baseDate.addingTimeInterval(Double(index) * -3600) // 1 hour apart
            )
        }
        mockDataService.mockHistory = entries
        
        // Test 1: Empty history
        mockDataService.mockHistory = []
        let emptyResult = try await repository.fetchHistory()
        XCTAssertTrue(emptyResult.isEmpty)
        
        // Test 2: Exactly one page (20 items)
        mockDataService.mockHistory = Array(entries.prefix(20))
        let onePageResult = try await repository.fetchHistory()
        XCTAssertEqual(onePageResult.count, 20)
        
        // Test 3: Multiple pages with partial last page
        mockDataService.mockHistory = entries // 55 items
        mockDataService.pageSize = 20
        
        // First page
        mockDataService.currentPage = 0
        let page1 = try await repository.fetchHistory()
        XCTAssertEqual(page1.count, 20)
        
        // Second page
        mockDataService.currentPage = 1
        let page2 = try await repository.fetchHistory()
        XCTAssertEqual(page2.count, 20)
        
        // Third page (partial)
        mockDataService.currentPage = 2
        let page3 = try await repository.fetchHistory()
        XCTAssertEqual(page3.count, 15)
        
        // Test 4: Beyond last page
        mockDataService.currentPage = 3
        let beyondPage = try await repository.fetchHistory()
        XCTAssertTrue(beyondPage.isEmpty)
        
        // Test 5: Large page size
        mockDataService.currentPage = 0
        mockDataService.pageSize = 100
        let largePage = try await repository.fetchHistory()
        XCTAssertEqual(largePage.count, 55)
    }
    
    // MARK: - Test: History Date Range Filtering
    
    func testHistoryDateRangeFiltering() async throws {
        // Given: History entries spread over 30 days
        let baseDate = Date()
        let entries = (0..<30).map { dayOffset in
            HistoryEntry(
                id: "history-day-\(dayOffset)",
                medicineId: "med-\(dayOffset % 5)",
                userId: "user1",
                action: dayOffset % 2 == 0 ? "Stock ajusté" : "Médicament créé",
                details: "Action du jour \(dayOffset)",
                timestamp: baseDate.addingTimeInterval(Double(dayOffset) * -86400) // Days in the past
            )
        }
        mockDataService.mockHistory = entries
        
        // Test 1: Filter last 7 days
        let sevenDaysAgo = baseDate.addingTimeInterval(-7 * 86400)
        mockDataService.dateFilter = { $0.timestamp >= sevenDaysAgo }
        let lastWeek = try await repository.fetchHistory()
        XCTAssertEqual(lastWeek.count, 8) // Days 0-7
        XCTAssertTrue(lastWeek.allSatisfy { $0.timestamp >= sevenDaysAgo })
        
        // Test 2: Filter specific date range (days 10-20)
        let startDate = baseDate.addingTimeInterval(-20 * 86400)
        let endDate = baseDate.addingTimeInterval(-10 * 86400)
        mockDataService.dateFilter = { $0.timestamp >= startDate && $0.timestamp <= endDate }
        let midRange = try await repository.fetchHistory()
        XCTAssertEqual(midRange.count, 11) // Days 10-20 inclusive
        
        // Test 3: Filter by action type
        mockDataService.dateFilter = nil
        mockDataService.actionFilter = { $0.action == "Stock ajusté" }
        let stockAdjustments = try await repository.fetchHistory()
        XCTAssertEqual(stockAdjustments.count, 15) // Even days only
        XCTAssertTrue(stockAdjustments.allSatisfy { $0.action == "Stock ajusté" })
        
        // Test 4: Combined filters (last 14 days + stock adjustments)
        let fourteenDaysAgo = baseDate.addingTimeInterval(-14 * 86400)
        mockDataService.dateFilter = { $0.timestamp >= fourteenDaysAgo }
        mockDataService.actionFilter = { $0.action == "Stock ajusté" }
        let combinedFilter = try await repository.fetchHistory()
        XCTAssertEqual(combinedFilter.count, 8) // Even days in last 14 days
        
        // Test 5: Filter by medicine ID
        mockDataService.dateFilter = nil
        mockDataService.actionFilter = nil
        mockDataService.medicineFilter = "med-2"
        let medicineHistory = try await repository.fetchHistory()
        XCTAssertEqual(medicineHistory.count, 6) // Days 2, 7, 12, 17, 22, 27
        XCTAssertTrue(medicineHistory.allSatisfy { $0.medicineId == "med-2" })
    }
    
    // MARK: - Test: History Data Integrity
    
    func testHistoryDataIntegrity() async throws {
        // Test 1: Verify entry immutability
        let originalEntry = HistoryEntry(
            id: "immutable-1",
            medicineId: "med-1",
            userId: "user1",
            action: "Stock ajusté",
            details: "Test immutability",
            timestamp: Date()
        )
        
        try await repository.addHistoryEntry(originalEntry)
        XCTAssertEqual(mockDataService.addedEntries.count, 1)
        XCTAssertEqual(mockDataService.addedEntries.first?.id, originalEntry.id)
        
        // Test 2: Verify chronological ordering
        let entries = (0..<10).map { index in
            HistoryEntry(
                id: "chrono-\(index)",
                medicineId: "med-1",
                userId: "user1",
                action: "Action \(index)",
                details: "Details \(index)",
                timestamp: Date().addingTimeInterval(Double(index) * -60)
            )
        }
        
        for entry in entries.shuffled() {
            try await repository.addHistoryEntry(entry)
        }
        
        mockDataService.sortByDateDescending = true
        let sorted = try await repository.fetchHistory()
        
        // Verify descending order
        for i in 0..<sorted.count-1 {
            XCTAssertTrue(sorted[i].timestamp >= sorted[i+1].timestamp)
        }
        
        // Test 3: Verify required fields
        let incompleteEntry = HistoryEntry(
            id: "",
            medicineId: "med-1",
            userId: "user1",
            action: "Test",
            details: "Test",
            timestamp: Date()
        )
        
        mockDataService.shouldValidate = true
        do {
            try await repository.addHistoryEntry(incompleteEntry)
            XCTFail("Expected validation error for empty ID")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test 4: Verify duplicate prevention
        let duplicateEntry = HistoryEntry(
            id: "duplicate-1",
            medicineId: "med-1",
            userId: "user1",
            action: "Test",
            details: "Original",
            timestamp: Date()
        )
        
        try await repository.addHistoryEntry(duplicateEntry)
        
        mockDataService.preventDuplicates = true
        do {
            try await repository.addHistoryEntry(duplicateEntry)
            XCTFail("Expected error for duplicate entry")
        } catch {
            XCTAssertNotNil(error)
        }
        
        // Test 5: Verify data consistency
        let testEntry = HistoryEntry(
            id: "consistency-1",
            medicineId: "med-123",
            userId: "user-456",
            action: "Stock ajusté de 100 à 150",
            details: "Réapprovisionnement mensuel",
            timestamp: Date()
        )
        
        try await repository.addHistoryEntry(testEntry)
        
        let retrieved = mockDataService.addedEntries.last
        XCTAssertEqual(retrieved?.id, testEntry.id)
        XCTAssertEqual(retrieved?.medicineId, testEntry.medicineId)
        XCTAssertEqual(retrieved?.userId, testEntry.userId)
        XCTAssertEqual(retrieved?.action, testEntry.action)
        XCTAssertEqual(retrieved?.details, testEntry.details)
        if let retrievedTimestamp = retrieved?.timestamp {
            XCTAssertEqual(retrievedTimestamp.timeIntervalSince1970, 
                          testEntry.timestamp.timeIntervalSince1970, 
                          accuracy: 1.0)
        }
    }
    
    // MARK: - Test: Fetch History for Specific Medicine
    
    func testFetchHistoryForMedicine() async throws {
        // Given: Mixed history entries
        let entries = [
            HistoryEntry(id: "1", medicineId: "med-A", userId: "user1", action: "Créé", details: "Création", timestamp: Date()),
            HistoryEntry(id: "2", medicineId: "med-B", userId: "user1", action: "Modifié", details: "Modification", timestamp: Date()),
            HistoryEntry(id: "3", medicineId: "med-A", userId: "user2", action: "Stock ajusté", details: "Ajustement", timestamp: Date()),
            HistoryEntry(id: "4", medicineId: "med-C", userId: "user1", action: "Supprimé", details: "Suppression", timestamp: Date()),
            HistoryEntry(id: "5", medicineId: "med-A", userId: "user1", action: "Expiré", details: "Expiration", timestamp: Date())
        ]
        mockDataService.mockHistory = entries
        
        // When: Fetch history for specific medicine
        mockDataService.medicineFilter = "med-A"
        let medicineAHistory = try await repository.fetchHistoryForMedicine("med-A")
        
        // Then: Only entries for that medicine
        XCTAssertEqual(medicineAHistory.count, 3)
        XCTAssertTrue(medicineAHistory.allSatisfy { $0.medicineId == "med-A" })
        XCTAssertEqual(Set(medicineAHistory.map { $0.id }), Set(["1", "3", "5"]))
    }
}

// MARK: - Mock History Data Service Adapter

class MockHistoryDataServiceAdapter: DataServiceAdapter {
    var mockHistory: [HistoryEntry] = []
    var addedEntries: [HistoryEntry] = []
    var shouldThrowError = false
    var errorToThrow: Error?
    
    // Pagination
    var currentPage = 0
    var pageSize = 20
    
    // Filtering
    var dateFilter: ((HistoryEntry) -> Bool)?
    var actionFilter: ((HistoryEntry) -> Bool)?
    var medicineFilter: String?
    
    // Validation
    var shouldValidate = false
    var preventDuplicates = false
    var sortByDateDescending = false
    
    override func getHistory(for medicineId: String? = nil) async throws -> [HistoryEntry] {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        var result = mockHistory
        
        // Apply medicine filter
        if let medicineId = medicineId ?? medicineFilter {
            result = result.filter { $0.medicineId == medicineId }
        }
        
        // Apply date filter
        if let filter = dateFilter {
            result = result.filter(filter)
        }
        
        // Apply action filter
        if let filter = actionFilter {
            result = result.filter(filter)
        }
        
        // Sort if needed
        if sortByDateDescending {
            result = result.sorted { $0.timestamp > $1.timestamp }
        }
        
        // Apply pagination
        let startIndex = currentPage * pageSize
        let endIndex = min(startIndex + pageSize, result.count)
        
        guard startIndex < result.count else {
            return []
        }
        
        return Array(result[startIndex..<endIndex])
    }
    
    override func addHistoryEntry(_ entry: HistoryEntry) async throws {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        // Validation
        if shouldValidate {
            if entry.id.isEmpty {
                throw ValidationError.invalidId
            }
        }
        
        // Duplicate prevention
        if preventDuplicates {
            if addedEntries.contains(where: { $0.id == entry.id }) {
                throw ValidationError.nameAlreadyExists(name: entry.id)
            }
        }
        
        addedEntries.append(entry)
        mockHistory.append(entry)
    }
}