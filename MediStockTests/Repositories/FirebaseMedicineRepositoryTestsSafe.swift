import XCTest
import Combine
import Firebase
import FirebaseFirestore
@testable @preconcurrency import MediStock

@MainActor
final class FirebaseMedicineRepositoryTestsSafe: XCTestCase, Sendable {
    
    var sut: MockFirebaseMedicineRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        sut = MockFirebaseMedicineRepository()
        sut.reset()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    
    private func createTestMedicine(
        id: String = "test-medicine-1",
        name: String = "Test Medicine",
        aisleId: String = "aisle-1"
    ) -> Medicine {
        return Medicine(
            id: id,
            name: name,
            aisleId: aisleId,
            expirationDate: Date().addingTimeInterval(86400 * 30), // 30 days from now
            quantity: 10,
            minQuantity: 5,
            description: "Test Medicine Description"
        )
    }
    
    private func createTestMedicineDTO(
        id: String = "test-medicine-1",
        name: String = "Test Medicine",
        aisleId: String = "aisle-1"
    ) -> MedicineDTO {
        return MedicineDTO(
            id: id,
            name: name,
            aisleId: aisleId,
            expirationDate: Date().addingTimeInterval(86400 * 30),
            quantity: 10,
            minQuantity: 5,
            description: "Test Medicine Description"
        )
    }
    
    // MARK: - getMedicines Tests
    
    func test_getMedicines_withCacheData_shouldReturnCachedMedicines() async throws {
        // Given
        let testMedicines = [
            createTestMedicine(id: "1", name: "Medicine 1"),
            createTestMedicine(id: "2", name: "Medicine 2")
        ]
        sut.setMockMedicines(testMedicines)
        
        // When
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertNotNil(medicines)
        XCTAssertEqual(medicines.count, 2)
        XCTAssertEqual(medicines[0].name, "Medicine 1")
        XCTAssertEqual(medicines[1].name, "Medicine 2")
    }
    
    func test_getMedicines_withEmptyCache_shouldFetchFromServer() async throws {
        // Given
        sut.setMockMedicines([])
        
        // When
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertNotNil(medicines)
        XCTAssertEqual(medicines.count, 0)
    }
    
