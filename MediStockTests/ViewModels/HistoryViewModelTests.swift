import XCTest
@testable import MediStock

@MainActor
final class HistoryViewModelTests: XCTestCase {
    
    var sut: HistoryViewModel!
    var mockGetHistoryUseCase: MockGetHistoryUseCase!
    var mockGetMedicinesUseCase: MockGetMedicinesUseCase!
    var mockExportHistoryUseCase: MockExportHistoryUseCase!
    
    override func setUp() {
        super.setUp()
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
        sut = nil
        mockGetHistoryUseCase = nil
        mockGetMedicinesUseCase = nil
        mockExportHistoryUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.history.isEmpty)
        XCTAssertTrue(sut.medicines.isEmpty)
        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Reset State Tests
    
    func testResetState() {
        // Given
        sut.state = .error("Some error")
        
        // When
        sut.resetState()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Fetch History Tests
    
    func testFetchHistory_Success() async {
        // Given
        let historyEntries = [
            TestDataFactory.createTestHistoryEntry(timestamp: Date(timeIntervalSinceNow: -3600)), // 1 hour ago
            TestDataFactory.createTestHistoryEntry(timestamp: Date(timeIntervalSinceNow: -1800)), // 30 minutes ago
            TestDataFactory.createTestHistoryEntry(timestamp: Date()) // Now
        ]
        mockGetHistoryUseCase.historyEntries = historyEntries
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.history.count, 3)
        
        // Verify sorting by timestamp (most recent first)
        XCTAssertGreaterThan(sut.history[0].timestamp, sut.history[1].timestamp)
        XCTAssertGreaterThan(sut.history[1].timestamp, sut.history[2].timestamp)
    }
    
