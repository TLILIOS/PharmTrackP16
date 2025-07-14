import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class AdjustStockViewModelTests: XCTestCase, Sendable {
    
    var sut: AdjustStockViewModel!
    var mockGetMedicineUseCase: MockGetMedicineUseCase!
    var mockAdjustStockUseCase: MockAdjustStockUseCase!
    var cancellables: Set<AnyCancellable>!
    var testMedicine: Medicine!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        testMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 50,
            maxQuantity: 100
        )
        
        mockGetMedicineUseCase = MockGetMedicineUseCase()
        mockAdjustStockUseCase = MockAdjustStockUseCase()
        
        sut = AdjustStockViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            adjustStockUseCase: mockAdjustStockUseCase,
            medicine: testMedicine
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockGetMedicineUseCase = nil
        mockAdjustStockUseCase = nil
        testMedicine = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.medicine.id, "test-medicine-1")
        XCTAssertEqual(sut.medicine.name, "Test Medicine")
        XCTAssertEqual(sut.medicine.currentQuantity, 50)
        XCTAssertEqual(sut.adjustmentQuantity, 0)
        XCTAssertEqual(sut.adjustmentReason, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showingSuccessMessage)
    }
    
    func testInitialization_WithDifferentMedicine() {
        // Given
        let differentMedicine = TestDataFactory.createTestMedicine(
            id: "different-med",
            name: "Different Medicine",
            currentQuantity: 25
        )
        
        // When
        let differentSut = AdjustStockViewModel(
            getMedicineUseCase: mockGetMedicineUseCase,
            adjustStockUseCase: mockAdjustStockUseCase,
            medicine: differentMedicine
        )
        
        // Then
        XCTAssertEqual(differentSut.medicine.id, "different-med")
        XCTAssertEqual(differentSut.medicine.name, "Different Medicine")
        XCTAssertEqual(differentSut.medicine.currentQuantity, 25)
    }
    
    // MARK: - Published Properties Tests
    
    func testMedicinePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Medicine change")
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Updated Medicine",
            currentQuantity: 75
        )
        
        sut.$medicine
            .dropFirst()
            .sink { medicine in
                if medicine.name == "Updated Medicine" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.medicine = updatedMedicine
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testAdjustmentQuantityPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Adjustment quantity change")
        
        sut.$adjustmentQuantity
            .dropFirst()
            .sink { quantity in
                if quantity == 10 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.adjustmentQuantity = 10
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testAdjustmentReasonPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Adjustment reason change")
        
        sut.$adjustmentReason
            .dropFirst()
            .sink { reason in
                if reason == "Stock correction" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.adjustmentReason = "Stock correction"
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testIsLoadingPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Loading state changes")
        expectation.expectedFulfillmentCount = 2 // true then false
        
        sut.adjustmentQuantity = 5
        sut.adjustmentReason = "Test adjustment"
        
        mockGetMedicineUseCase.returnMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 55
        )
        
        sut.$isLoading
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.adjustStock()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testErrorMessagePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Error message change")
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Try to adjust with empty reason
        await sut.adjustStock()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testShowingSuccessMessagePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Success message change")
        
        sut.adjustmentQuantity = 5
        sut.adjustmentReason = "Test adjustment"
        
        mockGetMedicineUseCase.returnMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 55
        )
        
        sut.$showingSuccessMessage
            .dropFirst()
            .sink { showingSuccess in
                if showingSuccess {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await sut.adjustStock()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Adjust Stock Tests - Success Cases
    
    func testAdjustStock_PositiveAdjustment_Success() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = "Restocking"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 60
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        
        // Form should be reset
        XCTAssertEqual(sut.adjustmentQuantity, 0)
        XCTAssertEqual(sut.adjustmentReason, "")
        
        // Medicine should be updated
        XCTAssertEqual(sut.medicine.currentQuantity, 60)
        
        // Verify use case calls
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 1)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].medicineId, "test-medicine-1")
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].adjustment, 10)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].reason, "Restocking")
        
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds.count, 1)
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds[0], "test-medicine-1")
    }
    
    func testAdjustStock_NegativeAdjustment_Success() async {
        // Given
        sut.adjustmentQuantity = -15
        sut.adjustmentReason = "Damaged goods"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 35
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        
        // Form should be reset
        XCTAssertEqual(sut.adjustmentQuantity, 0)
        XCTAssertEqual(sut.adjustmentReason, "")
        
        // Medicine should be updated
        XCTAssertEqual(sut.medicine.currentQuantity, 35)
        
        // Verify use case calls
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 1)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].adjustment, -15)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].reason, "Damaged goods")
    }
    
    func testAdjustStock_LargePositiveAdjustment_Success() async {
        // Given
        sut.adjustmentQuantity = 500
        sut.adjustmentReason = "Bulk restocking"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 550
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(sut.medicine.currentQuantity, 550)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].adjustment, 500)
    }
    
    func testAdjustStock_WithDetailedReason_Success() async {
        // Given
        sut.adjustmentQuantity = 25
        sut.adjustmentReason = "Inventory audit adjustment - found discrepancy in warehouse count"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 75
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].reason, "Inventory audit adjustment - found discrepancy in warehouse count")
    }
    
    // MARK: - Adjust Stock Tests - Validation Errors
    
    func testAdjustStock_WithZeroQuantity_ShowsValidationError() async {
        // Given
        sut.adjustmentQuantity = 0
        sut.adjustmentReason = "Some reason"
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "La quantité d'ajustement ne peut pas être zéro")
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Form should not be reset
        XCTAssertEqual(sut.adjustmentQuantity, 0)
        XCTAssertEqual(sut.adjustmentReason, "Some reason")
        
        // Use cases should not be called
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 0)
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds.count, 0)
    }
    
    func testAdjustStock_WithEmptyReason_ShowsValidationError() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = ""
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Veuillez saisir une raison pour l'ajustement")
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Form should not be reset
        XCTAssertEqual(sut.adjustmentQuantity, 10)
        XCTAssertEqual(sut.adjustmentReason, "")
        
        // Use cases should not be called
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 0)
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds.count, 0)
    }
    
    func testAdjustStock_WithWhitespaceOnlyReason_ShowsValidationError() async {
        // Given
        sut.adjustmentQuantity = 5
        sut.adjustmentReason = "   "
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Erreur lors de l'ajustement du stock: Medicine not found")
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 1)
    }
    
    // MARK: - Adjust Stock Tests - Service Errors
    
    func testAdjustStock_AdjustStockUseCaseError_ShowsError() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = "Test adjustment"
        
        mockAdjustStockUseCase.shouldThrowError = true
        mockAdjustStockUseCase.errorToThrow = NSError(
            domain: "AdjustStockError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to adjust stock"]
        )
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to adjust stock"))
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Form should not be reset on error
        XCTAssertEqual(sut.adjustmentQuantity, 10)
        XCTAssertEqual(sut.adjustmentReason, "Test adjustment")
        
        // Medicine should not be updated
        XCTAssertEqual(sut.medicine.currentQuantity, 50) // Original value
        
        // Adjust stock use case should be called, but get medicine should not
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 1)
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds.count, 0)
    }
    
    func testAdjustStock_GetMedicineUseCaseError_ShowsError() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = "Test adjustment"
        
        mockGetMedicineUseCase.shouldThrowError = true
        mockGetMedicineUseCase.errorToThrow = NSError(
            domain: "GetMedicineError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch updated medicine"]
        )
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to fetch updated medicine"))
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Form should not be reset on error
        XCTAssertEqual(sut.adjustmentQuantity, 10)
        XCTAssertEqual(sut.adjustmentReason, "Test adjustment")
        
        // Both use cases should be called
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 1)
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds.count, 1)
    }
    
    // MARK: - Message Handling Tests
    
    func testDismissSuccessMessage() {
        // Given
        sut.showingSuccessMessage = true
        
        // When
        sut.dismissSuccessMessage()
        
        // Then
        XCTAssertFalse(sut.showingSuccessMessage)
    }
    
    func testDismissErrorMessage() {
        // Given
        sut.errorMessage = "Some error"
        
        // When
        sut.dismissErrorMessage()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    func testDismissErrorMessage_ClearsValidationErrors() {
        // Given
        sut.errorMessage = "La quantité d'ajustement ne peut pas être zéro"
        
        // When
        sut.dismissErrorMessage()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Loading State Tests
    
    func testAdjustStock_LoadingStateTransitions() async {
        // Given
        sut.adjustmentQuantity = 5
        sut.adjustmentReason = "Test adjustment"
        
        mockGetMedicineUseCase.returnMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 55
        )
        
        // Initially not loading
        XCTAssertFalse(sut.isLoading)
        
        // When
        let adjustTask = Task { await sut.adjustStock() }
        
        // Then - Should complete and not be loading
        await adjustTask.value
        XCTAssertFalse(sut.isLoading)
    }
    
    func testAdjustStock_LoadingStateDuringError() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = "Test adjustment"
        
        mockAdjustStockUseCase.shouldThrowError = true
        mockAdjustStockUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        // When
        await sut.adjustStock()
        
        // Then - Should not be loading after error
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteAdjustmentWorkflow() async {
        // Given
        let originalQuantity = sut.medicine.currentQuantity
        sut.adjustmentQuantity = 20
        sut.adjustmentReason = "Monthly inventory adjustment"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: originalQuantity + 20
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When - Perform adjustment
        await sut.adjustStock()
        
        // Then - Should succeed
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.medicine.currentQuantity, originalQuantity + 20)
        
        // Form should be reset
        XCTAssertEqual(sut.adjustmentQuantity, 0)
        XCTAssertEqual(sut.adjustmentReason, "")
        
        // When - Dismiss success message
        sut.dismissSuccessMessage()
        
        // Then
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Verify all interactions
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 1)
        XCTAssertEqual(mockGetMedicineUseCase.requestedMedicineIds.count, 1)
    }
    
    func testErrorRecoveryWorkflow() async {
        // Given
        sut.adjustmentQuantity = 15
        sut.adjustmentReason = "Test adjustment"
        
        // Set up error for first attempt
        mockAdjustStockUseCase.shouldThrowError = true
        mockAdjustStockUseCase.errorToThrow = NSError(domain: "NetworkError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"])
        
        // When - First attempt fails
        await sut.adjustStock()
        
        // Then - Should show error
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Network connection failed"))
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertEqual(sut.adjustmentQuantity, 15) // Form not reset on error
        XCTAssertEqual(sut.adjustmentReason, "Test adjustment")
        
        // When - Dismiss error and retry
        sut.dismissErrorMessage()
        XCTAssertNil(sut.errorMessage)
        
        // Fix the error
        mockAdjustStockUseCase.shouldThrowError = false
        mockGetMedicineUseCase.returnMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 65
        )
        
        await sut.adjustStock()
        
        // Then - Should succeed
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(sut.medicine.currentQuantity, 65)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 2) // Two attempts total
    }
    
    // MARK: - Edge Cases Tests
    
    func testAdjustStock_WithNegativeStockResult() async {
        // Given
        sut.adjustmentQuantity = -60 // More than current stock
        sut.adjustmentReason = "Major loss"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: -10 // Negative stock allowed
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then - Should still work (business logic allows negative stock)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.medicine.currentQuantity, -10)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].adjustment, -60)
    }
    
    func testAdjustStock_WithVeryLongReason() async {
        // Given
        let longReason = String(repeating: "This is a very detailed reason for the stock adjustment. ", count: 100)
        sut.adjustmentQuantity = 5
        sut.adjustmentReason = longReason
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 55
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then - Should still work
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].reason, longReason)
    }
    
    func testAdjustStock_WithSpecialCharactersInReason() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = "Correction d'inventaire - éléments endommagés à 50% & rejetés"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 60
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When
        await sut.adjustStock()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].reason, "Correction d'inventaire - éléments endommagés à 50% & rejetés")
    }
    
    func testMultipleConsecutiveAdjustments() async {
        // Given
        sut.adjustmentQuantity = 10
        sut.adjustmentReason = "First adjustment"
        
        let firstUpdatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 60
        )
        mockGetMedicineUseCase.returnMedicine = firstUpdatedMedicine
        
        // When - First adjustment
        await sut.adjustStock()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(sut.medicine.currentQuantity, 60)
        XCTAssertEqual(sut.adjustmentQuantity, 0) // Form reset
        XCTAssertEqual(sut.adjustmentReason, "")
        
        // When - Dismiss and make second adjustment
        sut.dismissSuccessMessage()
        sut.adjustmentQuantity = -5
        sut.adjustmentReason = "Second adjustment"
        
        let secondUpdatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 55
        )
        mockGetMedicineUseCase.returnMedicine = secondUpdatedMedicine
        
        await sut.adjustStock()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(sut.medicine.currentQuantity, 55)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls.count, 2)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[0].adjustment, 10)
        XCTAssertEqual(mockAdjustStockUseCase.adjustmentCalls[1].adjustment, -5)
    }
    
    func testStateConsistency_MultipleOperations() async {
        // Given
        sut.adjustmentQuantity = 25
        sut.adjustmentReason = "Bulk adjustment"
        
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "test-medicine-1",
            name: "Test Medicine",
            currentQuantity: 75
        )
        mockGetMedicineUseCase.returnMedicine = updatedMedicine
        
        // When - Perform adjustment
        await sut.adjustStock()
        XCTAssertTrue(sut.showingSuccessMessage)
        
        // When - Dismiss success
        sut.dismissSuccessMessage()
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // When - Set new values
        sut.adjustmentQuantity = -10
        sut.adjustmentReason = "Correction"
        
        // Then - State should be consistent
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.medicine.currentQuantity, 75)
        XCTAssertEqual(sut.adjustmentQuantity, -10)
        XCTAssertEqual(sut.adjustmentReason, "Correction")
    }
}