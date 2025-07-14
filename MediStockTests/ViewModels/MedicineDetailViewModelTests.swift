import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class MedicineDetailViewModelTests: XCTestCase, Sendable {
    
    var sut: MedicineDetailViewModel!
    var testMedicine: Medicine!
    var mockGetMedicineUseCase: MockGetMedicineUseCase!
    var mockUpdateMedicineStockUseCase: MockUpdateMedicineStockUseCase!
    var mockDeleteMedicineUseCase: MockDeleteMedicineUseCase!
    var mockGetHistoryForMedicineUseCase: MockGetHistoryForMedicineUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        testMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            description: "Test Description",
            dosage: "500mg",
            currentQuantity: 25
        )
        
        mockGetMedicineUseCase = MockGetMedicineUseCase()
        mockUpdateMedicineStockUseCase = MockUpdateMedicineStockUseCase()
        mockDeleteMedicineUseCase = MockDeleteMedicineUseCase()
        mockGetHistoryForMedicineUseCase = MockGetHistoryForMedicineUseCase()
        
        sut = MedicineDetailViewModel(
            medicine: testMedicine,
            getMedicineUseCase: mockGetMedicineUseCase,
            updateMedicineStockUseCase: mockUpdateMedicineStockUseCase,
            deleteMedicineUseCase: mockDeleteMedicineUseCase,
            getHistoryUseCase: mockGetHistoryForMedicineUseCase
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        testMedicine = nil
        mockGetMedicineUseCase = nil
        mockUpdateMedicineStockUseCase = nil
        mockDeleteMedicineUseCase = nil
        mockGetHistoryForMedicineUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.medicine.id, testMedicine.id)
        XCTAssertEqual(sut.medicine.name, "Test Medicine")
        XCTAssertEqual(sut.medicine.currentQuantity, 25)
        XCTAssertEqual(sut.history.count, 0)
        XCTAssertEqual(sut.state, .idle)
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertNil(sut.aisleName) // Current implementation returns nil
    }
    
    // MARK: - Published Properties Tests
    
    func testMedicinePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Medicine change through refresh")
        
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            name: "Updated Medicine",
            currentQuantity: 50
        )
        mockGetMedicineUseCase.medicine = updatedMedicine
        
        sut.$medicine
            .dropFirst()
            .sink { medicine in
                if medicine.name == "Updated Medicine" && medicine.currentQuantity == 50 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.refreshMedicine()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testHistoryPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "History change through fetch")
        
        let testHistory = [
            TestHelpers.createTestHistoryEntry(medicineId: "test-medicine-1", action: "Stock Updated"),
            TestHelpers.createTestHistoryEntry(medicineId: "test-medicine-1", action: "Medicine Added")
        ]
        mockGetHistoryForMedicineUseCase.historyEntries = testHistory
        
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
        let expectation = XCTestExpectation(description: "State change through refresh")
        
        mockGetMedicineUseCase.medicine = testMedicine
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.refreshMedicine()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testIsLoadingHistoryPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Loading history state change")
        expectation.expectedFulfillmentCount = 2 // true then false
        
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        sut.$isLoadingHistory
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
        // Given - First trigger a state change
        mockGetMedicineUseCase.shouldThrowError = true
        mockGetMedicineUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        await sut.refreshMedicine()
        
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
    
    // MARK: - Refresh Medicine Tests
    
    func testRefreshMedicine_Success() async {
        // Given
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            name: "Updated Medicine",
            description: "Updated Description",
            currentQuantity: 75
        )
        mockGetMedicineUseCase.medicine = updatedMedicine
        
        // When
        await sut.refreshMedicine()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine.name, "Updated Medicine")
        XCTAssertEqual(sut.medicine.description, "Updated Description")
        XCTAssertEqual(sut.medicine.currentQuantity, 75)
        XCTAssertEqual(mockGetMedicineUseCase.lastId, "test-medicine-1")
    }
    
    func testRefreshMedicine_WithError_ShowsError() async {
        // Given
        mockGetMedicineUseCase.shouldThrowError = true
        mockGetMedicineUseCase.errorToThrow = NSError(
            domain: "MedicineError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Medicine not found"]
        )
        
        // When
        await sut.refreshMedicine()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Medicine not found"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testRefreshMedicine_LoadingStates() async {
        // Given
        mockGetMedicineUseCase.medicine = testMedicine
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then success
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.refreshMedicine()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .success)
    }
    
    // MARK: - Update Stock Tests
    
    func testUpdateStock_Success() async {
        // Given
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 30
        )
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        // When
        await sut.updateStock(newQuantity: 30, comment: "Stock replenishment")
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine.currentQuantity, 30)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.medicineId, "test-medicine-1")
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.newQuantity, 30)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.comment, "Stock replenishment")
        
        // Verify history was fetched
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.callCount, 1)
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.lastMedicineId, "test-medicine-1")
    }
    
    func testUpdateStock_WithError_ShowsError() async {
        // Given
        mockUpdateMedicineStockUseCase.shouldThrowError = true
        mockUpdateMedicineStockUseCase.errorToThrow = NSError(
            domain: "StockError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Insufficient permissions"]
        )
        
        // When
        await sut.updateStock(newQuantity: 30, comment: "Test update")
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Insufficient permissions"))
        } else {
            XCTFail("Expected error state")
        }
        
        // Medicine should remain unchanged
        XCTAssertEqual(sut.medicine.currentQuantity, 25) // Original quantity
    }
    
    func testUpdateStock_RefreshesHistoryAfterSuccess() async {
        // Given
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            currentQuantity: 40
        )
        let historyEntries = [
            TestHelpers.createTestHistoryEntry(
                medicineId: "test-medicine-1",
                action: "Stock Updated",
                details: "Quantity changed to 40"
            )
        ]
        
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        mockGetHistoryForMedicineUseCase.historyEntries = historyEntries
        
        // When
        await sut.updateStock(newQuantity: 40, comment: "Restock")
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine.currentQuantity, 40)
        XCTAssertEqual(sut.history.count, 1)
        XCTAssertEqual(sut.history[0].action, "Stock Updated")
        XCTAssertEqual(sut.history[0].details, "Quantity changed to 40")
    }
    
    func testUpdateStock_WithZeroQuantity() async {
        // Given
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            currentQuantity: 0
        )
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        // When
        await sut.updateStock(newQuantity: 0, comment: "Out of stock")
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine.currentQuantity, 0)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.newQuantity, 0)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.comment, "Out of stock")
    }
    
    // MARK: - Delete Medicine Tests
    
    func testDeleteMedicine_Success() async {
        // When
        await sut.deleteMedicine()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertTrue(mockDeleteMedicineUseCase.deletedMedicineIds.contains("test-medicine-1"))
    }
    
    func testDeleteMedicine_WithError_ShowsError() async {
        // Given
        mockDeleteMedicineUseCase.shouldThrowError = true
        mockDeleteMedicineUseCase.errorToThrow = NSError(
            domain: "DeleteError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Cannot delete medicine with pending orders"]
        )
        
        // When
        await sut.deleteMedicine()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Cannot delete medicine with pending orders"))
        } else {
            XCTFail("Expected error state")
        }
        
        // Verify medicine was not deleted
        XCTAssertFalse(mockDeleteMedicineUseCase.deletedMedicineIds.contains("test-medicine-1"))
    }
    
    func testDeleteMedicine_LoadingStates() async {
        // Given
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then success
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.deleteMedicine()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .success)
    }
    
    // MARK: - Fetch History Tests
    
    func testFetchHistory_Success() async {
        // Given
        let testHistory = [
            TestHelpers.createTestHistoryEntry(
                id: "entry1",
                medicineId: "test-medicine-1",
                action: "Medicine Added",
                details: "Initial creation"
            ),
            TestHelpers.createTestHistoryEntry(
                id: "entry2",
                medicineId: "test-medicine-1",
                action: "Stock Updated",
                details: "Quantity changed from 20 to 25"
            )
        ]
        mockGetHistoryForMedicineUseCase.historyEntries = testHistory
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertEqual(sut.history.count, 2)
        XCTAssertEqual(sut.history[0].action, "Medicine Added")
        XCTAssertEqual(sut.history[1].action, "Stock Updated")
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.callCount, 1)
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.lastMedicineId, "test-medicine-1")
    }
    
    func testFetchHistory_WithError_ClearsHistory() async {
        // Given
        mockGetHistoryForMedicineUseCase.shouldThrowError = true
        mockGetHistoryForMedicineUseCase.errorToThrow = NSError(
            domain: "HistoryError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load history"]
        )
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertEqual(sut.history.count, 0)
        // Note: The state should remain unchanged (doesn't affect main state)
    }
    
    func testFetchHistory_LoadingStates() async {
        // Given
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        let loadingExpectation = XCTestExpectation(description: "Loading history state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // true then false
        
        sut.$isLoadingHistory
            .dropFirst() // Skip initial false
            .sink { _ in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.fetchHistory()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertFalse(sut.isLoadingHistory)
    }
    
    func testFetchHistory_EmptyResult() async {
        // Given
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertEqual(sut.history.count, 0)
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.callCount, 1)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow_RefreshUpdateAndFetchHistory() async {
        // Given
        let refreshedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            name: "Refreshed Medicine",
            currentQuantity: 25
        )
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            name: "Refreshed Medicine",
            currentQuantity: 35
        )
        let historyEntries = [
            TestHelpers.createTestHistoryEntry(
                medicineId: "test-medicine-1",
                action: "Stock Updated",
                details: "Updated to 35"
            )
        ]
        
        mockGetMedicineUseCase.medicine = refreshedMedicine
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        mockGetHistoryForMedicineUseCase.historyEntries = historyEntries
        
        // When - Refresh medicine first
        await sut.refreshMedicine()
        
        // Then - Verify refresh
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine.name, "Refreshed Medicine")
        
        // When - Update stock
        await sut.updateStock(newQuantity: 35, comment: "Stock increase")
        
        // Then - Verify update and history fetch
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.medicine.currentQuantity, 35)
        XCTAssertEqual(sut.history.count, 1)
        XCTAssertEqual(sut.history[0].action, "Stock Updated")
        
        // Verify all use cases were called
        XCTAssertEqual(mockGetMedicineUseCase.lastId, "test-medicine-1")
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.newQuantity, 35)
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.lastMedicineId, "test-medicine-1")
    }
    
    func testStateConsistency_MultipleOperations() async {
        // Given
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            currentQuantity: 50
        )
        mockGetMedicineUseCase.medicine = updatedMedicine
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        // When - Perform multiple operations
        await sut.refreshMedicine()
        XCTAssertEqual(sut.state, .success)
        
        await sut.updateStock(newQuantity: 50, comment: "Update")
        XCTAssertEqual(sut.state, .success)
        
        await sut.fetchHistory()
        XCTAssertEqual(sut.state, .success) // Should remain success
        
        // Then - State should be consistent
        XCTAssertEqual(sut.state, .success)
        XCTAssertFalse(sut.isLoadingHistory)
    }
    
    func testConcurrentOperations() async {
        // Given
        let updatedMedicine = TestHelpers.createTestMedicine(
            id: "test-medicine-1",
            currentQuantity: 60
        )
        mockGetMedicineUseCase.medicine = updatedMedicine
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        // When - Start operations concurrently
        async let refreshTask: () = sut.refreshMedicine()
        async let historyTask: () = sut.fetchHistory()
        
        // Wait for both to complete
        await refreshTask
        await historyTask
        
        // Then - Both should succeed without conflicts
        XCTAssertEqual(sut.state, .success)
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertEqual(sut.medicine.currentQuantity, 60)
    }
    
    // MARK: - Edge Cases Tests
    
    func testMedicineWithCriticalStock() async {
        // Given
        let criticalMedicine = TestHelpers.createTestMedicine(
            id: "critical-med",
            name: "Critical Medicine",
            currentQuantity: 2,
            criticalThreshold: 5
        )
        
        sut = MedicineDetailViewModel(
            medicine: criticalMedicine,
            getMedicineUseCase: mockGetMedicineUseCase,
            updateMedicineStockUseCase: mockUpdateMedicineStockUseCase,
            deleteMedicineUseCase: mockDeleteMedicineUseCase,
            getHistoryUseCase: mockGetHistoryForMedicineUseCase
        )
        
        // Then
        XCTAssertEqual(sut.medicine.currentQuantity, 2)
        XCTAssertEqual(sut.medicine.criticalThreshold, 5)
        XCTAssertTrue(sut.medicine.currentQuantity <= sut.medicine.criticalThreshold)
    }
    
    func testMedicineWithEmptyId() async {
        // Given
        let emptyIdMedicine = TestHelpers.createTestMedicine(
            id: "",
            name: "No ID Medicine"
        )
        
        mockGetMedicineUseCase.shouldThrowError = true
        mockGetMedicineUseCase.errorToThrow = NSError(
            domain: "MedicineError",
            code: 404,
            userInfo: [NSLocalizedDescriptionKey: "Medicine not found"]
        )
        
        sut = MedicineDetailViewModel(
            medicine: emptyIdMedicine,
            getMedicineUseCase: mockGetMedicineUseCase,
            updateMedicineStockUseCase: mockUpdateMedicineStockUseCase,
            deleteMedicineUseCase: mockDeleteMedicineUseCase,
            getHistoryUseCase: mockGetHistoryForMedicineUseCase
        )
        
        // When
        await sut.refreshMedicine()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Medicine not found"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testLargeHistoryHandling() async {
        // Given
        let largeHistory = (1...100).map { index in
            TestHelpers.createTestHistoryEntry(
                id: "entry\(index)",
                medicineId: "test-medicine-1",
                action: "Action \(index)",
                details: "Details for action \(index)"
            )
        }
        mockGetHistoryForMedicineUseCase.historyEntries = largeHistory
        
        // When
        await sut.fetchHistory()
        
        // Then
        XCTAssertFalse(sut.isLoadingHistory)
        XCTAssertEqual(sut.history.count, 100)
        XCTAssertEqual(sut.history[0].action, "Action 1")
        XCTAssertEqual(sut.history[99].action, "Action 100")
    }
}
