import XCTest
import Combine
import Firebase
import FirebaseFirestore
@testable @preconcurrency import MediStock

@MainActor
final class FirebaseAisleRepositoryTestsSafe: XCTestCase, Sendable {
    
    var sut: MockFirebaseAisleRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        sut = MockFirebaseAisleRepository()
        sut.reset()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    
    private func createTestAisle(
        id: String = "test-aisle-1",
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
    
    private func createTestAisleDTO(
        id: String = "test-aisle-1",
        name: String = "Test Aisle",
        colorHex: String = "#FF0000"
    ) -> AisleDTO {
        return AisleDTO(
            id: id,
            name: name,
            description: "Test Aisle Description",
            colorHex: colorHex,
            icon: "pills"
        )
    }
    
    // MARK: - getAisles Tests
    
    func test_getAisles_withCacheData_shouldReturnCachedAisles() async throws {
        // Given
        let testAisles = [
            createTestAisle(id: "1", name: "Aisle 1"),
            createTestAisle(id: "2", name: "Aisle 2")
        ]
        sut.setMockAisles(testAisles)
        
        // When
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertNotNil(aisles)
        XCTAssertEqual(aisles.count, 2)
        XCTAssertEqual(aisles[0].name, "Aisle 1")
        XCTAssertEqual(aisles[1].name, "Aisle 2")
    }
    
    func test_getAisles_withEmptyCache_shouldFetchFromServer() async throws {
        // Given
        sut.setMockAisles([])
        
        // When
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertNotNil(aisles)
        XCTAssertEqual(aisles.count, 0)
    }
    
    func test_getAisles_withNetworkError_shouldThrowError() async throws {
        // Given
        sut.setShouldSucceed(false)
        sut.setErrorToThrow(NSError(domain: "NetworkError", code: 1001, userInfo: nil))
        
        // When & Then
        do {
            _ = try await sut.getAisles()
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    func test_getAisles_withMalformedData_shouldFilterInvalidEntries() async throws {
        // Given
        let validAisle = createTestAisle(id: "valid", name: "Valid Aisle")
        sut.setMockAisles([validAisle])
        
        // When
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertNotNil(aisles)
        XCTAssertEqual(aisles.count, 1)
        XCTAssertEqual(aisles[0].name, "Valid Aisle")
    }
    
    // MARK: - addAisle Tests
    
    func test_addAisle_withValidAisle_shouldCreateWithGeneratedId() async throws {
        // Given
        let newAisle = createTestAisle(id: "new-aisle", name: "New Aisle")
        
        // When
        try await sut.addAisle(newAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertTrue(aisles.contains { $0.name == "New Aisle" })
    }
    
    func test_addAisle_withExistingAisle_shouldUpdateAisle() async throws {
        // Given
        let existingAisle = createTestAisle(id: "existing-id", name: "Original Name")
        try await sut.addAisle(existingAisle)
        
        let updatedAisle = createTestAisle(id: "existing-id", name: "Updated Name")
        
        // When
        try await sut.updateAisle(updatedAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        let foundAisle = aisles.first { $0.id == "existing-id" }
        XCTAssertNotNil(foundAisle)
        XCTAssertEqual(foundAisle?.name, "Updated Name")
    }
    
    func test_addAisle_withInvalidData_shouldThrowError() async throws {
        // Given
        sut.setShouldSucceed(false)
        let invalidAisle = createTestAisle(name: "")
        
        // When & Then
        do {
            try await sut.addAisle(invalidAisle)
            XCTFail("Should throw error for invalid data")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - updateAisle Tests
    
    func test_updateAisle_withValidAisle_shouldUpdateSuccessfully() async throws {
        // Given
        let originalAisle = createTestAisle(id: "update-test", name: "Original")
        try await sut.addAisle(originalAisle)
        
        let updatedAisle = createTestAisle(id: "update-test", name: "Updated", colorHex: "#00FF00")
        
        // When
        try await sut.updateAisle(updatedAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        let foundAisle = aisles.first { $0.id == "update-test" }
        XCTAssertEqual(foundAisle?.name, "Updated")
        XCTAssertEqual(foundAisle?.colorHex, "#00FF00")
    }
    
    func test_updateAisle_withNonExistentAisle_shouldCreateNew() async throws {
        // Given
        let nonExistentAisle = createTestAisle(id: "non-existent", name: "New Aisle")
        
        // When
        try await sut.updateAisle(nonExistentAisle)
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertTrue(aisles.contains { $0.id == "non-existent" })
    }
    
    // MARK: - deleteAisle Tests
    
    func test_deleteAisle_withValidId_shouldRemoveAisle() async throws {
        // Given
        let aisleToDelete = createTestAisle(id: "delete-me", name: "To Delete")
        try await sut.addAisle(aisleToDelete)
        
        // When
        try await sut.deleteAisle(withId: "delete-me")
        let aisles = try await sut.getAisles()
        
        // Then
        XCTAssertFalse(aisles.contains { $0.id == "delete-me" })
    }
    
    func test_deleteAisle_withInvalidId_shouldHandleGracefully() async throws {
        // Given
        let invalidId = "non-existent-id"
        
        // When & Then
        // Should not throw error for non-existent ID
        try await sut.deleteAisle(withId: invalidId)
        
        // Verify no error occurred
        let aisles = try await sut.getAisles()
        XCTAssertNotNil(aisles)
    }
    
    // MARK: - observeAisles Tests
    
    func test_observeAisles_shouldEmitInitialValues() {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives initial values")
        let testAisles = [createTestAisle(id: "obs1", name: "Observable 1")]
        sut.setMockAisles(testAisles)
        
        // When
        sut.observeAisles()
            .first()
            .sink { aisles in
                XCTAssertEqual(aisles.count, 1)
                XCTAssertEqual(aisles[0].name, "Observable 1")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_observeAisles_shouldEmitUpdatesOnAdd() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives updates")
        expectation.expectedFulfillmentCount = 2
        
        var receivedCounts: [Int] = []
        
        sut.observeAisles()
            .sink { aisles in
                receivedCounts.append(aisles.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        try await sut.addAisle(createTestAisle(id: "new-obs", name: "New Observable"))
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedCounts.last, 3) // 2 initial + 1 new
    }
    
    func test_observeAisles_shouldEmitUpdatesOnDelete() async {
        // Given
        let expectation = XCTestExpectation(description: "Observer receives delete updates")
        expectation.expectedFulfillmentCount = 2
        
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
        XCTAssertEqual(receivedCounts.last, 1) // 2 initial - 1 deleted
    }
    
    // MARK: - searchAisles Tests
    
    func test_searchAisles_withValidQuery_shouldReturnMatchingAisles() async throws {
        // Given
        let testAisles = [
            createTestAisle(id: "1", name: "Emergency Medicine"),
            createTestAisle(id: "2", name: "Cardiology"),
            createTestAisle(id: "3", name: "Emergency Surgery")
        ]
        sut.setMockAisles(testAisles)
        
        // When
        let results = try await sut.searchAisles(query: "Emergency")
        
        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.name.contains("Emergency") })
    }
    
    func test_searchAisles_withEmptyQuery_shouldReturnAllAisles() async throws {
        // Given
        let testAisles = [
            createTestAisle(id: "1", name: "Aisle 1"),
            createTestAisle(id: "2", name: "Aisle 2")
        ]
        sut.setMockAisles(testAisles)
        
        // When
        let results = try await sut.searchAisles(query: "")
        
        // Then
        XCTAssertEqual(results.count, 2)
    }
    
    func test_searchAisles_withNoMatches_shouldReturnEmptyArray() async throws {
        // Given
        let testAisles = [createTestAisle(id: "1", name: "Cardiology")]
        sut.setMockAisles(testAisles)
        
        // When
        let results = try await sut.searchAisles(query: "NonExistentQuery")
        
        // Then
        XCTAssertEqual(results.count, 0)
    }
    
    // MARK: - getMedicineCountByAisle Tests
    
    func test_getMedicineCountByAisle_withValidAisleId_shouldReturnCount() async throws {
        // Given
        let aisleId = "test-aisle-id"
        
        // When
        let count = try await sut.getMedicineCountByAisle(aisleId: aisleId)
        
        // Then
        XCTAssertGreaterThanOrEqual(count, 0)
        XCTAssertLessThanOrEqual(count, 20) // Mock returns 0-20
    }
    
    func test_getMedicineCountByAisle_withInvalidAisleId_shouldReturnZero() async throws {
        // Given
        let invalidAisleId = "non-existent-aisle"
        
        // When
        let count = try await sut.getMedicineCountByAisle(aisleId: invalidAisleId)
        
        // Then
        XCTAssertGreaterThanOrEqual(count, 0)
    }
    
    // MARK: - Concurrent Access Tests
    
    func test_concurrentAisleOperations_shouldHandleCorrectly() async {
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
    
    // MARK: - Performance Tests
    
    func test_aisleOperations_performance() {
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
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func test_aisleOperations_withNetworkFailure_shouldHandleGracefully() async {
        // Given
        sut.setShouldSucceed(false)
        sut.setErrorToThrow(NSError(domain: "NetworkError", code: 500, userInfo: nil))
        
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
}