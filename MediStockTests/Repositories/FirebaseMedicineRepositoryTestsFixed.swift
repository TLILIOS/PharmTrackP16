import XCTest
import Combine
import Firebase
import FirebaseFirestore
@testable @preconcurrency import MediStock

@MainActor
final class FirebaseMedicineRepositoryTestsFixed: XCTestCase, Sendable {
    
    var sut: TestableMedicineRepository!
    var mockFirestore: MockFirestore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        TestDependencyContainer.shared.reset()
        mockFirestore = MockFirestore.shared
        sut = TestDependencyContainer.shared.createMedicineRepository()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables?.removeAll()
        cancellables = nil
        sut = nil
        mockFirestore = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    
    private func createTestMedicine(
        id: String = UUID().uuidString,
        name: String = "Test Medicine",
        aisleId: String = "test-aisle"
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
    
    // MARK: - getMedicines Tests
    
    func testGetMedicinesWithData() async throws {
        // Given - MockFirestore is setup with initial data in reset()
        
        // When
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertNotNil(medicines)
        XCTAssertEqual(medicines.count, 2)
        XCTAssertEqual(medicines[0].name, "Medicine 1")
        XCTAssertEqual(medicines[1].name, "Medicine 2")
    }
    
    func testGetMedicinesWithEmptyData() async throws {
        // Given
        mockFirestore.reset()
        mockFirestore.collection("medicines") // Creates empty collection
        
        // When
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertNotNil(medicines)
        XCTAssertEqual(medicines.count, 0)
    }
    
    func testGetMedicinesWithNetworkError() async {
        // Given
        mockFirestore.shouldSucceed = false
        mockFirestore.errorToThrow = NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        
        // When & Then
        do {
            _ = try await sut.getMedicines()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "FIRFirestoreErrorDomain")
        }
    }
    
    // MARK: - getMedicine Tests
    
