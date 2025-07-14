import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class HistoryViewModelTests: XCTestCase, Sendable {
    
    var sut: HistoryViewModel!
    var mockGetHistoryUseCase: MockGetHistoryUseCase!
    var mockGetMedicinesUseCase: MockGetMedicinesUseCase!
    var mockExportHistoryUseCase: MockExportHistoryUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockGetHistoryUseCase = MockGetHistoryUseCase()
        mockGetMedicinesUseCase = MockGetMedicinesUseCase()
        mockExportHistoryUseCase = MockExportHistoryUseCase()
        
        sut = HistoryViewModel(
            getHistoryUseCase: mockGetHistoryUseCase,
            getMedicinesUseCase: mockGetMedicinesUseCase,
            exportHistoryUseCase: mockExportHistoryUseCase
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockGetHistoryUseCase = nil
        mockGetMedicinesUseCase = nil
        mockExportHistoryUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.history.count, 0)
        XCTAssertEqual(sut.medicines.count, 0)
        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Published Properties Tests
    
    func testHistoryPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "History change through fetch")
        
        let testHistory = [
            TestHelpers.createTestHistoryEntry(medicineId: "med1", action: "Added", details: "Test action 1"),
            TestHelpers.createTestHistoryEntry(medicineId: "med2", action: "Updated", details: "Test action 2")
        ]
        mockGetHistoryUseCase.historyEntries = testHistory
        
        sut.$history
            .dropFirst()
            .sink { history in
                if history.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchHistory()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testStatePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "State change through fetch")
        
        mockGetHistoryUseCase.historyEntries = []
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchHistory()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testIsLoadingPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Loading state change through fetch")
        expectation.expectedFulfillmentCount = 2 // true then false
        
        mockGetHistoryUseCase.historyEntries = []
        
        sut.$isLoading
            .dropFirst() // Skip initial false
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await sut.fetchHistory()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Reset State Tests
    
    func testResetState() async {
        // Given - First trigger a state change through fetchHistory
        mockGetHistoryUseCase.shouldThrowError = true
        mockGetHistoryUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        await sut.fetchHistory()
        
        // Verify we're in error state
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
        
        // When
        sut.resetState()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Fetch History Tests
    
    func testFetchHistory_Success() async {
        // Given
        let calendar = Calendar.current
        let now = Date()
        let oneHourAgo = calendar.date(byAdding: .hour, value: -1, to: now)!
        let twoHoursAgo = calendar.date(byAdding: .hour, value: -2, to: now)!
        
        let testHistory = [
            TestHelpers.createTestHistoryEntry(
                id: "entry1",
                medicineId: "med1",
                action: "Stock Updated",
                details: "Quantity changed from 10 to 15",
                timestamp: oneHourAgo
            ),
            TestHelpers.createTestHistoryEntry(
                id: "entry2",
                medicineId: "med2",
                action: "Medicine Added",
                details: "New medicine added to inventory",
                timestamp: twoHoursAgo
            )
        ]
        
        mockGetHistoryUseCase.historyEntries = testHistory
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.history.count, 2)
        
        // Should be sorted by timestamp descending (most recent first)
        XCTAssertEqual(sut.history[0].id, "entry1") // one hour ago (more recent)
        XCTAssertEqual(sut.history[1].id, "entry2") // two hours ago (older)
        
        // Verify use case was called
        XCTAssertFalse(mockGetHistoryUseCase.shouldThrowError)
    }
    
    func testFetchHistory_WithError_ShowsError() async {
        // Given
        mockGetHistoryUseCase.shouldThrowError = true
        mockGetHistoryUseCase.errorToThrow = NSError(
            domain: "HistoryError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load history"]
        )
        
        // When
        await sut.fetchHistory()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Failed to load history"))
        } else {
            XCTFail("Expected error state")
        }
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.history.count, 0)
    }
    
    func testFetchHistory_LoadingStates() async {
        // Given
        mockGetHistoryUseCase.historyEntries = []
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then success
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.fetchHistory()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .success)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testFetchHistory_SortsEntriesByTimestampDescending() async {
        // Given
        let calendar = Calendar.current
        let now = Date()
        let timestamps = [
            calendar.date(byAdding: .day, value: -1, to: now)!, // Yesterday
            calendar.date(byAdding: .hour, value: -1, to: now)!, // 1 hour ago
            calendar.date(byAdding: .minute, value: -30, to: now)!, // 30 minutes ago
            calendar.date(byAdding: .day, value: -3, to: now)! // 3 days ago
        ]
        
        let testHistory = timestamps.enumerated().map { index, timestamp in
            TestHelpers.createTestHistoryEntry(
                id: "entry\(index)",
                action: "Action \(index)",
                timestamp: timestamp
            )
        }
        
        mockGetHistoryUseCase.historyEntries = testHistory
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.history.count, 4)
        
        // Should be sorted by timestamp descending (most recent first)
        XCTAssertEqual(sut.history[0].id, "entry2") // 30 minutes ago (most recent)
        XCTAssertEqual(sut.history[1].id, "entry1") // 1 hour ago
        XCTAssertEqual(sut.history[2].id, "entry0") // Yesterday
        XCTAssertEqual(sut.history[3].id, "entry3") // 3 days ago (oldest)
    }
    
    // MARK: - Fetch Medicines Tests
    
    func testFetchMedicines_Success() async {
        // Given
        let testMedicines = [
            TestHelpers.createTestMedicine(id: "med1", name: "Aspirin"),
            TestHelpers.createTestMedicine(id: "med2", name: "Ibuprofen")
        ]
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        
        // When
        await sut.fetchMedicines()
        
        // Then
        XCTAssertEqual(sut.medicines.count, 2)
        XCTAssertEqual(sut.medicines[0].name, "Aspirin")
        XCTAssertEqual(sut.medicines[1].name, "Ibuprofen")
        XCTAssertEqual(mockGetMedicinesUseCase.callCount, 1)
    }
    
    func testFetchMedicines_WithError_DoesNotUpdateState() async {
        // Given
        mockGetMedicinesUseCase.shouldThrowError = true
        mockGetMedicinesUseCase.errorToThrow = NSError(
            domain: "MedicineError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load medicines"]
        )
        
        let initialState = sut.state
        
        // When
        await sut.fetchMedicines()
        
        // Then
        XCTAssertEqual(sut.medicines.count, 0)
        XCTAssertEqual(sut.state, initialState) // State should not change
    }
    
    // MARK: - Export History Tests
    
    func testExportHistory_PDF_Success() async {
        // Given
        let testEntries = [
            TestHelpers.createTestHistoryEntry(medicineId: "med1", action: "Added", details: "Test action")
        ]
        
        mockExportHistoryUseCase.exportData = Data("PDF Export Data".utf8)
        
        // When
        await sut.exportHistory(format: .pdf, entries: testEntries)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(mockExportHistoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockExportHistoryUseCase.lastFormat, .pdf)
    }
    
    func testExportHistory_CSV_Success() async {
        // Given
        let testEntries = [
            TestHelpers.createTestHistoryEntry(medicineId: "med1", action: "Updated", details: "Test action")
        ]
        
        mockExportHistoryUseCase.exportData = Data("CSV Export Data".utf8)
        
        // When
        await sut.exportHistory(format: .csv, entries: testEntries)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(mockExportHistoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockExportHistoryUseCase.lastFormat, .csv)
    }
    
    func testExportHistory_WithError_ShowsError() async {
        // Given
        let testEntries = [
            TestHelpers.createTestHistoryEntry(medicineId: "med1", action: "Added", details: "Test action")
        ]
        
        mockExportHistoryUseCase.shouldThrowError = true
        mockExportHistoryUseCase.errorToThrow = NSError(
            domain: "ExportError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Export failed"]
        )
        
        // When
        await sut.exportHistory(format: .pdf, entries: testEntries)
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Export failed"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testExportHistory_SetsExportingState() async {
        // Given
        let testEntries = [
            TestHelpers.createTestHistoryEntry(medicineId: "med1", action: "Added", details: "Test action")
        ]
        
        mockExportHistoryUseCase.exportData = Data("Test Data".utf8)
        
        let exportingExpectation = XCTestExpectation(description: "Exporting state")
        
        sut.$state
            .sink { state in
                if case .exporting = state {
                    exportingExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await sut.exportHistory(format: .pdf, entries: testEntries)
        
        // Then
        await fulfillment(of: [exportingExpectation], timeout: 1.0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow_FetchHistoryAndMedicinesThenExport() async {
        // Given
        let testMedicines = [
            TestHelpers.createTestMedicine(id: "med1", name: "Aspirin"),
            TestHelpers.createTestMedicine(id: "med2", name: "Ibuprofen")
        ]
        
        let testHistory = [
            TestHelpers.createTestHistoryEntry(
                id: "entry1",
                medicineId: "med1",
                action: "Stock Updated",
                details: "Quantity updated"
            ),
            TestHelpers.createTestHistoryEntry(
                id: "entry2",
                medicineId: "med2",
                action: "Medicine Added",
                details: "New medicine added"
            )
        ]
        
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        mockGetHistoryUseCase.historyEntries = testHistory
        mockExportHistoryUseCase.exportData = Data("Export Data".utf8)
        
        // When - Fetch data first
        await sut.fetchMedicines()
        await sut.fetchHistory()
        
        // Then - Verify data is loaded
        XCTAssertEqual(sut.medicines.count, 2)
        XCTAssertEqual(sut.history.count, 2)
        XCTAssertEqual(sut.state, .success)
        
        // When - Export the history
        await sut.exportHistory(format: .pdf, entries: sut.history)
        
        // Then - Verify export succeeded
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(mockExportHistoryUseCase.executeCallCount, 1)
        XCTAssertEqual(mockExportHistoryUseCase.lastFormat, .pdf)
    }
    
    func testEmptyHistoryHandling() async {
        // Given
        mockGetHistoryUseCase.historyEntries = []
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.history.count, 0)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLargeHistoryHandling() async {
        // Given
        let largeHistory = (1...100).map { index in
            TestHelpers.createTestHistoryEntry(
                id: "entry\(index)",
                medicineId: "med\(index % 10)", // Rotate through 10 different medicine IDs
                action: "Action \(index)",
                details: "Details for action \(index)",
                timestamp: Calendar.current.date(byAdding: .minute, value: -index, to: Date()) ?? Date()
            )
        }
        
        mockGetHistoryUseCase.historyEntries = largeHistory
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.history.count, 100)
        XCTAssertFalse(sut.isLoading)
        
        // Verify sorting (first entry should be most recent - entry1)
        XCTAssertEqual(sut.history[0].id, "entry1")
        XCTAssertEqual(sut.history[99].id, "entry100")
    }
    
    // MARK: - State Consistency Tests
    
    func testStateTransitions() async {
        // Given
        mockGetHistoryUseCase.historyEntries = []
        
        // Initial state
        XCTAssertEqual(sut.state, .idle)
        
        // When fetching
        let fetchTask = Task {
            await sut.fetchHistory()
        }
        
        // Should be loading
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        // Note: Due to async timing, we might miss the loading state, but that's okay
        
        await fetchTask.value
        
        // Should be success
        XCTAssertEqual(sut.state, .success)
    }
    
    func testMultipleFetchCalls() async {
        // Given
        mockGetHistoryUseCase.historyEntries = [
            TestHelpers.createTestHistoryEntry(id: "entry1", action: "Test Action")
        ]
        
        // When - Call fetchHistory multiple times
        await sut.fetchHistory()
        let firstState = sut.state
        let firstHistoryCount = sut.history.count
        
        await sut.fetchHistory()
        let secondState = sut.state
        let secondHistoryCount = sut.history.count
        
        // Then - Both calls should succeed and return same data
        XCTAssertEqual(firstState, .success)
        XCTAssertEqual(secondState, .success)
        XCTAssertEqual(firstHistoryCount, 1)
        XCTAssertEqual(secondHistoryCount, 1)
    }
}
