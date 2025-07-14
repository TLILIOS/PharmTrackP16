import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class MedicineStockViewModelTests: XCTestCase, Sendable {
    
    var sut: MedicineStockViewModel!
    var mockMedicineRepository: MockMedicineRepository!
    var mockAisleRepository: MockAisleRepository!
    var mockHistoryRepository: MockHistoryRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockMedicineRepository = MockMedicineRepository()
        mockAisleRepository = MockAisleRepository()
        mockHistoryRepository = MockHistoryRepository()
        
        sut = MedicineStockViewModel(
            medicineRepository: mockMedicineRepository,
            aisleRepository: mockAisleRepository,
            historyRepository: mockHistoryRepository
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockMedicineRepository = nil
        mockAisleRepository = nil
        mockHistoryRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.medicines.count, 0)
        XCTAssertEqual(sut.aisles.count, 0)
        XCTAssertEqual(sut.aisleObjects.count, 0)
        XCTAssertEqual(sut.history.count, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Published Properties Tests
    
    func testMedicinesPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Medicines change")
        
        let testMedicines = [
            TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1"),
            TestDataFactory.createTestMedicine(id: "med2", name: "Medicine 2")
        ]
        
        sut.$medicines
            .dropFirst()
            .sink { medicines in
                if medicines.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockMedicineRepository.returnMedicines = testMedicines
        await sut.fetchMedicines()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testAislesPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Aisles change")
        
        let testAisles = [
            TestDataFactory.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "aisle2", name: "Emergency", colorHex: "#FF0000")
        ]
        
        sut.$aisles
            .dropFirst()
            .sink { aisles in
                if aisles.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockAisleRepository.returnAisles = testAisles
        await sut.fetchAisles()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testAisleObjectsPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Aisle objects change")
        
        let testAisles = [
            TestDataFactory.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF")
        ]
        
        sut.$aisleObjects
            .dropFirst()
            .sink { aisleObjects in
                if aisleObjects.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockAisleRepository.returnAisles = testAisles
        await sut.fetchAisles()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testIsLoadingPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Loading state changes")
        expectation.expectedFulfillmentCount = 2 // true then false
        
        sut.$isLoading
            .dropFirst()
            .sink { _ in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        await sut.fetchMedicines()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testErrorMessagePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Error message changes")
        
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchMedicines()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Fetch Medicines Tests
    
    func testFetchMedicines_Success() async {
        // Given
        let testMedicines = [
            TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1", currentQuantity: 25),
            TestDataFactory.createTestMedicine(id: "med2", name: "Medicine 2", currentQuantity: 50),
            TestDataFactory.createTestMedicine(id: "med3", name: "Medicine 3", currentQuantity: 10)
        ]
        mockMedicineRepository.returnMedicines = testMedicines
        
        // When
        await sut.fetchMedicines()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.medicines.count, 3)
        XCTAssertEqual(sut.medicines[0].name, "Medicine 1")
        XCTAssertEqual(sut.medicines[1].name, "Medicine 2")
        XCTAssertEqual(sut.medicines[2].name, "Medicine 3")
    }
    
    func testFetchMedicines_WithError() async {
        // Given
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "MedicineError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch medicines"]
        )
        
        // When
        await sut.fetchMedicines()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to fetch medicines"))
        XCTAssertEqual(sut.medicines.count, 0)
    }
    
    func testFetchMedicines_WithCaching() async {
        // Given
        let testMedicines = [TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1")]
        mockMedicineRepository.returnMedicines = testMedicines
        
        // When - First fetch
        await sut.fetchMedicines()
        
        // Then
        XCTAssertEqual(sut.medicines.count, 1)
        XCTAssertEqual(mockMedicineRepository.callCount, 1)
        
        // When - Second fetch immediately (should use cache)
        await sut.fetchMedicines()
        
        // Then - Should not call repository again due to caching
        XCTAssertEqual(mockMedicineRepository.callCount, 1)
        XCTAssertEqual(sut.medicines.count, 1)
    }
    
    func testFetchMedicines_LoadingStates() async {
        // Given
        mockMedicineRepository.returnMedicines = []
        
        // Initially not loading
        XCTAssertFalse(sut.isLoading)
        
        // When
        let fetchTask = Task { await sut.fetchMedicines() }
        
        // Then - Should complete and not be loading
        await fetchTask.value
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Fetch Aisles Tests
    
    func testFetchAisles_Success() async {
        // Given
        let testAisles = [
            TestDataFactory.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "aisle2", name: "Emergency", colorHex: "#FF0000")
        ]
        mockAisleRepository.returnAisles = testAisles
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.aisleObjects.count, 2)
        XCTAssertEqual(sut.aisles.count, 2)
        XCTAssertTrue(sut.aisles.contains("Pharmacy"))
        XCTAssertTrue(sut.aisles.contains("Emergency"))
        XCTAssertEqual(sut.aisles.sorted(), ["Emergency", "Pharmacy"]) // Should be sorted
    }
    
    func testFetchAisles_WithError() async {
        // Given
        mockAisleRepository.shouldThrowError = true
        mockAisleRepository.errorToThrow = NSError(
            domain: "AisleError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch aisles"]
        )
        
        // When
        await sut.fetchAisles()
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to fetch aisles"))
        XCTAssertEqual(sut.aisleObjects.count, 0)
        XCTAssertEqual(sut.aisles.count, 0)
    }
    
    func testFetchAisles_WithCaching() async {
        // Given
        let testAisles = [TestDataFactory.createTestAisle(id: "aisle1", name: "Test Aisle", colorHex: "#007AFF")]
        mockAisleRepository.returnAisles = testAisles
        
        // When - First fetch
        await sut.fetchAisles()
        
        // Then
        XCTAssertEqual(sut.aisleObjects.count, 1)
        XCTAssertEqual(mockAisleRepository.callCount, 1)
        
        // When - Second fetch immediately (should use cache)
        await sut.fetchAisles()
        
        // Then - Should not call repository again due to caching
        XCTAssertEqual(mockAisleRepository.callCount, 1)
        XCTAssertEqual(sut.aisleObjects.count, 1)
    }
    
    // MARK: - Stock Management Tests
    
    func testIncreaseStock_Success() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Test Medicine",
            currentQuantity: 20
        )
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Test Medicine",
            currentQuantity: 21
        )
        mockMedicineRepository.returnUpdatedMedicine = updatedMedicine
        
        // When
        await sut.increaseStock(testMedicine, user: "test-user")
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.lastUpdateMedicineStockCall?.id, "med1")
        XCTAssertEqual(mockMedicineRepository.lastUpdateMedicineStockCall?.newStock, 21)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        XCTAssertTrue(mockHistoryRepository.addedEntries[0].action.contains("Increased stock"))
    }
    
    func testDecreaseStock_Success() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Test Medicine",
            currentQuantity: 20
        )
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Test Medicine",
            currentQuantity: 19
        )
        mockMedicineRepository.returnUpdatedMedicine = updatedMedicine
        
        // When
        await sut.decreaseStock(testMedicine, user: "test-user")
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.lastUpdateMedicineStockCall?.id, "med1")
        XCTAssertEqual(mockMedicineRepository.lastUpdateMedicineStockCall?.newStock, 19)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        XCTAssertTrue(mockHistoryRepository.addedEntries[0].action.contains("Decreased stock"))
    }
    
    func testIncreaseStock_WithError() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(id: "med1", name: "Test Medicine")
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "StockError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to update stock"]
        )
        
        // When
        await sut.increaseStock(testMedicine, user: "test-user")
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to update stock"))
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 0) // No history added on error
    }
    
    // MARK: - Add Random Medicine Tests
    
    func testAddRandomMedicine_Success() async {
        // Given
        let savedMedicine = TestDataFactory.createTestMedicine(
            id: "random-med",
            name: "Random Medicine"
        )
        mockMedicineRepository.returnSavedMedicine = savedMedicine
        
        // When
        await sut.addRandomMedicine(user: "test-user")
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.savedMedicines.count, 1)
        XCTAssertTrue(mockMedicineRepository.savedMedicines[0].name.contains("Medicine"))
        XCTAssertEqual(mockMedicineRepository.savedMedicines[0].dosage, "500mg")
        XCTAssertEqual(mockMedicineRepository.savedMedicines[0].form, "Tablet")
        
        // Verify history was added
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        XCTAssertTrue(mockHistoryRepository.addedEntries[0].action.contains("Added"))
        XCTAssertEqual(mockHistoryRepository.addedEntries[0].userId, "test-user")
    }
    
    func testAddRandomMedicine_WithError() async {
        // Given
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "AddError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to add medicine"]
        )
        
        // When
        await sut.addRandomMedicine(user: "test-user")
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to add medicine"))
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 0) // No history added on error
    }
    
    // MARK: - Delete Medicines Tests
    
    func testDeleteMedicines_Success() async {
        // Given
        let testMedicines = [
            TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1"),
            TestDataFactory.createTestMedicine(id: "med2", name: "Medicine 2"),
            TestDataFactory.createTestMedicine(id: "med3", name: "Medicine 3")
        ]
        sut.medicines = testMedicines
        
        let indexSet = IndexSet([0, 2]) // Delete first and third medicines
        
        // When
        await sut.deleteMedicines(at: indexSet)
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.deletedMedicineIds.count, 2)
        XCTAssertTrue(mockMedicineRepository.deletedMedicineIds.contains("med1"))
        XCTAssertTrue(mockMedicineRepository.deletedMedicineIds.contains("med3"))
        XCTAssertFalse(mockMedicineRepository.deletedMedicineIds.contains("med2"))
    }
    
    func testDeleteMedicines_WithError() async {
        // Given
        let testMedicines = [TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1")]
        sut.medicines = testMedicines
        
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "DeleteError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to delete medicine"]
        )
        
        let indexSet = IndexSet([0])
        
        // When
        await sut.deleteMedicines(at: indexSet)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to delete medicine"))
        XCTAssertEqual(mockMedicineRepository.deletedMedicineIds.count, 0)
    }
    
    // MARK: - Update Medicine Tests
    
    func testUpdateMedicine_Success() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Updated Medicine",
            description: "Updated Description"
        )
        mockMedicineRepository.returnSavedMedicine = testMedicine
        
        // When
        await sut.updateMedicine(testMedicine, user: "test-user")
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.savedMedicines.count, 1)
        XCTAssertEqual(mockMedicineRepository.savedMedicines[0].id, "med1")
        XCTAssertEqual(mockMedicineRepository.savedMedicines[0].name, "Updated Medicine")
        
        // Verify history was added
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        XCTAssertTrue(mockHistoryRepository.addedEntries[0].action.contains("Updated"))
        XCTAssertEqual(mockHistoryRepository.addedEntries[0].medicineId, "med1")
        XCTAssertEqual(mockHistoryRepository.addedEntries[0].userId, "test-user")
    }
    
    func testUpdateMedicine_WithError() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(id: "med1", name: "Test Medicine")
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(
            domain: "UpdateError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to update medicine"]
        )
        
        // When
        await sut.updateMedicine(testMedicine, user: "test-user")
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to update medicine"))
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 0) // No history added on error
    }
    
    // MARK: - Fetch History Tests
    
    func testFetchHistory_Success() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(id: "med1", name: "Test Medicine")
        let testHistory = [
            TestDataFactory.createTestHistoryEntry(
                id: "hist1",
                medicineId: "med1",
                action: "Stock Updated",
                details: "Increased stock"
            ),
            TestDataFactory.createTestHistoryEntry(
                id: "hist2",
                medicineId: "med1",
                action: "Medicine Created",
                details: "Initial creation"
            )
        ]
        mockHistoryRepository.historyForMedicine = testHistory
        
        // When
        await sut.fetchHistory(for: testMedicine)
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.history.count, 2)
        // History is sorted by timestamp (most recent first), so order can vary
        let actions = sut.history.map { $0.action }
        XCTAssertTrue(actions.contains("Stock Updated"))
        XCTAssertTrue(actions.contains("Medicine Created"))
        XCTAssertEqual(mockHistoryRepository.lastMedicineIdForHistory, "med1")
    }
    
    func testFetchHistory_WithError() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(id: "med1", name: "Test Medicine")
        mockHistoryRepository.shouldThrowError = true
        mockHistoryRepository.errorToThrow = NSError(
            domain: "HistoryError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch history"]
        )
        
        // When
        await sut.fetchHistory(for: testMedicine)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Failed to fetch history"))
        XCTAssertEqual(sut.history.count, 0)
    }
    
    // MARK: - Real-time Listeners Tests
    
    func testMedicinesListener_ReceivesUpdates() async {
        let expectation = XCTestExpectation(description: "Medicines listener receives updates")
        
        let testMedicines = [
            TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1"),
            TestDataFactory.createTestMedicine(id: "med2", name: "Medicine 2")
        ]
        
        // Configure mock data before recreating ViewModel
        mockMedicineRepository.medicines = testMedicines
        mockMedicineRepository.returnMedicines = testMedicines
        
        // Recreate ViewModel after setting up mock data to ensure listeners pick up the data
        sut = MedicineStockViewModel(
            medicineRepository: mockMedicineRepository,
            aisleRepository: mockAisleRepository,
            historyRepository: mockHistoryRepository
        )
        
        sut.$medicines
            .dropFirst()
            .sink { medicines in
                if medicines.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger fetch to ensure data is loaded
        await sut.fetchMedicines()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.medicines.count, 2)
    }
    
    func testAislesListener_ReceivesUpdates() async {
        let expectation = XCTestExpectation(description: "Aisles listener receives updates")
        
        let testAisles = [
            TestDataFactory.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF"),
            TestDataFactory.createTestAisle(id: "aisle2", name: "Emergency", colorHex: "#FF0000")
        ]
        
        sut.$aisleObjects
            .dropFirst()
            .sink { aisleObjects in
                if aisleObjects.count == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate repository update by triggering fetch
        mockAisleRepository.returnAisles = testAisles
        await sut.fetchAisles()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.aisleObjects.count, 2)
        XCTAssertEqual(sut.aisles.count, 2)
        XCTAssertTrue(sut.aisles.contains("Pharmacy"))
        XCTAssertTrue(sut.aisles.contains("Emergency"))
    }
    
    func testListener_HandlesErrors() async {
        let expectation = XCTestExpectation(description: "Listener handles errors")
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Set up repository error and trigger fetch
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(domain: "ListenerError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Listener error"])
        
        await sut.fetchMedicines()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Listener error"))
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow_FetchAndManageStock() async {
        // Given
        let testMedicines = [
            TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1", currentQuantity: 10)
        ]
        let testAisles = [
            TestDataFactory.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF")
        ]
        
        mockMedicineRepository.medicines = testMedicines
        mockMedicineRepository.returnMedicines = testMedicines
        mockAisleRepository.aisles = testAisles
        mockAisleRepository.returnAisles = testAisles
        mockMedicineRepository.returnUpdatedMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Medicine 1",
            currentQuantity: 11
        )
        
        // Recreate ViewModel after setting up mock data to ensure listeners pick up the data
        sut = MedicineStockViewModel(
            medicineRepository: mockMedicineRepository,
            aisleRepository: mockAisleRepository,
            historyRepository: mockHistoryRepository
        )
        
        // When - Fetch data
        await sut.fetchMedicines()
        await sut.fetchAisles()
        
        // Allow time for listeners to update
        await Task.yield()
        
        // Then - Verify data loaded
        print("DEBUG: medicines.count = \(sut.medicines.count), aisles.count = \(sut.aisles.count)")
        print("DEBUG: aisleObjects.count = \(sut.aisleObjects.count)")
        print("DEBUG: mock aisles = \(mockAisleRepository.aisles)")
        print("DEBUG: mock returnAisles = \(mockAisleRepository.returnAisles)")
        
        XCTAssertEqual(sut.medicines.count, 1)
        XCTAssertEqual(sut.aisles.count, 1)
        XCTAssertTrue(sut.aisles.contains("Pharmacy"))
        
        // When - Increase stock
        await sut.increaseStock(testMedicines[0], user: "test-user")
        
        // Then - Verify stock updated and history added
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.lastUpdateMedicineStockCall?.newStock, 11)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        XCTAssertTrue(mockHistoryRepository.addedEntries[0].action.contains("Increased"))
    }
    
    func testCompleteWorkflow_AddAndUpdateMedicine() async {
        // Given
        let newMedicine = TestDataFactory.createTestMedicine(
            id: "new-med",
            name: "New Medicine"
        )
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "new-med",
            name: "Updated Medicine"
        )
        
        mockMedicineRepository.returnSavedMedicine = newMedicine
        
        // When - Add random medicine
        await sut.addRandomMedicine(user: "test-user")
        
        // Then - Verify medicine added
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.savedMedicines.count, 1)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 1)
        
        // When - Update medicine
        mockMedicineRepository.returnSavedMedicine = updatedMedicine
        await sut.updateMedicine(updatedMedicine, user: "test-user")
        
        // Then - Verify medicine updated
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.savedMedicines.count, 2)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 2)
        XCTAssertTrue(mockHistoryRepository.addedEntries[1].action.contains("Updated"))
    }
    
    func testStateConsistency_MultipleOperations() async {
        // Given
        let testMedicines = [TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1")]
        mockMedicineRepository.returnMedicines = testMedicines
        mockMedicineRepository.returnUpdatedMedicine = testMedicines[0]
        
        // When - Perform multiple operations
        await sut.fetchMedicines()
        XCTAssertNil(sut.errorMessage)
        
        await sut.increaseStock(testMedicines[0], user: "user1")
        XCTAssertNil(sut.errorMessage)
        
        await sut.decreaseStock(testMedicines[0], user: "user2")
        XCTAssertNil(sut.errorMessage)
        
        // Then - State should be consistent
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(mockHistoryRepository.addedEntries.count, 2)
    }
    
    // MARK: - Edge Cases Tests
    
    func testAddRandomMedicine_GeneratesUniqueValues() async {
        // Given
        mockMedicineRepository.returnSavedMedicine = TestDataFactory.createTestMedicine(id: "random", name: "Random")
        
        // When - Add multiple random medicines
        await sut.addRandomMedicine(user: "test-user")
        await sut.addRandomMedicine(user: "test-user")
        await sut.addRandomMedicine(user: "test-user")
        
        // Then - Should have different IDs and names
        XCTAssertEqual(mockMedicineRepository.savedMedicines.count, 3)
        let medicine1 = mockMedicineRepository.savedMedicines[0]
        let medicine2 = mockMedicineRepository.savedMedicines[1]
        let medicine3 = mockMedicineRepository.savedMedicines[2]
        
        XCTAssertNotEqual(medicine1.id, medicine2.id)
        XCTAssertNotEqual(medicine2.id, medicine3.id)
        XCTAssertNotEqual(medicine1.id, medicine3.id)
    }
    
    func testStockOperations_WithZeroQuantity() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Test Medicine",
            currentQuantity: 0
        )
        let updatedMedicine = TestDataFactory.createTestMedicine(
            id: "med1",
            name: "Test Medicine",
            currentQuantity: -1
        )
        mockMedicineRepository.returnUpdatedMedicine = updatedMedicine
        
        // When - Decrease stock from 0
        await sut.decreaseStock(testMedicine, user: "test-user")
        
        // Then - Should allow negative stock (business logic allows it)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.lastUpdateMedicineStockCall?.newStock, -1)
    }
    
    func testDeleteMedicines_EmptyIndexSet() async {
        // Given
        let testMedicines = [TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1")]
        sut.medicines = testMedicines
        
        let emptyIndexSet = IndexSet()
        
        // When
        await sut.deleteMedicines(at: emptyIndexSet)
        
        // Then - No deletions should occur
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockMedicineRepository.deletedMedicineIds.count, 0)
    }
    
    func testFetchHistory_EmptyResult() async {
        // Given
        let testMedicine = TestDataFactory.createTestMedicine(id: "med1", name: "Test Medicine")
        mockHistoryRepository.historyForMedicine = []
        
        // When
        await sut.fetchHistory(for: testMedicine)
        
        // Then
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.history.count, 0)
        XCTAssertEqual(mockHistoryRepository.lastMedicineIdForHistory, "med1")
    }
    
    func testErrorRecovery() async {
        // Given
        mockMedicineRepository.shouldThrowError = true
        mockMedicineRepository.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Initial error"])
        
        // When - First operation fails
        await sut.fetchMedicines()
        
        // Then - Should be in error state
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage!.contains("Initial error"))
        
        // When - Fix error and retry
        mockMedicineRepository.shouldThrowError = false
        mockMedicineRepository.returnMedicines = [TestDataFactory.createTestMedicine(id: "med1", name: "Medicine 1")]
        await sut.fetchMedicines()
        
        // Then - Should recover
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.medicines.count, 1)
    }
}
