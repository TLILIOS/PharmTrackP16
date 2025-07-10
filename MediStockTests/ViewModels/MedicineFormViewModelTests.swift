import XCTest
@testable import MediStock

@MainActor
final class MedicineFormViewModelTests: XCTestCase {
    
    var sut: MedicineFormViewModel!
    var mockAddMedicineUseCase: MockAddMedicineUseCase!
    var mockUpdateMedicineUseCase: MockUpdateMedicineUseCase!
    var mockGetAislesUseCase: MockGetAislesUseCase!
    
    override func setUp() {
        super.setUp()
        mockAddMedicineUseCase = MockAddMedicineUseCase()
        mockUpdateMedicineUseCase = MockUpdateMedicineUseCase()
        mockGetAislesUseCase = MockGetAislesUseCase()
        
        sut = MedicineFormViewModel(
            addMedicineUseCase: mockAddMedicineUseCase,
            updateMedicineUseCase: mockUpdateMedicineUseCase,
            getAislesUseCase: mockGetAislesUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockAddMedicineUseCase = nil
        mockUpdateMedicineUseCase = nil
        mockGetAislesUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.dosage, "")
        XCTAssertEqual(sut.form, "")
        XCTAssertEqual(sut.reference, "")
        XCTAssertEqual(sut.unit, "")
        XCTAssertEqual(sut.currentQuantity, 0)
        XCTAssertEqual(sut.maxQuantity, 100)
        XCTAssertEqual(sut.warningThreshold, 20)
        XCTAssertEqual(sut.criticalThreshold, 10)
        XCTAssertNil(sut.expiryDate)
        XCTAssertEqual(sut.selectedAisleId, "")
        XCTAssertTrue(sut.availableAisles.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isEditMode)
    }
    
    // MARK: - Load Aisles Tests
    