    func testGetMedicineWithValidId() async throws {
        // Given - Medicine with ID "1" exists in initial data
        
        // When
        let medicine = try await sut.getMedicine(withId: "1")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.id, "1")
        XCTAssertEqual(medicine?.name, "Medicine 1")
    }
    
    func testGetMedicineWithInvalidId() async throws {
        // Given
        let invalidId = "non-existent-id"
        
        // When
        let medicine = try await sut.getMedicine(withId: invalidId)
        
        // Then
        XCTAssertNil(medicine)
    }
    
    func testGetMedicineWithEmptyId() async throws {
        // Given
        let emptyId = ""
        
        // When
        let medicine = try await sut.getMedicine(withId: emptyId)
        
        // Then
        XCTAssertNil(medicine)
    }
    
    // MARK: - addMedicine Tests
    
    func testAddMedicineWithValidData() async throws {
        // Given
        let newMedicine = createTestMedicine(id: "", name: "New Medicine")
        let initialCount = try await sut.getMedicines().count
        
        // When
        try await sut.addMedicine(newMedicine)
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertEqual(medicines.count, initialCount + 1)
        XCTAssertTrue(medicines.contains { $0.name == "New Medicine" })
    }
    
    func testAddMedicineWithExistingId() async throws {
        // Given
        let existingMedicine = createTestMedicine(id: "existing-id", name: "Existing Medicine")
        
        // When
        try await sut.addMedicine(existingMedicine)
        let medicine = try await sut.getMedicine(withId: "existing-id")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "Existing Medicine")
    }
    
    func testAddMedicineWithNetworkError() async {
        // Given
        mockFirestore.shouldSucceed = false
        let medicine = createTestMedicine()
        
        // When & Then
        do {
            try await sut.addMedicine(medicine)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - updateMedicine Tests
    
    func testUpdateMedicineWithValidData() async throws {
        // Given
        let originalMedicine = createTestMedicine(id: "update-test", name: "Original Medicine")
        try await sut.addMedicine(originalMedicine)
        
        let updatedMedicine = createTestMedicine(id: "update-test", name: "Updated Medicine", aisleId: "new-aisle")
        
        // When
        try await sut.updateMedicine(updatedMedicine)
        let medicine = try await sut.getMedicine(withId: "update-test")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "Updated Medicine")
        XCTAssertEqual(medicine?.aisleId, "new-aisle")
    }
    
    func testUpdateNonExistentMedicine() async throws {
        // Given
        let nonExistentMedicine = createTestMedicine(id: "non-existent", name: "Non Existent")
        
        // When
        try await sut.updateMedicine(nonExistentMedicine)
        let medicine = try await sut.getMedicine(withId: "non-existent")
        
        // Then
        XCTAssertNotNil(medicine)
        XCTAssertEqual(medicine?.name, "Non Existent")
    }
    
    // MARK: - deleteMedicine Tests
    
    func testDeleteMedicineWithValidId() async throws {
        // Given
        let medicineToDelete = createTestMedicine(id: "delete-me", name: "To Delete")
        try await sut.addMedicine(medicineToDelete)
        
        let beforeCount = try await sut.getMedicines().count
        
        // When
        try await sut.deleteMedicine(withId: "delete-me")
        let medicine = try await sut.getMedicine(withId: "delete-me")
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertNil(medicine)
        XCTAssertEqual(medicines.count, beforeCount - 1)
    }
    
    func testDeleteNonExistentMedicine() async throws {
        // Given
        let invalidId = "non-existent-id"
        let beforeCount = try await sut.getMedicines().count
        
        // When
        try await sut.deleteMedicine(withId: invalidId)
        let medicines = try await sut.getMedicines()
        
        // Then
        XCTAssertEqual(medicines.count, beforeCount)
    }
    
    // MARK: - updateMedicineStock Tests
    
    func testUpdateMedicineStockWithValidId() async throws {
        // Given
        let medicine = createTestMedicine(id: "stock-test", name: "Stock Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "stock-test", newQuantity: 50)
        let updatedMedicine = try await sut.getMedicine(withId: "stock-test")
        
        // Then
        XCTAssertNotNil(updatedMedicine)
        XCTAssertEqual(updatedMedicine?.quantity, 50)
    }
    
    func testUpdateMedicineStockWithInvalidId() async {
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
    
    func testUpdateMedicineStockWithNegativeQuantity() async throws {
        // Given
        let medicine = createTestMedicine(id: "negative-test", name: "Negative Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "negative-test", newQuantity: -5)
        let updatedMedicine = try await sut.getMedicine(withId: "negative-test")
        
        // Then
        XCTAssertNotNil(updatedMedicine)
        XCTAssertEqual(updatedMedicine?.quantity, -5) // Mock allows negative values
    }
    
    func testUpdateMedicineStockWithZeroQuantity() async throws {
        // Given
        let medicine = createTestMedicine(id: "zero-test", name: "Zero Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "zero-test", newQuantity: 0)
        let updatedMedicine = try await sut.getMedicine(withId: "zero-test")
        
        // Then
        XCTAssertNotNil(updatedMedicine)
        XCTAssertEqual(updatedMedicine?.quantity, 0)
    }
    
    // MARK: - observeMedicines Tests
    
    func testObserveMedicinesEmitsInitialValues() {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives initial values")
        
        // When
        sut.observeMedicines()
            .first()
            .sink { medicines in
                XCTAssertEqual(medicines.count, 2)
                XCTAssertEqual(medicines[0].name, "Medicine 1")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testObserveMedicinesEmitsUpdatesOnAdd() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives updates")
        expectation.expectedFulfillmentCount = 2 // Initial + after add
        
        var receivedCounts: [Int] = []
        
        sut.observeMedicines()
            .sink { medicines in
                receivedCounts.append(medicines.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.addMedicine(createTestMedicine(id: "new-observable", name: "New Observable"))
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts.count, 2)
        XCTAssertEqual(receivedCounts[0], 2) // Initial
        XCTAssertEqual(receivedCounts[1], 3) // After add
    }
    
    func testObserveMedicinesEmitsUpdatesOnDelete() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives delete updates")
        expectation.expectedFulfillmentCount = 2 // Initial + after delete
        
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
        XCTAssertEqual(receivedCounts.count, 2)
        XCTAssertEqual(receivedCounts[0], 2) // Initial
        XCTAssertEqual(receivedCounts[1], 1) // After delete
    }
    
    func testObserveMedicinesEmitsUpdatesOnStockChange() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives stock updates")
        expectation.expectedFulfillmentCount = 2 // Initial + after stock update
        
        var receivedMedicines: [[Medicine]] = []
        
        sut.observeMedicines()
            .sink { medicines in
                receivedMedicines.append(medicines)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.updateMedicineStock(medicineId: "1", newQuantity: 100)
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedMedicines.count, 2)
        
        let updatedMedicine = receivedMedicines[1].first { $0.id == "1" }
        XCTAssertNotNil(updatedMedicine)
        XCTAssertEqual(updatedMedicine?.quantity, 100)
    }
    
    // MARK: - searchMedicines Tests
    
    func testSearchMedicinesWithValidQuery() async throws {
        // Given
        try await sut.addMedicine(createTestMedicine(id: "search1", name: "Aspirin"))
        try await sut.addMedicine(createTestMedicine(id: "search2", name: "Ibuprofen"))
        try await sut.addMedicine(createTestMedicine(id: "search3", name: "Aspirin Plus"))
        
        // When
        let results = try await sut.searchMedicines(query: "Aspirin")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Aspirin") })
    }
    
    func testSearchMedicinesWithEmptyQuery() async throws {
        // Given
        let allMedicines = try await sut.getMedicines()
        
        // When
        let results = try await sut.searchMedicines(query: "")
        
        // Then
        XCTAssertEqual(results.count, allMedicines.count)
    }
    
    func testSearchMedicinesWithNoMatches() async throws {
        // When
        let results = try await sut.searchMedicines(query: "NonExistentMedicine")
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    func testSearchMedicinesCaseInsensitive() async throws {
        // Given
        try await sut.addMedicine(createTestMedicine(id: "case-test", name: "AsPiRiN"))
        
        // When
        let results = try await sut.searchMedicines(query: "aspirin")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "AsPiRiN")
    }
    
    func testSearchMedicinesByDescription() async throws {
        // Given
        let medicineWithDescription = Medicine(
            id: "desc-test",
            name: "Test Medicine",
            aisleId: "aisle-1",
            expirationDate: Date().addingTimeInterval(86400 * 30),
            quantity: 10,
            minQuantity: 5,
            description: "Pain reliever"
        )
        try await sut.addMedicine(medicineWithDescription)
        
        // When
        let results = try await sut.searchMedicines(query: "reliever")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].id, "desc-test")
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentMedicineOperations() async {
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
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    func testConcurrentStockUpdates() async {
        // Given
        let medicine = createTestMedicine(id: "stock-concurrent", name: "Stock Concurrent")
        try await sut.addMedicine(medicine)
        
        let expectation = XCTestExpectation(description: "Concurrent stock updates")
        expectation.expectedFulfillmentCount = 5
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask {
                    do {
                        try await self.sut.updateMedicineStock(medicineId: "stock-concurrent", newQuantity: i * 10)
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Verify final state
        let finalMedicine = try await sut.getMedicine(withId: "stock-concurrent")
        XCTAssertNotNil(finalMedicine)
        XCTAssertGreaterThan(finalMedicine?.quantity ?? 0, 0)
    }
    
    // MARK: - Performance Tests
    
    func testMedicineOperationsPerformance() {
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
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    func testSearchMedicinesPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Search performance")
            
            Task {
                do {
                    _ = try await sut.searchMedicines(query: "Medicine")
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testMedicineOperationsWithNetworkFailure() async {
        // Given
        mockFirestore.shouldSucceed = false
        mockFirestore.errorToThrow = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        
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
    
    func testMedicineExpirationDate() async throws {
        // Given
        let futureDate = Date().addingTimeInterval(86400 * 365) // 1 year from now
        let medicine = Medicine(
            id: "date-test",
            name: "Date Test",
            aisleId: "aisle-1",
            expirationDate: futureDate,
            quantity: 10,
            minQuantity: 5,
            description: "Test"
        )
        
        // When
        try await sut.addMedicine(medicine)
        let retrievedMedicine = try await sut.getMedicine(withId: "date-test")
        
        // Then
        XCTAssertNotNil(retrievedMedicine)
        XCTAssertGreaterThan(retrievedMedicine?.expirationDate ?? Date.distantPast, Date())
    }
    
    func testMedicineQuantityLimits() async throws {
        // Given
        let medicine = createTestMedicine(id: "quantity-test", name: "Quantity Test")
        try await sut.addMedicine(medicine)
        
        // When
        try await sut.updateMedicineStock(medicineId: "quantity-test", newQuantity: 1000)
        let updatedMedicine = try await sut.getMedicine(withId: "quantity-test")
        
        // Then
        XCTAssertNotNil(updatedMedicine)
        XCTAssertEqual(updatedMedicine?.quantity, 1000)
    }
    
    func testMedicineAisleAssociation() async throws {
        // Given
        let medicine = createTestMedicine(id: "aisle-test", name: "Aisle Test", aisleId: "specific-aisle")
        
        // When
        try await sut.addMedicine(medicine)
        let retrievedMedicine = try await sut.getMedicine(withId: "aisle-test")
        
        // Then
        XCTAssertNotNil(retrievedMedicine)
        XCTAssertEqual(retrievedMedicine?.aisleId, "specific-aisle")
    }
    
    func testEmptyMedicineName() async throws {
        // Given
        let medicineWithEmptyName = createTestMedicine(name: "")
        
        // When
        try await sut.addMedicine(medicineWithEmptyName)
        let medicines = try await sut.getMedicines()
        
        // Then
        let foundMedicine = medicines.first { $0.name == "" }
        XCTAssertNotNil(foundMedicine)
    }
}