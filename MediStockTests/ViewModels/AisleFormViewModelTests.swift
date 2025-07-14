import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class AisleFormViewModelTests: XCTestCase, Sendable {
    
    var sut: AisleFormViewModel!
    var mockAddAisleUseCase: MockAddAisleUseCase!
    var mockUpdateAisleUseCase: MockUpdateAisleUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockAddAisleUseCase = MockAddAisleUseCase()
        mockUpdateAisleUseCase = MockUpdateAisleUseCase()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockAddAisleUseCase = nil
        mockUpdateAisleUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_AddMode() {
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: nil as Aisle?
        )
        
        // Then
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertFalse(sut.isEditing)
        XCTAssertEqual(sut.title, "Ajouter un rayon")
    }
    
    func testInitialization_EditMode() {
        // Given
        let testAisle = TestDataFactory.createTestAisle(
            id: "test-aisle",
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#007AFF"
        )
        
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        // Then
        XCTAssertEqual(sut.name, "Test Aisle")
        XCTAssertEqual(sut.description, "Test Description")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertTrue(sut.isEditing)
        XCTAssertEqual(sut.title, "Modifier le rayon")
    }
    
    func testInitialization_EditMode_WithNilDescription() {
        // Given
        let testAisle = TestDataFactory.createTestAisle(
            id: "test-aisle",
            name: "Test Aisle",
            description: nil,
            colorHex: "#007AFF"
        )
        
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        // Then
        XCTAssertEqual(sut.name, "Test Aisle")
        XCTAssertEqual(sut.description, "")
        XCTAssertTrue(sut.isEditing)
    }
    
    // MARK: - Published Properties Tests
    
    func testNamePropertyIsPublished() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        let expectation = XCTestExpectation(description: "Name change")
        
        sut.$name
            .dropFirst()
            .sink { name in
                if name == "New Name" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.name = "New Name"
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testDescriptionPropertyIsPublished() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        let expectation = XCTestExpectation(description: "Description change")
        
        sut.$description
            .dropFirst()
            .sink { description in
                if description == "New Description" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        sut.description = "New Description"
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testIsLoadingPropertyIsPublished() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "Test Aisle"
        
        let expectation = XCTestExpectation(description: "Loading state changes")
        expectation.expectedFulfillmentCount = 2 // true then false
        
        sut.$isLoading
            .dropFirst() // Skip initial false
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.save()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testErrorMessagePropertyIsPublished() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        let expectation = XCTestExpectation(description: "Error message change")
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When - Try to save with empty name to trigger validation error
        await sut.save()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testShowingSuccessMessagePropertyIsPublished() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "Test Aisle"
        
        let expectation = XCTestExpectation(description: "Success message change")
        
        sut.$showingSuccessMessage
            .dropFirst()
            .sink { showingSuccess in
                if showingSuccess {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        await sut.save()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Computed Properties Tests
    
    func testIsEditing_AddMode() {
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: nil as Aisle?
        )
        
        // Then
        XCTAssertFalse(sut.isEditing)
    }
    
    func testIsEditing_EditMode() {
        // Given
        let testAisle = TestDataFactory.createTestAisle(id: "test", name: "Test", colorHex: "#007AFF")
        
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        // Then
        XCTAssertTrue(sut.isEditing)
    }
    
    func testTitle_AddMode() {
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: nil as Aisle?
        )
        
        // Then
        XCTAssertEqual(sut.title, "Ajouter un rayon")
    }
    
    func testTitle_EditMode() {
        // Given
        let testAisle = TestDataFactory.createTestAisle(id: "test", name: "Test", colorHex: "#007AFF")
        
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        // Then
        XCTAssertEqual(sut.title, "Modifier le rayon")
    }
    
    // MARK: - Save Functionality Tests - Add Mode
    
    func testSave_AddMode_Success() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "New Aisle"
        sut.description = "New Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        
        // Form should be reset for add mode
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        
        // Verify use case was called
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, "New Aisle")
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].description, "New Description")
        
        // Update use case should not be called
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 0)
    }
    
    func testSave_AddMode_WithEmptyDescription() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "New Aisle"
        sut.description = ""
        
        // When
        await sut.save()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, "New Aisle")
        XCTAssertNil(mockAddAisleUseCase.addedAisles[0].description)
    }
    
    func testSave_AddMode_WithError() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "New Aisle"
        
        mockAddAisleUseCase.shouldThrowError = true
        mockAddAisleUseCase.errorToThrow = NSError(
            domain: "AddError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to add aisle"]
        )
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to add aisle"))
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Form should not be reset on error
        XCTAssertEqual(sut.name, "New Aisle")
        
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 0)
    }
    
    // MARK: - Save Functionality Tests - Edit Mode
    
    func testSave_EditMode_Success() async {
        // Given
        let testAisle = TestDataFactory.createTestAisle(
            id: "test-aisle",
            name: "Original Name",
            description: "Original Description",
            colorHex: "#007AFF"
        )
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        sut.name = "Updated Name"
        sut.description = "Updated Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        
        // Form should NOT be reset for edit mode
        XCTAssertEqual(sut.name, "Updated Name")
        XCTAssertEqual(sut.description, "Updated Description")
        
        // Verify update use case was called
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 1)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles[0].id, "test-aisle")
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles[0].name, "Updated Name")
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles[0].description, "Updated Description")
        
        // Add use case should not be called
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 0)
    }
    
    func testSave_EditMode_WithEmptyDescription() async {
        // Given
        let testAisle = TestDataFactory.createTestAisle(
            id: "test-aisle",
            name: "Test Name",
            description: "Original Description",
            colorHex: "#007AFF"
        )
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        sut.description = ""
        
        // When
        await sut.save()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 1)
        XCTAssertNil(mockUpdateAisleUseCase.updatedAisles[0].description)
    }
    
    func testSave_EditMode_WithError() async {
        // Given
        let testAisle = TestDataFactory.createTestAisle(
            id: "test-aisle",
            name: "Test Name",
            colorHex: "#007AFF"
        )
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        sut.name = "Updated Name"
        
        mockUpdateAisleUseCase.shouldThrowError = true
        mockUpdateAisleUseCase.errorToThrow = NSError(
            domain: "UpdateError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to update aisle"]
        )
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to update aisle"))
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Form should not be reset on error
        XCTAssertEqual(sut.name, "Updated Name")
        
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 0)
    }
    
    // MARK: - Validation Tests
    
    func testSave_WithEmptyName_ShowsValidationError() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = ""
        sut.description = "Some description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(sut.errorMessage, "Le nom du rayon ne peut pas être vide")
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Neither use case should be called
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 0)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 0)
    }
    
    func testSave_WithWhitespaceOnlyName_AllowsSave() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "   "
        sut.description = "Some description"
        
        // When
        await sut.save()
        
        // Then - Production code allows whitespace-only names (doesn't trim)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        
        // Add use case should be called with whitespace name
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, "   ")
    }
    
    // MARK: - Loading State Tests
    
    func testSave_LoadingStateTransitions() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "Test Aisle"
        
        // Initially not loading
        XCTAssertFalse(sut.isLoading)
        
        // When
        let saveTask = Task { await sut.save() }
        
        // Then - Should be loading during save
        // Note: This might be tricky to test due to async timing, so we'll test the final state
        await saveTask.value
        
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Message Handling Tests
    
    func testDismissSuccessMessage() {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.showingSuccessMessage = true
        
        // When
        sut.dismissSuccessMessage()
        
        // Then
        XCTAssertFalse(sut.showingSuccessMessage)
    }
    
    func testDismissErrorMessage() {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.errorMessage = "Some error"
        
        // When
        sut.dismissErrorMessage()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteAddWorkflow() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        // When - Fill form
        sut.name = "Pharmacy"
        sut.description = "Main pharmacy aisle"
        
        // Then - Form should be updated
        XCTAssertEqual(sut.name, "Pharmacy")
        XCTAssertEqual(sut.description, "Main pharmacy aisle")
        XCTAssertFalse(sut.isEditing)
        
        // When - Save
        await sut.save()
        
        // Then - Should succeed and reset form
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        
        // When - Dismiss success message
        sut.dismissSuccessMessage()
        
        // Then
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // Verify use case was called correctly
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, "Pharmacy")
    }
    
    func testCompleteEditWorkflow() async {
        // Given
        let testAisle = TestDataFactory.createTestAisle(
            id: "edit-aisle",
            name: "Original Name",
            description: "Original Description",
            colorHex: "#007AFF"
        )
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: testAisle
        )
        
        // Then - Form should be pre-filled
        XCTAssertEqual(sut.name, "Original Name")
        XCTAssertEqual(sut.description, "Original Description")
        XCTAssertTrue(sut.isEditing)
        XCTAssertEqual(sut.title, "Modifier le rayon")
        
        // When - Update form
        sut.name = "Updated Name"
        sut.description = "Updated Description"
        
        // When - Save
        await sut.save()
        
        // Then - Should succeed but NOT reset form
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.name, "Updated Name")
        XCTAssertEqual(sut.description, "Updated Description")
        
        // Verify update use case was called
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 1)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles[0].id, "edit-aisle")
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles[0].name, "Updated Name")
    }
    
    func testErrorRecoveryWorkflow() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        sut.name = "Test Aisle"
        
        // Set up error
        mockAddAisleUseCase.shouldThrowError = true
        mockAddAisleUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When - First save attempt fails
        await sut.save()
        
        // Then - Should show error
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Network error"))
        XCTAssertFalse(sut.showingSuccessMessage)
        
        // When - Dismiss error
        sut.dismissErrorMessage()
        
        // Then
        XCTAssertNil(sut.errorMessage)
        
        // When - Fix error and retry
        mockAddAisleUseCase.shouldThrowError = false
        await sut.save()
        
        // Then - Should succeed
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSave_WithVeryLongName() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        let longName = String(repeating: "A", count: 1000)
        sut.name = longName
        
        // When
        await sut.save()
        
        // Then - Should still work (no validation for max length)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, longName)
    }
    
    func testSave_WithSpecialCharacters() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        sut.name = "Rayon #1 - Médicaments & Soins"
        sut.description = "Description avec des caractères spéciaux: éàç"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, "Rayon #1 - Médicaments & Soins")
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].description, "Description avec des caractères spéciaux: éàç")
    }
    
    func testMultipleConsecutiveSaves_AddMode() async {
        // Given
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
        
        // When - First save
        sut.name = "Aisle 1"
        await sut.save()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(sut.name, "") // Form reset
        
        // When - Dismiss and save again
        sut.dismissSuccessMessage()
        sut.name = "Aisle 2"
        await sut.save()
        
        // Then
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 2)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[0].name, "Aisle 1")
        XCTAssertEqual(mockAddAisleUseCase.addedAisles[1].name, "Aisle 2")
    }
}
