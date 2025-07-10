import XCTest
@testable import MediStock

@MainActor
final class AisleFormViewModelTests: XCTestCase {
    
    var sut: AisleFormViewModel!
    var mockAddAisleUseCase: MockAddAisleUseCase!
    var mockUpdateAisleUseCase: MockUpdateAisleUseCase!
    
    override func setUp() {
        super.setUp()
        mockAddAisleUseCase = MockAddAisleUseCase()
        mockUpdateAisleUseCase = MockUpdateAisleUseCase()
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockAddAisleUseCase = nil
        mockUpdateAisleUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState_NewAisle() {
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertFalse(sut.isEditing)
        XCTAssertEqual(sut.title, "Ajouter un rayon")
    }
    
    func testInitialState_EditingAisle() {
        // Given
        let existingAisle = TestDataFactory.createTestAisle(
            name: "Existing Aisle",
            description: "Existing Description"
        )
        
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: existingAisle
        )
        
        // Then
        XCTAssertEqual(sut.name, "Existing Aisle")
        XCTAssertEqual(sut.description, "Existing Description")
        XCTAssertTrue(sut.isEditing)
        XCTAssertEqual(sut.title, "Modifier le rayon")
    }
    
    func testInitialState_EditingAisleWithNilDescription() {
        // Given
        let existingAisle = TestDataFactory.createTestAisle(
            name: "Existing Aisle",
            description: nil
        )
        
        // When
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: existingAisle
        )
        