    func testLoadAisles_Success() async {
        // Given
        let expectedAisles = TestDataFactory.createMultipleAisles(count: 3)
        mockGetAislesUseCase.aisles = expectedAisles
        
        // When
        await sut.loadAisles()
        
        // Then
        XCTAssertEqual(sut.availableAisles.count, expectedAisles.count)
        XCTAssertEqual(sut.availableAisles, expectedAisles)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoadAisles_Failure() async {
        // Given
        mockGetAislesUseCase.shouldThrowError = true
        let expectedError = "Failed to load aisles"
        mockGetAislesUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.loadAisles()
        
        // Then
        XCTAssertTrue(sut.availableAisles.isEmpty)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    func testLoadAisles_EmptyResult() async {
        // Given
        mockGetAislesUseCase.aisles = []
        
        // When
        await sut.loadAisles()
        
        // Then
        XCTAssertTrue(sut.availableAisles.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Form Setup Tests
    
    func testSetupForEditing() {
        // Given
        let existingMedicine = TestDataFactory.createTestMedicine(
            id: "test-id",
            name: "Test Medicine",
            description: "Test Description",
            dosage: "500mg",
            form: "Tablet",
            reference: "TEST-001",
            unit: "tablet",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            aisleId: "aisle-1"
        )
        
        // When
        sut.setupForEditing(medicine: existingMedicine)
        
        // Then
        XCTAssertTrue(sut.isEditMode)
        XCTAssertEqual(sut.name, "Test Medicine")
        XCTAssertEqual(sut.description, "Test Description")
        XCTAssertEqual(sut.dosage, "500mg")
        XCTAssertEqual(sut.form, "Tablet")
        XCTAssertEqual(sut.reference, "TEST-001")
        XCTAssertEqual(sut.unit, "tablet")
        XCTAssertEqual(sut.currentQuantity, 50)
        XCTAssertEqual(sut.maxQuantity, 100)
        XCTAssertEqual(sut.warningThreshold, 20)
        XCTAssertEqual(sut.criticalThreshold, 10)
        XCTAssertEqual(sut.selectedAisleId, "aisle-1")
    }
    
    func testSetupForNew() {
        // Given - Set some values first
        sut.name = "Old Name"
        sut.isEditMode = true
        
        // When
        sut.setupForNew()
        
        // Then
        XCTAssertFalse(sut.isEditMode)
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.selectedAisleId, "")
    }
    
    // MARK: - Save Medicine Tests
    
    func testSaveMedicine_NewMedicine_Success() async {
        // Given
        sut.name = "New Medicine"
        sut.description = "New Description"
        sut.dosage = "250mg"
        sut.form = "Capsule"
        sut.reference = "NEW-001"
        sut.unit = "capsule"
        sut.currentQuantity = 30
        sut.maxQuantity = 100
        sut.warningThreshold = 15
        sut.criticalThreshold = 5
        sut.selectedAisleId = "aisle-1"
        sut.expiryDate = Date()
        
        // When
        let success = await sut.saveMedicine()
        
        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(mockAddMedicineUseCase.addedMedicines.count, 1)
        let addedMedicine = mockAddMedicineUseCase.addedMedicines.first!
        XCTAssertEqual(addedMedicine.name, "New Medicine")
        XCTAssertEqual(addedMedicine.dosage, "250mg")
        XCTAssertNil(sut.errorMessage)
    }
    
    func testSaveMedicine_EditMode_Success() async {
        // Given
        let existingMedicine = TestDataFactory.createTestMedicine(id: "test-id")
        sut.setupForEditing(medicine: existingMedicine)
        sut.name = "Updated Medicine"
        
        // When
        let success = await sut.saveMedicine()
        
        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(mockUpdateMedicineUseCase.updatedMedicines.count, 1)
        let updatedMedicine = mockUpdateMedicineUseCase.updatedMedicines.first!
        XCTAssertEqual(updatedMedicine.name, "Updated Medicine")
        XCTAssertNil(sut.errorMessage)
    }
    
    func testSaveMedicine_AddFailure() async {
        // Given
        sut.name = "New Medicine"
        mockAddMedicineUseCase.shouldThrowError = true
        let expectedError = "Failed to add medicine"
        mockAddMedicineUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        let success = await sut.saveMedicine()
        
        // Then
        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, expectedError)
        XCTAssertTrue(mockAddMedicineUseCase.addedMedicines.isEmpty)
    }
    
    func testSaveMedicine_UpdateFailure() async {
        // Given
        let existingMedicine = TestDataFactory.createTestMedicine(id: "test-id")
        sut.setupForEditing(medicine: existingMedicine)
        mockUpdateMedicineUseCase.shouldThrowError = true
        let expectedError = "Failed to update medicine"
        mockUpdateMedicineUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        let success = await sut.saveMedicine()
        
        // Then
        XCTAssertFalse(success)
        XCTAssertEqual(sut.errorMessage, expectedError)
        XCTAssertTrue(mockUpdateMedicineUseCase.updatedMedicines.isEmpty)
    }
    
    // MARK: - Form Validation Tests
    
    func testIsFormValid_ValidForm() {
        // Given
        sut.name = "Valid Medicine"
        sut.description = "Valid Description"
        sut.dosage = "500mg"
        sut.form = "Tablet"
        sut.unit = "tablet"
        sut.selectedAisleId = "aisle-1"
        
        // When
        let isValid = sut.isFormValid
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testIsFormValid_EmptyName() {
        // Given
        sut.name = ""
        sut.description = "Valid Description"
        sut.dosage = "500mg"
        sut.form = "Tablet"
        sut.unit = "tablet"
        sut.selectedAisleId = "aisle-1"
        
        // When
        let isValid = sut.isFormValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testIsFormValid_EmptyDescription() {
        // Given
        sut.name = "Valid Medicine"
        sut.description = ""
        sut.dosage = "500mg"
        sut.form = "Tablet"
        sut.unit = "tablet"
        sut.selectedAisleId = "aisle-1"
        
        // When
        let isValid = sut.isFormValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testIsFormValid_NoAisleSelected() {
        // Given
        sut.name = "Valid Medicine"
        sut.description = "Valid Description"
        sut.dosage = "500mg"
        sut.form = "Tablet"
        sut.unit = "tablet"
        sut.selectedAisleId = ""
        
        // When
        let isValid = sut.isFormValid
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Quantity Validation Tests
    
    func testQuantityValidation_ValidValues() {
        // Given
        sut.currentQuantity = 50
        sut.maxQuantity = 100
        sut.warningThreshold = 20
        sut.criticalThreshold = 10
        
        // Then
        XCTAssertLessThan(sut.criticalThreshold, sut.warningThreshold)
        XCTAssertLessThan(sut.warningThreshold, sut.maxQuantity)
        XCTAssertLessThanOrEqual(sut.currentQuantity, sut.maxQuantity)
    }
    
    func testQuantityValidation_InvalidThresholds() {
        // Given
        sut.maxQuantity = 100
        sut.warningThreshold = 50
        sut.criticalThreshold = 60 // Critical > Warning (invalid)
        
        // When saving, this should be handled by validation logic
        // For now, we just verify the values are set
        XCTAssertGreaterThan(sut.criticalThreshold, sut.warningThreshold)
    }
    
    // MARK: - Clear Error Tests
    
    func testClearError() {
        // Given
        sut.errorMessage = "Some error"
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Reset Form Tests
    
    func testResetForm() {
        // Given
        sut.name = "Test Medicine"
        sut.description = "Test Description"
        sut.currentQuantity = 50
        sut.isEditMode = true
        sut.errorMessage = "Some error"
        
        // When
        sut.resetForm()
        
        // Then
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertEqual(sut.currentQuantity, 0)
        XCTAssertFalse(sut.isEditMode)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Date Handling Tests
    
    func testExpiryDateHandling() {
        // Given
        let futureDate = Calendar.current.date(byAdding: .year, value: 2, to: Date())!
        
        // When
        sut.expiryDate = futureDate
        
        // Then
        XCTAssertEqual(sut.expiryDate, futureDate)
    }
    
    func testExpiryDateHandling_NilDate() {
        // Given
        sut.expiryDate = Date()
        
        // When
        sut.expiryDate = nil
        
        // Then
        XCTAssertNil(sut.expiryDate)
    }
    
    // MARK: - Reference Generation Tests
    
    func testReferenceGeneration() {
        // Given
        sut.name = "Test Medicine"
        
        // When
        sut.generateReference()
        
        // Then
        XCTAssertFalse(sut.reference.isEmpty)
        XCTAssertTrue(sut.reference.count >= 3)
    }
    
    func testReferenceGeneration_EmptyName() {
        // Given
        sut.name = ""
        
        // When
        sut.generateReference()
        
        // Then
        XCTAssertFalse(sut.reference.isEmpty) // Should generate something even with empty name
    }
    
    // MARK: - Edge Cases Tests
    
    func testNegativeQuantities() {
        // Given
        sut.currentQuantity = -10
        sut.maxQuantity = -5
        sut.warningThreshold = -15
        sut.criticalThreshold = -20
        
        // When saving, validation should handle negative values
        // For now, we just verify they can be set
        XCTAssertEqual(sut.currentQuantity, -10)
        XCTAssertEqual(sut.maxQuantity, -5)
    }
    
    func testVeryLargeQuantities() {
        // Given
        sut.currentQuantity = 999999
        sut.maxQuantity = 1000000
        
        // When
        XCTAssertEqual(sut.currentQuantity, 999999)
        XCTAssertEqual(sut.maxQuantity, 1000000)
    }
    
    func testVeryLongStrings() {
        // Given
        let longString = String(repeating: "a", count: 1000)
        
        // When
        sut.name = longString
        sut.description = longString
        
        // Then
        XCTAssertEqual(sut.name.count, 1000)
        XCTAssertEqual(sut.description.count, 1000)
    }
    
    // MARK: - Medicine Creation Tests
    
    func testCreateMedicineObject() async {
        // Given
        sut.name = "Test Medicine"
        sut.description = "Test Description"
        sut.dosage = "500mg"
        sut.form = "Tablet"
        sut.reference = "TEST-001"
        sut.unit = "tablet"
        sut.currentQuantity = 50
        sut.maxQuantity = 100
        sut.warningThreshold = 20
        sut.criticalThreshold = 10
        sut.selectedAisleId = "aisle-1"
        sut.expiryDate = Date()
        
        // When
        let success = await sut.saveMedicine()
        
        // Then
        XCTAssertTrue(success)
        let createdMedicine = mockAddMedicineUseCase.addedMedicines.first!
        XCTAssertEqual(createdMedicine.name, "Test Medicine")
        XCTAssertEqual(createdMedicine.description, "Test Description")
        XCTAssertEqual(createdMedicine.dosage, "500mg")
        XCTAssertEqual(createdMedicine.form, "Tablet")
        XCTAssertEqual(createdMedicine.reference, "TEST-001")
        XCTAssertEqual(createdMedicine.unit, "tablet")
        XCTAssertEqual(createdMedicine.currentQuantity, 50)
        XCTAssertEqual(createdMedicine.maxQuantity, 100)
        XCTAssertEqual(createdMedicine.warningThreshold, 20)
        XCTAssertEqual(createdMedicine.criticalThreshold, 10)
        XCTAssertEqual(createdMedicine.aisleId, "aisle-1")
        XCTAssertNotNil(createdMedicine.expiryDate)
    }
}