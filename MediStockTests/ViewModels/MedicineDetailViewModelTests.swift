import XCTest
@testable import MediStock

@MainActor
final class MedicineDetailViewModelTests: XCTestCase {
    
    var sut: MedicineDetailViewModel!
    var mockGetMedicineUseCase: MockGetMedicineUseCase!
    var mockUpdateMedicineStockUseCase: MockUpdateMedicineStockUseCase!
    var mockGetHistoryForMedicineUseCase: MockGetHistoryForMedicineUseCase!
    
    override func setUp() {
        super.setUp()
        mockGetMedicineUseCase = MockGetMedicineUseCase()
        mockUpdateMedicineStockUseCase = MockUpdateMedicineStockUseCase()
        mockGetHistoryForMedicineUseCase = MockGetHistoryForMedicineUseCase()
        
        sut = MedicineDetailViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            updateMedicineStockUseCase: mockUpdateMedicineStockUseCase,
            getHistoryForMedicineUseCase: mockGetHistoryForMedicineUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockGetMedicineUseCase = nil
        mockUpdateMedicineStockUseCase = nil
        mockGetHistoryForMedicineUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertNil(sut.medicine)
        XCTAssertTrue(sut.history.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Load Medicine Tests
    
    func testLoadMedicine_Success() async {
        // Given
        let expectedMedicine = TestDataFactory.createTestMedicine(id: "test-medicine-1")
        mockGetMedicineUseCase.medicine = expectedMedicine
        
        // When
        await sut.loadMedicine(id: "test-medicine-1")
        
        // Then
        XCTAssertEqual(sut.medicine?.id, expectedMedicine.id)
        XCTAssertEqual(sut.medicine?.name, expectedMedicine.name)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoadMedicine_NotFound() async {
        // Given
        mockGetMedicineUseCase.medicine = nil
        
        // When
        await sut.loadMedicine(id: "non-existent-id")
        
        // Then
        XCTAssertNil(sut.medicine)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func testLoadMedicine_Failure() async {
        // Given
        mockGetMedicineUseCase.shouldThrowError = true
        let expectedError = "Failed to load medicine"
        mockGetMedicineUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.loadMedicine(id: "test-medicine-1")
        
        // Then
        XCTAssertNil(sut.medicine)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    func testLoadMedicine_LoadingState() async {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        mockGetMedicineUseCase.medicine = medicine
        mockGetMedicineUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.loadMedicine(id: "test-medicine-1")
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        
        await task.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.medicine)
    }
    
    // MARK: - Load History Tests
    
    func testLoadHistory_Success() async {
        // Given
        let medicineId = "test-medicine-1"
        let expectedHistory = [
            TestDataFactory.createTestHistoryEntry(medicineId: medicineId, action: "Added"),
            TestDataFactory.createTestHistoryEntry(medicineId: medicineId, action: "Updated Stock")
        ]
        mockGetHistoryForMedicineUseCase.historyEntries = expectedHistory
        
        // When
        await sut.loadHistory(for: medicineId)
        
        // Then
        XCTAssertEqual(sut.history.count, expectedHistory.count)
        XCTAssertEqual(mockGetHistoryForMedicineUseCase.lastMedicineId, medicineId)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoadHistory_Failure() async {
        // Given
        let medicineId = "test-medicine-1"
        mockGetHistoryForMedicineUseCase.shouldThrowError = true
        let expectedError = "Failed to load history"
        mockGetHistoryForMedicineUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.loadHistory(for: medicineId)
        
        // Then
        XCTAssertTrue(sut.history.isEmpty)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    func testLoadHistory_EmptyResult() async {
        // Given
        let medicineId = "test-medicine-1"
        mockGetHistoryForMedicineUseCase.historyEntries = []
        
        // When
        await sut.loadHistory(for: medicineId)
        
        // Then
        XCTAssertTrue(sut.history.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Update Stock Tests
    
    func testUpdateStock_Success() async {
        // Given
        let medicineId = "test-medicine-1"
        let newQuantity = 25
        let comment = "Stock updated"
        let updatedMedicine = TestDataFactory.createTestMedicine(id: medicineId, currentQuantity: newQuantity)
        mockUpdateMedicineStockUseCase.updatedMedicine = updatedMedicine
        
        // When
        await sut.updateStock(medicineId: medicineId, newQuantity: newQuantity, comment: comment)
        
        // Then
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.medicineId, medicineId)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.newQuantity, newQuantity)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.comment, comment)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testUpdateStock_Failure() async {
        // Given
        let medicineId = "test-medicine-1"
        let newQuantity = 25
        let comment = "Stock updated"
        mockUpdateMedicineStockUseCase.shouldThrowError = true
        let expectedError = "Failed to update stock"
        mockUpdateMedicineStockUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.updateStock(medicineId: medicineId, newQuantity: newQuantity, comment: comment)
        
        // Then
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    func testUpdateStock_NegativeQuantity() async {
        // Given
        let medicineId = "test-medicine-1"
        let newQuantity = -5
        let comment = "Invalid stock"
        
        // When
        await sut.updateStock(medicineId: medicineId, newQuantity: newQuantity, comment: comment)
        
        // Then
        // Should still attempt the update (validation might be in use case)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.newQuantity, newQuantity)
    }
    
    // MARK: - Refresh Data Tests
    
    func testRefreshData_Success() async {
        // Given
        let medicineId = "test-medicine-1"
        let medicine = TestDataFactory.createTestMedicine(id: medicineId)
        let history = [TestDataFactory.createTestHistoryEntry(medicineId: medicineId)]
        
        mockGetMedicineUseCase.medicine = medicine
        mockGetHistoryForMedicineUseCase.historyEntries = history
        
        // When
        await sut.refreshData(medicineId: medicineId)
        
        // Then
        XCTAssertEqual(sut.medicine?.id, medicineId)
        XCTAssertEqual(sut.history.count, 1)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testRefreshData_PartialFailure() async {
        // Given
        let medicineId = "test-medicine-1"
        let medicine = TestDataFactory.createTestMedicine(id: medicineId)
        
        mockGetMedicineUseCase.medicine = medicine
        mockGetHistoryForMedicineUseCase.shouldThrowError = true
        
        // When
        await sut.refreshData(medicineId: medicineId)
        
        // Then
        XCTAssertNotNil(sut.medicine) // Medicine should load successfully
        XCTAssertTrue(sut.history.isEmpty) // History should fail to load
        XCTAssertNotNil(sut.errorMessage) // Error from history loading
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError() {
        // Given
        sut.errorMessage = "Some error"
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - State Management Tests
    
    func testStateConsistency() async {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        mockGetMedicineUseCase.medicine = medicine
        
        // When
        await sut.loadMedicine(id: medicine.id)
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.medicine)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentOperations() async {
        // Given
        let medicineId = "test-medicine-1"
        let medicine = TestDataFactory.createTestMedicine(id: medicineId)
        let history = [TestDataFactory.createTestHistoryEntry(medicineId: medicineId)]
        
        mockGetMedicineUseCase.medicine = medicine
        mockGetHistoryForMedicineUseCase.historyEntries = history
        
        // When - Perform concurrent operations
        async let loadMedicineTask = sut.loadMedicine(id: medicineId)
        async let loadHistoryTask = sut.loadHistory(for: medicineId)
        
        await loadMedicineTask
        await loadHistoryTask
        
        // Then
        XCTAssertNotNil(sut.medicine)
        XCTAssertFalse(sut.history.isEmpty)
    }
    
    // MARK: - Data Validation Tests
    
    func testMedicineDataValidation() async {
        // Given
        let invalidMedicine = Medicine(
            id: "",
            name: "",
            description: "",
            dosage: "",
            form: "",
            reference: "",
            unit: "",
            currentQuantity: -1,
            maxQuantity: 0,
            warningThreshold: -1,
            criticalThreshold: -1,
            expiryDate: nil,
            aisleId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        mockGetMedicineUseCase.medicine = invalidMedicine
        
        // When
        await sut.loadMedicine(id: "invalid-medicine")
        
        // Then
        XCTAssertNotNil(sut.medicine) // Should still load, validation is up to use case
        XCTAssertEqual(sut.medicine?.name, "")
        XCTAssertEqual(sut.medicine?.currentQuantity, -1)
    }
    
    // MARK: - Edge Cases Tests
    
    func testEmptyMedicineId() async {
        // When
        await sut.loadMedicine(id: "")
        
        // Then
        XCTAssertNil(sut.medicine) // Should handle empty ID gracefully
    }
    
    func testVeryLongMedicineId() async {
        // Given
        let longId = String(repeating: "a", count: 1000)
        
        // When
        await sut.loadMedicine(id: longId)
        
        // Then
        // Should handle long IDs without crashing
        XCTAssertNil(sut.medicine) // Likely won't find medicine with such ID
    }
    
    // MARK: - Multiple Updates Tests
    
    func testMultipleStockUpdates() async {
        // Given
        let medicineId = "test-medicine-1"
        let updates = [(10, "First update"), (20, "Second update"), (15, "Third update")]
        
        // When
        for (quantity, comment) in updates {
            await sut.updateStock(medicineId: medicineId, newQuantity: quantity, comment: comment)
        }
        
        // Then
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.newQuantity, 15)
        XCTAssertEqual(mockUpdateMedicineStockUseCase.lastUpdateCall?.comment, "Third update")
    }
}