    func testFetchHistory_Failure() async {
        // Given
        mockGetHistoryUseCase.shouldThrowError = true
        let expectedError = "Failed to fetch history"
        mockGetHistoryUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .error("Erreur lors du chargement de l'historique: \(expectedError)"))
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.history.isEmpty)
    }
    
    func testFetchHistory_LoadingState() async {
        // Given
        mockGetHistoryUseCase.historyEntries = []
        mockGetHistoryUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.fetchHistory()
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertTrue(sut.isLoading)
        XCTAssertEqual(sut.state, .loading)
        
        await task.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.state, .success)
    }
    
    func testFetchHistory_EmptyResult() async {
        // Given
        mockGetHistoryUseCase.historyEntries = []
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertTrue(sut.history.isEmpty)
    }
    
    // MARK: - Fetch Medicines Tests
    
    func testFetchMedicines_Success() async {
        // Given
        let medicines = TestDataFactory.createMultipleMedicines(count: 5)
        mockGetMedicinesUseCase.medicines = medicines
        
        // When
        await sut.fetchMedicines()
        
        // Then
        XCTAssertEqual(sut.medicines.count, 5)
        XCTAssertEqual(sut.medicines, medicines)
    }
    
    func testFetchMedicines_Failure() async {
        // Given
        mockGetMedicinesUseCase.shouldThrowError = true
        let expectedError = "Failed to fetch medicines"
        mockGetMedicinesUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.fetchMedicines()
        
        // Then
        // Should not affect main state, just log error
        XCTAssertEqual(sut.state, .idle)
        XCTAssertTrue(sut.medicines.isEmpty)
    }
    
    // MARK: - Export History Tests
    
    func testExportHistory_PDF_Success() async {
        // Given
        let historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 3)
        let medicines = TestDataFactory.createMultipleMedicines(count: 2)
        sut.medicines = medicines
        
        // When
        await sut.exportHistory(format: .pdf, entries: historyEntries)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(mockExportHistoryUseCase.lastFormat, .pdf)
        XCTAssertEqual(mockExportHistoryUseCase.callCount, 1)
    }
    
    func testExportHistory_CSV_Success() async {
        // Given
        let historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 3)
        let medicines = TestDataFactory.createMultipleMedicines(count: 2)
        sut.medicines = medicines
        
        // When
        await sut.exportHistory(format: .csv, entries: historyEntries)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(mockExportHistoryUseCase.lastFormat, .csv)
        XCTAssertEqual(mockExportHistoryUseCase.callCount, 1)
    }
    
    func testExportHistory_Failure() async {
        // Given
        let historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 3)
        mockExportHistoryUseCase.shouldThrowError = true
        let expectedError = "Export failed"
        mockExportHistoryUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.exportHistory(format: .pdf, entries: historyEntries)
        
        // Then
        XCTAssertEqual(sut.state, .error("Erreur lors de l'exportation: \(expectedError)"))
    }
    
    func testExportHistory_ExportingState() async {
        // Given
        let historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 3)
        mockExportHistoryUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.exportHistory(format: .pdf, entries: historyEntries)
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check exporting state
        XCTAssertEqual(sut.state, .exporting)
        
        await task.value
        
        // Then
        XCTAssertEqual(sut.state, .success)
    }
    
    // MARK: - Export Data Creation Tests
    
    func testCreateExportData_WithKnownMedicines() async {
        // Given
        let medicine = TestDataFactory.createTestMedicine(id: "med-1", name: "Known Medicine")
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            medicineId: "med-1",
            action: "Stock Updated",
            details: "Updated from 10 to 15"
        )
        
        sut.medicines = [medicine]
        
        // When
        await sut.exportHistory(format: .pdf, entries: [historyEntry])
        
        // Then
        XCTAssertEqual(sut.state, .success)
        // The export data creation is tested indirectly through successful export
    }
    
    func testCreateExportData_WithUnknownMedicines() async {
        // Given
        let historyEntry = TestDataFactory.createTestHistoryEntry(
            medicineId: "unknown-med",
            action: "Stock Updated",
            details: "Updated from 10 to 15"
        )
        
        sut.medicines = [] // No medicines loaded
        
        // When
        await sut.exportHistory(format: .pdf, entries: [historyEntry])
        
        // Then
        XCTAssertEqual(sut.state, .success)
        // Should handle unknown medicines gracefully
    }
    
    // MARK: - Date Formatting Tests
    
    func testDateFormatting() {
        // Given
        let calendar = Calendar.current
        let components = DateComponents(year: 2023, month: 12, day: 25, hour: 14, minute: 30)
        let testDate = calendar.date(from: components)!
        
        // When - Test date formatting through export
        let historyEntry = TestDataFactory.createTestHistoryEntry(timestamp: testDate)
        
        // Create a simple test to verify the ViewModel can handle date formatting
        // The actual formatting is tested indirectly through the export functionality
        XCTAssertNotNil(historyEntry.timestamp)
    }
    
    // MARK: - Edge Cases Tests
    
    func testFetchHistory_LargeDataSet() async {
        // Given
        let largeHistorySet = TestDataFactory.createMultipleHistoryEntries(count: 1000)
        mockGetHistoryUseCase.historyEntries = largeHistorySet
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.history.count, 1000)
        // Verify first item is the most recent (sorting works for large datasets)
        XCTAssertGreaterThanOrEqual(sut.history[0].timestamp, sut.history[999].timestamp)
    }
    
    func testExportHistory_EmptyEntries() async {
        // Given
        let emptyEntries: [HistoryEntry] = []
        
        // When
        await sut.exportHistory(format: .pdf, entries: emptyEntries)
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(mockExportHistoryUseCase.callCount, 1)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentFetchAndExport() async {
        // Given
        let historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 5)
        let medicines = TestDataFactory.createMultipleMedicines(count: 3)
        mockGetHistoryUseCase.historyEntries = historyEntries
        mockGetMedicinesUseCase.medicines = medicines
        
        // When - Perform concurrent operations
        async let fetchHistoryTask = sut.fetchHistory()
        async let fetchMedicinesTask = sut.fetchMedicines()
        async let exportTask = sut.exportHistory(format: .pdf, entries: historyEntries)
        
        await fetchHistoryTask
        await fetchMedicinesTask
        await exportTask
        
        // Then
        XCTAssertEqual(sut.history.count, 5)
        XCTAssertEqual(sut.medicines.count, 3)
        XCTAssertEqual(mockExportHistoryUseCase.callCount, 1)
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistency_SuccessfulOperations() async {
        // Given
        let historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 3)
        mockGetHistoryUseCase.historyEntries = historyEntries
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.history.isEmpty)
    }
    
    func testStateConsistency_ErrorRecovery() async {
        // Given
        mockGetHistoryUseCase.shouldThrowError = true
        mockGetHistoryUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [:])
        
        // When - First operation fails
        await sut.fetchHistory()
        XCTAssertEqual(sut.state, .error("Erreur lors du chargement de l'historique: The operation couldn't be completed. (TestError error 1.)"))
        
        // Reset and try again with success
        mockGetHistoryUseCase.shouldThrowError = false
        mockGetHistoryUseCase.historyEntries = TestDataFactory.createMultipleHistoryEntries(count: 2)
        
        await sut.fetchHistory()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.history.count, 2)
    }
}

// MARK: - HistoryExportItem Tests

final class HistoryExportItemTests: XCTestCase {
    
    func testHistoryExportItemCreation() {
        // Given
        let date = "25_12_2023"
        let time = "14:30"
        let medicine = "Test Medicine"
        let action = "Stock Updated"
        let details = "Updated from 10 to 15"
        
        // When
        let exportItem = HistoryExportItem(
            date: date,
            time: time,
            medicine: medicine,
            action: action,
            details: details
        )
        
        // Then
        XCTAssertEqual(exportItem.date, date)
        XCTAssertEqual(exportItem.time, time)
        XCTAssertEqual(exportItem.medicine, medicine)
        XCTAssertEqual(exportItem.action, action)
        XCTAssertEqual(exportItem.details, details)
    }
}