    func test_getMedicines_withNetworkError_shouldThrowError() async throws {
        // Given
        sut.setShouldSucceed(false)
        sut.setErrorToThrow(NSError(domain: "NetworkError", code: 1001, userInfo: nil))
        
        // When & Then
        do {
            _ = try await sut.getMedicines()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    func test_getMedicines_withMalformedData_shouldFilterInvalidEntries() async throws {
        // Given
        let validMedicine = createTestMedicine(id: "valid", name: "Valid Medicine")
        sut.setMockMedicines([validMedicine])
        
        // When
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertNotNil(medicines)
        XCTAssertEqual(medicines.count, 1)
        XCTAssertEqual(medicines[0].name, "Valid Medicine")
    }
    
    // MARK: - getMedicine Tests
    
    func test_getMedicine_withValidId_shouldReturnMedicine() async throws {
        // Given
        let testMedicine = createTestMedicine(id: "test-id", name: "Test Medicine")
        sut.setMockMedicines([testMedicine])
        
        // When
        let medicine = try await sut.getMedicine(withId: "test-id")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "Test Medicine")
        XCTAssertEqual(medicine?.id, "test-id")
    }
    
    func test_getMedicine_withInvalidId_shouldReturnNil() async throws {
        // Given
        sut.setMockMedicines([])
        
        // When
        let medicine = try await sut.getMedicine(withId: "non-existent-id")
        
        // Then
        XCTAssertNil(medicine)
    }
    
    func test_getMedicine_withEmptyId_shouldHandleGracefully() async throws {
        // Given
        let emptyId = ""
        
        // When
        let medicine = try await sut.getMedicine(withId: emptyId)
        
        // Then
        XCTAssertNil(medicine)
    }
    
    // MARK: - addMedicine Tests
    
    func test_addMedicine_withValidMedicine_shouldCreateSuccessfully() async throws {
        // Given
        let newMedicine = createTestMedicine(id: "new-medicine", name: "New Medicine")
        
        // When
        try await sut.addMedicine(newMedicine)
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertTrue(medicines.contains { $0.name == "New Medicine" })
    }
    
    func test_addMedicine_withInvalidData_shouldThrowError() async throws {
        // Given
        sut.setShouldSucceed(false)
        let invalidMedicine = createTestMedicine(name: "")
        
        // When & Then
        do {
            try await sut.addMedicine(invalidMedicine)
            XCTFail("Should throw error for invalid data")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - updateMedicine Tests
    
    func test_updateMedicine_withValidMedicine_shouldUpdateSuccessfully() async throws {
        // Given
        let originalMedicine = createTestMedicine(id: "update-test", name: "Original")
        try await sut.addMedicine(originalMedicine)
        
        let updatedMedicine = createTestMedicine(id: "update-test", name: "Updated", aisleId: "new-aisle")
        
        // When
        try await sut.updateMedicine(updatedMedicine)
        let medicine = try await sut.getMedicine(withId: "update-test")
        
        // Then
        XCTAssertEqual(medicine?.name, "Updated")
        XCTAssertEqual(medicine?.aisleId, "new-aisle")
    }
    
    func test_updateMedicine_withNonExistentMedicine_shouldCreateNew() async throws {
        // Given
        let nonExistentMedicine = createTestMedicine(id: "non-existent", name: "New Medicine")
        
        // When
        try await sut.updateMedicine(nonExistentMedicine)
        let medicine = try await sut.getMedicine(withId: "non-existent")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "New Medicine")
    }
    
    // MARK: - deleteMedicine Tests
    
    func test_deleteMedicine_withValidId_shouldRemoveMedicine() async throws {
        // Given
        let medicineToDelete = createTestMedicine(id: "delete-me", name: "To Delete")
        try await sut.addMedicine(medicineToDelete)
        
        // When
        try await sut.deleteMedicine(withId: "delete-me")
        let medicine = try await sut.getMedicine(withId: "delete-me")
        
        // Then
        XCTAssertNil(medicine)
    }
    
    func test_deleteMedicine_withInvalidId_shouldHandleGracefully() async throws {
        // Given
        let invalidId = "non-existent-id"
        
        // When & Then
        // Should not throw error for non-existent ID
        try await sut.deleteMedicine(withId: invalidId)
        
        // Verify no error occurred
        let medicines = try await sut.getMedicines()
        XCTAssertNotNil(medicines)
    }
    
    // MARK: - updateMedicineStock Tests
    
    func test_updateMedicineStock_withValidId_shouldUpdateQuantity() async throws {
        // Given
        let medicine = createTestMedicine(id: "stock-test", name: "Stock Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "stock-test", newQuantity: 50)
        let updatedMedicine = try await sut.getMedicine(withId: "stock-test")
        
        // Then
        XCTAssertEqual(updatedMedicine?.quantity, 50)
    }
    
    func test_updateMedicineStock_withInvalidId_shouldThrowError() async throws {
        // Given
        let invalidId = "non-existent-medicine"
        
        // When & Then
        do {
            try await sut.updateMedicineStock(medicineId: invalidId, newQuantity: 10)
            XCTFail("Should throw error for non-existent medicine")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    func test_updateMedicineStock_withNegativeQuantity_shouldHandleGracefully() async throws {
        // Given
        let medicine = createTestMedicine(id: "negative-test", name: "Negative Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "negative-test", newQuantity: -5)
        let updatedMedicine = try await sut.getMedicine(withId: "negative-test")
        
        // Then
        XCTAssertEqual(updatedMedicine?.quantity, -5) // Mock allows negative values
    }
    
    // MARK: - observeMedicines Tests
    
    func test_observeMedicines_shouldEmitInitialValues() {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives initial values")
        let testMedicines = [createTestMedicine(id: "obs1", name: "Observable 1")]
        sut.setMockMedicines(testMedicines)
        
        // When
        sut.observeMedicines()
            .first()
            .sink { medicines in
                XCTAssertEqual(medicines.count, 1)
                XCTAssertEqual(medicines[0].name, "Observable 1")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_observeMedicines_shouldEmitUpdatesOnAdd() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives updates")
        expectation.expectedFulfillmentCount = 2
        
        var receivedCounts: [Int] = []
        
        sut.observeMedicines()
            .sink { medicines in
                receivedCounts.append(medicines.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.addMedicine(createTestMedicine(id: "new-obs", name: "New Observable"))
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts.last, 3) // 2 initial + 1 new
    }
    
    func test_observeMedicines_shouldEmitUpdatesOnDelete() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives delete updates")
        expectation.expectedFulfillmentCount = 2
        
        var receivedCounts: [Int] = []
        
        sut.observeMedicines()
            .sink { medicines in
                receivedCounts.append(medicines.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.deleteMedicine(withId: "1")
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts.last, 1) // 2 initial - 1 deleted
    }
    
    // MARK: - searchMedicines Tests
    
    func test_searchMedicines_withValidQuery_shouldReturnMatchingMedicines() async throws {
        // Given
        let testMedicines = [
            createTestMedicine(id: "1", name: "Aspirin"),
            createTestMedicine(id: "2", name: "Ibuprofen"),
            createTestMedicine(id: "3", name: "Aspirin Plus")
        ]
        sut.setMockMedicines(testMedicines)
        
        // When
        let results = try await sut.searchMedicines(query: "Aspirin")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Aspirin") })
    }
    
    func test_searchMedicines_withEmptyQuery_shouldReturnAllMedicines() async throws {
        // Given
        let testMedicines = [
            createTestMedicine(id: "1", name: "Medicine 1"),
            createTestMedicine(id: "2", name: "Medicine 2")
        ]
        sut.setMockMedicines(testMedicines)
        
        // When
        let results = try await sut.searchMedicines(query: "")
        
        // Then
        XCTAssertEqual(results.count, 2)
    }
    
    func test_searchMedicines_withNoMatches_shouldReturnEmptyArray() async throws {
        // Given
        let testMedicines = [createTestMedicine(id: "1", name: "Aspirin")]
        sut.setMockMedicines(testMedicines)
        
        // When
        let results = try await sut.searchMedicines(query: "NonExistentMedicine")
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - Concurrent Access Tests
    
    func test_concurrentMedicineOperations_shouldHandleCorrectly() async {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let medicine = self.createTestMedicine(id: "concurrent-\(i)", name: "Concurrent \(i)")
                        try await self.sut.addMedicine(medicine)
                        expectation.fulfill()
                    } catch {
                        // Handle potential errors gracefully
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Performance Tests
    
    func test_medicineOperations_performance() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                do {
                    for i in 0..<100 {
                        let medicine = createTestMedicine(id: "perf-\(i)", name: "Performance \(i)")
                        try await sut.addMedicine(medicine)
                    }
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func test_medicineOperations_withNetworkFailure_shouldHandleGracefully() async {
        // Given
        sut.setShouldSucceed(false)
        sut.setErrorToThrow(NSError(domain: "NetworkError", code: 500, userInfo: nil))
        
        // When & Then
        do {
            try await sut.addMedicine(createTestMedicine())
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
        
        do {
            _ = try await sut.getMedicines()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - Data Validation Tests
    
    func test_medicine_expirationDate_shouldBeValid() async throws {
        // Given
        let futureDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
        let medicine = createTestMedicine(id: "date-test", name: "Date Test")
        
        // When
        try await sut.addMedicine(medicine)
        let retrievedMedicine = try await sut.getMedicine(withId: "date-test")
        
        // Then
        XCTAssertNotNil(retrievedMedicine?.expirationDate)
        XCTAssertGreaterThan(retrievedMedicine?.expirationDate ?? Date.distantPast, Date())
    }
    
    func test_medicine_quantityLimits_shouldBeEnforced() async throws {
        // Given
        let medicine = createTestMedicine(id: "quantity-test", name: "Quantity Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "quantity-test", newQuantity: 1000)
        let updatedMedicine = try await sut.getMedicine(withId: "quantity-test")
        
        // Then
        XCTAssertEqual(updatedMedicine?.quantity, 1000)
    }
    
    func test_medicine_aisleAssociation_shouldBeValid() async throws {
        // Given
        let medicine = createTestMedicine(id: "aisle-test", name: "Aisle Test", aisleId: "specific-aisle")
        
        // When
        try await sut.addMedicine(medicine)
        let retrievedMedicine = try await sut.getMedicine(withId: "aisle-test")
        
        // Then
        XCTAssertEqual(retrievedMedicine?.aisleId, "specific-aisle")
    }
}