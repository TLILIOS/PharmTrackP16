import XCTest
@testable import MediStock

@MainActor
final class AislesViewModelTests: XCTestCase {
    
    var sut: AislesViewModel!
    var mockGetAislesUseCase: MockGetAislesUseCase!
    var mockAddAisleUseCase: MockAddAisleUseCase!
    var mockUpdateAisleUseCase: MockUpdateAisleUseCase!
    var mockDeleteAisleUseCase: MockDeleteAisleUseCase!
    var mockGetMedicineCountByAisleUseCase: MockGetMedicineCountByAisleUseCase!
    
    override func setUp() {
        super.setUp()
        mockGetAislesUseCase = MockGetAislesUseCase()
        mockAddAisleUseCase = MockAddAisleUseCase()
        mockUpdateAisleUseCase = MockUpdateAisleUseCase()
        mockDeleteAisleUseCase = MockDeleteAisleUseCase()
        mockGetMedicineCountByAisleUseCase = MockGetMedicineCountByAisleUseCase()
        
        sut = AislesViewModel(
            getAislesUseCase: mockGetAislesUseCase,
            addAisleUseCase: mockAddAisleUseCase,
            updateAisleUseCase: mockUpdateAisleUseCase,
            deleteAisleUseCase: mockDeleteAisleUseCase,
            getMedicineCountByAisleUseCase: mockGetMedicineCountByAisleUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockGetAislesUseCase = nil
        mockAddAisleUseCase = nil
        mockUpdateAisleUseCase = nil
        mockDeleteAisleUseCase = nil
        mockGetMedicineCountByAisleUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.aisles.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Fetch Aisles Tests
    
    func testFetchAisles_Success() async {
        // Given
        let expectedAisles = TestDataFactory.createMultipleAisles(count: 3)
        mockGetAislesUseCase.aisles = expectedAisles
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertEqual(sut.aisles.count, expectedAisles.count)
        XCTAssertEqual(sut.aisles, expectedAisles)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testFetchAisles_Failure() async {
        // Given
        mockGetAislesUseCase.shouldThrowError = true
        let expectedError = "Failed to fetch aisles"
        mockGetAislesUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertTrue(sut.aisles.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    func testFetchAisles_LoadingState() async {
        // Given
        mockGetAislesUseCase.aisles = []
        mockGetAislesUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.fetchAisles()
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        
        await task.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Add Aisle Tests
    
    func testAddAisle_Success() async {
        // Given
        let newAisle = TestDataFactory.createTestAisle(name: "New Aisle")
        
        // When
        await sut.addAisle(newAisle)
        
        // Then
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.first?.name, newAisle.name)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testAddAisle_Failure() async {
        // Given
        let newAisle = TestDataFactory.createTestAisle(name: "New Aisle")
        mockAddAisleUseCase.shouldThrowError = true
        let expectedError = "Failed to add aisle"
        mockAddAisleUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.addAisle(newAisle)
        
        // Then
        XCTAssertTrue(mockAddAisleUseCase.addedAisles.isEmpty)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    // MARK: - Update Aisle Tests
    
    func testUpdateAisle_Success() async {
        // Given
        let existingAisle = TestDataFactory.createTestAisle(id: "1", name: "Original Name")
        let updatedAisle = TestDataFactory.createTestAisle(id: "1", name: "Updated Name")
        
        // When
        await sut.updateAisle(updatedAisle)
        
        // Then
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 1)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.first?.name, "Updated Name")
        XCTAssertNil(sut.errorMessage)
    }
    
    func testUpdateAisle_Failure() async {
        // Given
        let aisle = TestDataFactory.createTestAisle(name: "Test Aisle")
        mockUpdateAisleUseCase.shouldThrowError = true
        let expectedError = "Failed to update aisle"
        mockUpdateAisleUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.updateAisle(aisle)
        
        // Then
        XCTAssertTrue(mockUpdateAisleUseCase.updatedAisles.isEmpty)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    // MARK: - Delete Aisle Tests
    
    func testDeleteAisle_Success() async {
        // Given
        let aisleId = "test-aisle-1"
        
        // When
        await sut.deleteAisle(aisleId)
        
        // Then
        XCTAssertEqual(mockDeleteAisleUseCase.deletedAisleIds.count, 1)
        XCTAssertEqual(mockDeleteAisleUseCase.deletedAisleIds.first, aisleId)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testDeleteAisle_Failure() async {
        // Given
        let aisleId = "test-aisle-1"
        mockDeleteAisleUseCase.shouldThrowError = true
        let expectedError = "Failed to delete aisle"
        mockDeleteAisleUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.deleteAisle(aisleId)
        
        // Then
        XCTAssertTrue(mockDeleteAisleUseCase.deletedAisleIds.isEmpty)
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    // MARK: - Medicine Count Tests
    
    func testGetMedicineCount_Success() async {
        // Given
        let aisleId = "test-aisle-1"
        let expectedCount = 15
        mockGetMedicineCountByAisleUseCase.medicineCount = expectedCount
        
        // When
        let count = await sut.getMedicineCount(for: aisleId)
        
        // Then
        XCTAssertEqual(count, expectedCount)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testGetMedicineCount_Failure() async {
        // Given
        let aisleId = "test-aisle-1"
        mockGetMedicineCountByAisleUseCase.shouldThrowError = true
        let expectedError = "Failed to get medicine count"
        mockGetMedicineCountByAisleUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        let count = await sut.getMedicineCount(for: aisleId)
        
        // Then
        XCTAssertEqual(count, 0) // Should return 0 on error
        XCTAssertEqual(sut.errorMessage, expectedError)
    }
    
    // MARK: - Error Clearing Tests
    
    func testClearError() {
        // Given
        sut.errorMessage = "Some error"
        
        // When
        sut.clearError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Multiple Operations Tests
    
    func testMultipleOperations() async {
        // Given
        let aisle1 = TestDataFactory.createTestAisle(id: "1", name: "Aisle 1")
        let aisle2 = TestDataFactory.createTestAisle(id: "2", name: "Aisle 2")
        let updatedAisle1 = TestDataFactory.createTestAisle(id: "1", name: "Updated Aisle 1")
        
        mockGetAislesUseCase.aisles = [aisle1, aisle2]
        
        // When
        await sut.fetchAisles()
        await sut.updateAisle(updatedAisle1)
        await sut.deleteAisle("2")
        
        // Then
        XCTAssertEqual(sut.aisles.count, 2)
        XCTAssertEqual(mockUpdateAisleUseCase.updatedAisles.count, 1)
        XCTAssertEqual(mockDeleteAisleUseCase.deletedAisleIds.count, 1)
        XCTAssertEqual(mockDeleteAisleUseCase.deletedAisleIds.first, "2")
    }
    
    // MARK: - Aisle Validation Tests
    
    func testAisleValidation() async {
        // Given
        let validAisle = TestDataFactory.createTestAisle(name: "Valid Aisle")
        let invalidAisle = TestDataFactory.createTestAisle(name: "") // Empty name
        
        // When
        await sut.addAisle(validAisle)
        await sut.addAisle(invalidAisle)
        
        // Then
        // Both should be attempted to be added, validation might be handled by use case
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 2)
    }
    
    // MARK: - State Consistency Tests
    
    func testStateConsistency() async {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 3)
        mockGetAislesUseCase.aisles = aisles
        
        // When
        await sut.fetchAisles()
        
        // Then - State should be consistent
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.aisles.count, 3)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentOperations() async {
        // Given
        let aisles = TestDataFactory.createMultipleAisles(count: 2)
        mockGetAislesUseCase.aisles = aisles
        
        // When - Perform concurrent operations
        async let fetchTask = sut.fetchAisles()
        async let addTask = sut.addAisle(TestDataFactory.createTestAisle(name: "New Aisle"))
        async let countTask = sut.getMedicineCount(for: "test-aisle")
        
        await fetchTask
        await addTask
        let _ = await countTask
        
        // Then - All operations should complete
        XCTAssertEqual(sut.aisles.count, 2)
        XCTAssertEqual(mockAddAisleUseCase.addedAisles.count, 1)
    }
}