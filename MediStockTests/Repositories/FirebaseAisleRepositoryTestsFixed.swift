import XCTest
import Combine
import Firebase
import FirebaseFirestore
@testable @preconcurrency import MediStock

@MainActor
final class FirebaseAisleRepositoryTestsFixed: XCTestCase, Sendable {
    
    var sut: TestableAisleRepository!
    var mockFirestore: MockFirestore!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        TestDependencyContainer.shared.reset()
        mockFirestore = MockFirestore.shared
        sut = TestDependencyContainer.shared.createAisleRepository()
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
    
    private func createTestAisle(
        id: String = UUID().uuidString,
        name: String = "Test Aisle",
        colorHex: String = "#FF0000"
    ) -> Aisle {
        return Aisle(
            id: id,
            name: name,
            description: "Test Aisle Description",
            colorHex: colorHex,
            icon: "pills"
        )
    }
    
    // MARK: - getAisles Tests
    
    func testGetAislesWithData() async throws {
        // Given - MockFirestore is setup with initial data in reset()
        
        // When
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertNotNil(aisles)
        XCTAssertEqual(aisles.count, 2)
        XCTAssertEqual(aisles[0].name, "Aisle 1")
        XCTAssertEqual(aisles[1].name, "Aisle 2")
    }
    
    func testGetAislesWithEmptyData() async throws {
        // Given
        mockFirestore.reset()
        mockFirestore.collection("aisles") // Creates empty collection
        
        // When
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertNotNil(aisles)
        XCTAssertEqual(aisles.count, 0)
    }
    