        // Then
        XCTAssertEqual(sut.name, "Existing Aisle")
        XCTAssertEqual(sut.description, "")
        XCTAssertTrue(sut.isEditing)
    }
    
    // MARK: - Save New Aisle Tests
    
    func testSave_NewAisle_Success() async {
        // Given
        sut.name = "New Aisle"
        sut.description = "New Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        
        let addedAisle = mockAddAisleUseCase.addedAisles.first!
        XCTAssertEqual(addedAisle.name, "New Aisle")
        XCTAssertEqual(addedAisle.description, "New Description")
        
        // Form should be reset after successful add
        XCTAssertEqual(sut.name, "")
        XCTAssertEqual(sut.description, "")
    }
    
    func testSave_NewAisle_EmptyDescription() async {
        // Given
        sut.name = "New Aisle"
        sut.description = ""
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        
        let addedAisle = mockAddAisleUseCase.addedAisles.first!
        XCTAssertEqual(addedAisle.name, "New Aisle")
        XCTAssertNil(addedAisle.description) // Empty description should become nil
    }
    
    func testSave_NewAisle_Failure() async {
        // Given
        sut.name = "New Aisle"
        sut.description = "New Description"
        mockAddAisleUseCase.shouldThrowError = true
        let expectedError = "Failed to add aisle"
        mockAddAisleUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Erreur lors de la sauvegarde: \(expectedError)")
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertTrue(mockAddAisleUseCase.addedAisles.isEmpty)
        
        // Form should not be reset on failure
        XCTAssertEqual(sut.name, "New Aisle")
        XCTAssertEqual(sut.description, "New Description")
    }
    
    // MARK: - Save Existing Aisle Tests
    
    func testSave_ExistingAisle_Success() async {
        // Given
        let existingAisle = TestDataFactory.createTestAisle(
            id: "test-id",
            name: "Original Name",
            description: "Original Description"
        )
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: existingAisle
        )
        
        sut.name = "Updated Name"
        sut.description = "Updated Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 0) // Should not add
        
        let updatedAisle = mockUpdateAisleUseCase.updatedAisles.first!
        XCTAssertEqual(updatedAisle.id, "test-id")
        XCTAssertEqual(updatedAisle.name, "Updated Name")
        XCTAssertEqual(updatedAisle.description, "Updated Description")
        
        // Form should NOT be reset for editing
        XCTAssertEqual(sut.name, "Updated Name")
        XCTAssertEqual(sut.description, "Updated Description")
    }
    
    func testSave_ExistingAisle_Failure() async {
        // Given
        let existingAisle = TestDataFactory.createTestAisle(
            id: "test-id",
            name: "Original Name"
        )
        
        sut = AisleFormViewModel(
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            aisle: existingAisle
        )
        
        sut.name = "Updated Name"
        mockUpdateAisleUseCase.shouldThrowError = true
        let expectedError = "Failed to update aisle"
        mockUpdateAisleUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Erreur lors de la sauvegarde: \(expectedError)")
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertTrue(mockUpdateAisleUseCase.updatedAisles.isEmpty)
    }
    
    // MARK: - Validation Tests
    
    func testSave_EmptyName() async {
        // Given
        sut.name = ""
        sut.description = "Valid Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "Le nom du rayon ne peut pas être vide")
        XCTAssertFalse(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 0)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 0)
    }
    
    func testSave_WhitespaceName() async {
        // Given
        sut.name = "   "
        sut.description = "Valid Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertEqual(sut.errorMessage, "Le nom du rayon ne peut pas être vide")
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 0)
    }
    
    // MARK: - Loading State Tests
    
    func testSave_LoadingState() async {
        // Given
        sut.name = "Test Aisle"
        mockAddAisleUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.save()
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        
        await task.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.showingSuccessMessage)
    }
    
    // MARK: - Message Dismissal Tests
    
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
    
    // MARK: - Edge Cases Tests
    
    func testSave_VeryLongName() async {
        // Given
        sut.name = String(repeating: "a", count: 1000)
        sut.description = "Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertNil(sut.errorMessage) // Should handle long names
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.first!.name.count, 1000)
    }
    
    func testSave_VeryLongDescription() async {
        // Given
        sut.name = "Test Aisle"
        sut.description = String(repeating: "b", count: 10000)
        
        // When
        await sut.save()
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.first!.description?.count, 10000)
    }
    
    func testSave_SpecialCharactersInName() async {
        // Given
        sut.name = "Åäö#$%&*()_+-=[]{}|;:,.<>?/~`"
        sut.description = "Special chars test"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.first!.name, "Åäö#$%&*()_+-=[]{}|;:,.<>?/~`")
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistency_SuccessfulSave() async {
        // Given
        sut.name = "Test Aisle"
        sut.description = "Test Description"
        
        // When
        await sut.save()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
    }
    
    func testStateConsistency_ErrorRecovery() async {
        // Given
        sut.name = "Test Aisle"
        mockAddAisleUseCase.shouldThrowError = true
        mockAddAisleUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [:])
        
        // When - First save fails
        await sut.save()
        XCTAssertNotNil(sut.errorMessage)
        
        // Reset error and try again
        mockAddAisleUseCase.shouldThrowError = false
        sut.dismissErrorMessage()
        
        await sut.save()
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.showingSuccessMessage)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentSaveAttempts() async {
        // Given
        sut.name = "Test Aisle"
        mockAddAisleUseCase.delayNanoseconds = 50_000_000
        
        // When - Start multiple save attempts
        let task1 = Task { await sut.save() }
        let task2 = Task { await sut.save() }
        
        await task1.value
        await task2.value
        
        // Then - Should handle concurrent requests gracefully
        XCTAssertFalse(sut.isLoading)
        // Both saves should complete (though the behavior might vary based on implementation)
        XCTAssertGreaterThanOrEqual(mockAddAisleUseCase.addedAisles.count, 1)
    }
    
    // MARK: - UUID Generation Tests
    
    func testSave_GeneratesUniqueIds() async {
        // Given
        sut.name = "Test Aisle 1"
        await sut.save()
        
        sut.name = "Test Aisle 2"
        await sut.save()
        
        // Then
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 2)
        let id1 = mockAddAisleUseCase.addedAisles[0].id
        let id2 = mockAddAisleUseCase.addedAisles[1].id
        XCTAssertNotEqual(id1, id2)
        XCTAssertFalse(id1.isEmpty)
        XCTAssertFalse(id2.isEmpty)
    }
}