    func testGetAislesWithNetworkError() async {
        // Given
        mockFirestore.shouldSucceed = false
        mockFirestore.errorToThrow = NSError(domain: "FIRFirestoreErrorDomain", code: 14, userInfo: nil)
        
        // When & Then
        do {
            _ = try await sut.getAisles()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "FIRFirestoreErrorDomain")
        }
    }
    
    // MARK: - addAisle Tests
    
    func testAddAisleWithValidData() async throws {
        // Given
        let newAisle = createTestAisle(id: "", name: "New Aisle")
        let initialCount = try await sut.getAisles().count
        
        // When
        try await sut.addAisle(newAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertEqual(aisles.count, initialCount + 1)
        XCTAssertTrue(aisles.contains { $0.name == "New Aisle" })
    }
    
    func testAddAisleWithExistingId() async throws {
        // Given
        let existingAisle = createTestAisle(id: "existing-id", name: "Existing Aisle")
        
        // When
        try await sut.addAisle(existingAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertTrue(aisles.contains { $0.name == "Existing Aisle" })
    }
    
    func testAddAisleWithNetworkError() async {
        // Given
        mockFirestore.shouldSucceed = false
        let aisle = createTestAisle()
        
        // When & Then
        do {
            try await sut.addAisle(aisle)
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - updateAisle Tests
    
    func testUpdateAisleWithValidData() async throws {
        // Given
        let originalAisle = createTestAisle(id: "update-test", name: "Original Name")
        try await sut.addAisle(originalAisle)
        
        let updatedAisle = createTestAisle(id: "update-test", name: "Updated Name", colorHex: "#00FF00")
        
        // When
        try await sut.updateAisle(updatedAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        let foundAisle = aisles.first { $0.id == "update-test" }
        XCTAssertNotNil(foundAisle)
        XCTAssertEqual(foundAisle?.name, "Updated Name")
        XCTAssertEqual(foundAisle?.colorHex, "#00FF00")
    }
    
    func testUpdateNonExistentAisle() async throws {
        // Given
        let nonExistentAisle = createTestAisle(id: "non-existent", name: "Non Existent")
        
        // When
        try await sut.updateAisle(nonExistentAisle)
        let aisles = try await sut.getAisles()
        
        // Then - Mock should handle this gracefully
        let foundAisle = aisles.first { $0.id == "non-existent" }
        XCTAssertNotNil(foundAisle)
    }
    
    // MARK: - deleteAisle Tests
    
    func testDeleteAisleWithValidId() async throws {
        // Given
        let aisleToDelete = createTestAisle(id: "delete-me", name: "To Delete")
        try await sut.addAisle(aisleToDelete)
        
        let beforeCount = try await sut.getAisles().count
        
        // When
        try await sut.deleteAisle(withId: "delete-me")
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertEqual(aisles.count, beforeCount - 1)
        XCTAssertFalse(aisles.contains { $0.id == "delete-me" })
    }
    
    func testDeleteNonExistentAisle() async throws {
        // Given
        let invalidId = "non-existent-id"
        let beforeCount = try await sut.getAisles().count
        
        // When
        try await sut.deleteAisle(withId: invalidId)
        let aisles = try await sut.getAisles()
        
        // Then - Should not affect count
        XCTAssertEqual(aisles.count, beforeCount)
    }
    
    // MARK: - observeAisles Tests
    
    func testObserveAislesEmitsInitialValues() {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives initial values")
        
        // When
        sut.observeAisles()
            .first()
            .sink { aisles in
                XCTAssertEqual(aisles.count, 2)
                XCTAssertEqual(aisles[0].name, "Aisle 1")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testObserveAislesEmitsUpdatesOnAdd() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives updates")
        expectation.expectedFulfillmentCount = 2 // Initial + after add
        
        var receivedCounts: [Int] = []
        
        sut.observeAisles()
            .sink { aisles in
                receivedCounts.append(aisles.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.addAisle(createTestAisle(id: "new-observable", name: "New Observable"))
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts.count, 2)
        XCTAssertEqual(receivedCounts[0], 2) // Initial
        XCTAssertEqual(receivedCounts[1], 3) // After add
    }
    
    func testObserveAislesEmitsUpdatesOnDelete() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives delete updates")
        expectation.expectedFulfillmentCount = 2 // Initial + after delete
        
        var receivedCounts: [Int] = []
        
        sut.observeAisles()
            .sink { aisles in
                receivedCounts.append(aisles.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.deleteAisle(withId: "1")
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts.count, 2)
        XCTAssertEqual(receivedCounts[0], 2) // Initial
        XCTAssertEqual(receivedCounts[1], 1) // After delete
    }
    
    // MARK: - searchAisles Tests
    
    func testSearchAislesWithValidQuery() async throws {
        // Given
        try await sut.addAisle(createTestAisle(id: "search1", name: "Emergency Medicine"))
        try await sut.addAisle(createTestAisle(id: "search2", name: "Cardiology"))
        try await sut.addAisle(createTestAisle(id: "search3", name: "Emergency Surgery"))
        
        // When
        let results = try await sut.searchAisles(query: "Emergency")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Emergency") })
    }
    
    func testSearchAislesWithEmptyQuery() async throws {
        // Given
        let allAisles = try await sut.getAisles()
        
        // When
        let results = try await sut.searchAisles(query: "")
        
        // Then
        XCTAssertEqual(results.count, allAisles.count)
    }
    
    func testSearchAislesWithNoMatches() async throws {
        // When
        let results = try await sut.searchAisles(query: "NonExistentQuery")
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    func testSearchAislesCaseInsensitive() async throws {
        // Given
        try await sut.addAisle(createTestAisle(id: "case-test", name: "CaRdIoLoGy"))
        
        // When
        let results = try await sut.searchAisles(query: "cardiology")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "CaRdIoLoGy")
    }
    
    // MARK: - getMedicineCountByAisle Tests
    
    func testGetMedicineCountByAisleWithValidId() async throws {
        // Given
        let aisleId = "test-aisle-id"
        
        // When
        let count = try await sut.getMedicineCountByAisle(aisleId: aisleId)
        
        // Then
        XCTAssertGreaterThanOrEqual(count, 0)
        XCTAssertLessThanOrEqual(count, 10) // Mock returns 0-10
    }
    
    func testGetMedicineCountByAisleWithInvalidId() async throws {
        // Given
        let invalidAisleId = "non-existent-aisle"
        
        // When
        let count = try await sut.getMedicineCountByAisle(aisleId: invalidAisleId)
        
        // Then
        XCTAssertGreaterThanOrEqual(count, 0)
    }
    
    // MARK: - Concurrent Operations Tests
    
    func testConcurrentAisleOperations() async {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    do {
                        let aisle = self.createTestAisle(id: "concurrent-\(i)", name: "Concurrent \(i)")
                        try await self.sut.addAisle(aisle)
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
    
    func testConcurrentReadOperations() async {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        expectation.expectedFulfillmentCount = 10
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    do {
                        _ = try await self.sut.getAisles()
                        expectation.fulfill()
                    } catch {
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testAisleOperationsPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            Task {
                do {
                    for i in 0..<100 {
                        let aisle = createTestAisle(id: "perf-\(i)", name: "Performance \(i)")
                        try await sut.addAisle(aisle)
                    }
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 3.0)
        }
    }
    
    func testGetAislesPerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Get aisles performance")
            
            Task {
                do {
                    _ = try await sut.getAisles()
                    expectation.fulfill()
                } catch {
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 1.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testAisleOperationsWithNetworkFailure() async {
        // Given
        mockFirestore.shouldSucceed = false
        mockFirestore.errorToThrow = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        
        // When & Then
        do {
            try await sut.addAisle(createTestAisle())
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
        
        do {
            _ = try await sut.getAisles()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    func testErrorRecovery() async throws {
        // Given
        mockFirestore.shouldSucceed = false
        
        // When - First operation fails
        do {
            try await sut.addAisle(createTestAisle())
            XCTFail("Should throw error")
        } catch {
            // Expected
        }
        
        // When - Recovery
        mockFirestore.shouldSucceed = true
        
        // Then - Second operation succeeds
        try await sut.addAisle(createTestAisle(name: "Recovery Test"))
        let aisles = try await sut.getAisles()
        XCTAssertTrue(aisles.contains { $0.name == "Recovery Test" })
    }
    
    // MARK: - Data Validation Tests
    
    func testAisleDataValidation() async throws {
        // Given
        let aisle = createTestAisle(id: "validation-test", name: "Valid Aisle")
        
        // When
        try await sut.addAisle(aisle)
        let retrievedAisles = try await sut.getAisles()
        let retrievedAisle = retrievedAisles.first { $0.id == "validation-test" }
        
        // Then
        XCTAssertNotNil(retrievedAisle)
        XCTAssertEqual(retrievedAisle?.name, "Valid Aisle")
        XCTAssertEqual(retrievedAisle?.colorHex, "#FF0000")
        XCTAssertEqual(retrievedAisle?.icon, "pills")
        XCTAssertNotNil(retrievedAisle?.description)
    }
    
    func testEmptyAisleName() async throws {
        // Given
        let aisleWithEmptyName = createTestAisle(name: "")
        
        // When
        try await sut.addAisle(aisleWithEmptyName)
        let aisles = try await sut.getAisles()
        
        // Then - Mock should handle empty names gracefully
        let foundAisle = aisles.first { $0.name == "" }
        XCTAssertNotNil(foundAisle)
    }
}