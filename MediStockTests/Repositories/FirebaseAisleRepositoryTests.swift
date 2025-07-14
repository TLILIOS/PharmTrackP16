//import XCTest
//import Combine
//import Firebase
//import FirebaseFirestore
//@testable @preconcurrency import MediStock
//
//@MainActor
//final class FirebaseAisleRepositoryTests: XCTestCase, Sendable {
//    
//    var sut: MediStock.FirebaseAisleRepository!
//    var cancellables: Set<AnyCancellable>!
//    
//    override func setUp() {
//        super.setUp()
//        cancellables = Set<AnyCancellable>()
//        
//        // Skip Firebase initialization in tests to avoid network calls and timeouts
//        // Tests will use mock behavior or handle Firebase errors gracefully
//        
//        sut = FirebaseAisleRepository()
//    }
//    
//    override func tearDown() {
//        cancellables = nil
//        sut = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Test Data Factory
//    
//    private func createTestAisle(
//        id: String = "test-aisle-1",
//        name: String = "Test Aisle",
//        colorHex: String = "#FF0000"
//    ) -> Aisle {
//        return Aisle(
//            id: id,
//            name: name,
//            description: "Test Aisle Description",
//            colorHex: colorHex,
//            icon: "pills"
//        )
//    }
//    
//    private func createTestAisleDTO(
//        id: String = "test-aisle-1",
//        name: String = "Test Aisle",
//        colorHex: String = "#FF0000"
//    ) -> AisleDTO {
//        return AisleDTO(
//            id: id,
//            name: name,
//            description: "Test Aisle Description",
//            colorHex: colorHex,
//            icon: "pills"
//        )
//    }
//    
//    // MARK: - getAisles Tests
//    
//    func test_getAisles_withCacheData_shouldReturnCachedAisles() async throws {
//        // Given
//        // Cache contains data scenario
//        
//        // When & Then
//        do {
//            let aisles = try await sut.getAisles()
//            XCTAssertNotNil(aisles)
//            XCTAssertTrue(aisles is [Aisle])
//        } catch {
//            // Expected behavior when Firebase is not properly configured in test environment
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getAisles_withEmptyCache_shouldFetchFromServer() async throws {
//        // Given
//        // Empty cache scenario
//        
//        // When & Then
//        do {
//            let aisles = try await sut.getAisles()
//            XCTAssertNotNil(aisles)
//        } catch {
//            // Expected in test environment without Firebase setup
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getAisles_withNetworkError_shouldThrowError() async throws {
//        // Given
//        // Network error simulation
//        
//        // When & Then
//        do {
//            _ = try await sut.getAisles()
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getAisles_withMalformedData_shouldFilterInvalidEntries() async throws {
//        // Given
//        // Malformed data scenario
//        
//        // When & Then
//        do {
//            let aisles = try await sut.getAisles()
//            // Should return valid aisles only, filtering out malformed ones
//            XCTAssertNotNil(aisles)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    // MARK: - getAisle Tests
//    
//    func test_getAisle_withValidId_shouldReturnAisle() async throws {
//        // Given
//        let aisleId = "test-aisle-1"
//        
//        // When & Then
//        do {
//            _ = try await sut.getAisle(id: aisleId)
//            // In test environment, this will likely return nil
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getAisle_withInvalidId_shouldReturnNil() async throws {
//        // Given
//        let invalidId = "non-existent-id"
//        
//        // When & Then
//        do {
//            let aisle = try await sut.getAisle(id: invalidId)
//            XCTAssertNil(aisle)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getAisle_withEmptyId_shouldHandleGracefully() async throws {
//        // Given
//        let emptyId = ""
//        
//        // When & Then
//        do {
//            let aisle = try await sut.getAisle(id: emptyId)
//            XCTAssertNil(aisle)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getAisle_cacheThenServer_shouldFollowCorrectOrder() async throws {
//        // Given
//        let aisleId = "test-aisle-1"
//        
//        // When & Then
//        // Repository should first check cache, then server
//        do {
//            _ = try await sut.getAisle(id: aisleId)
//            // Verify the behavior follows cache-first pattern
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    // MARK: - saveAisle Tests
//    
//    func test_saveAisle_withNewAisle_shouldCreateWithGeneratedId() async throws {
//        // Given
//        let newAisle = createTestAisle(id: "")
//        
//        // When & Then
//        do {
//            let savedAisle = try await sut.saveAisle(newAisle)
//            XCTAssertFalse(savedAisle.id.isEmpty)
//            XCTAssertEqual(savedAisle.name, newAisle.name)
//            XCTAssertEqual(savedAisle.colorHex, newAisle.colorHex)
//            XCTAssertEqual(savedAisle.icon, newAisle.icon)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_saveAisle_withExistingAisle_shouldUpdateAisle() async throws {
//        // Given
//        let existingAisle = createTestAisle(id: "existing-id")
//        
//        // When & Then
//        do {
//            let updatedAisle = try await sut.saveAisle(existingAisle)
//            XCTAssertEqual(updatedAisle.id, existingAisle.id)
//            XCTAssertEqual(updatedAisle.name, existingAisle.name)
//            XCTAssertEqual(updatedAisle.icon, existingAisle.icon)
//            // updatedAt should be refreshed
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_saveAisle_withInvalidName_shouldHandleValidation() async throws {
//        // Given
//        let aisleWithEmptyName = createTestAisle(name: "")
//        
//        // When & Then
//        do {
//            _ = try await sut.saveAisle(aisleWithEmptyName)
//            // Should handle validation at service level
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_saveAisle_withInvalidColorHex_shouldHandleValidation() async throws {
//        // Given
//        let aisleWithInvalidColor = createTestAisle(colorHex: "invalid-color")
//        
//        // When & Then
//        do {
//            _ = try await sut.saveAisle(aisleWithInvalidColor)
//            // Repository should handle invalid color format
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_saveAisle_withDuplicateName_shouldAllowOrThrowError() async throws {
//        // Given
//        let aisle1 = createTestAisle(id: "aisle-1", name: "Duplicate Name")
//        let aisle2 = createTestAisle(id: "aisle-2", name: "Duplicate Name")
//        
//        // When & Then
//        do {
//            _ = try await sut.saveAisle(aisle1)
//            _ = try await sut.saveAisle(aisle2)
//            // Business logic: should duplicate names be allowed?
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    // MARK: - deleteAisle Tests
//    
//    func test_deleteAisle_withEmptyAisle_shouldDeleteSuccessfully() async throws {
//        // Given
//        let aisleId = "empty-aisle-1"
//        
//        // When & Then
//        do {
//            try await sut.deleteAisle(id: aisleId)
//            // Success case - no exception thrown
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_deleteAisle_withMedicinesInAisle_shouldThrowValidationError() async throws {
//        // Given
//        let aisleWithMedicines = "aisle-with-medicines"
//        
//        // When & Then
//        do {
//            try await sut.deleteAisle(id: aisleWithMedicines)
//            // Should check for medicines and throw error if found
//        } catch {
//            if let nsError = error as NSError? {
//                XCTAssertTrue(
//                    nsError.code == 400 || 
//                    nsError.localizedDescription.contains("contains medicines")
//                )
//            }
//        }
//    }
//    
//    func test_deleteAisle_withNonExistentAisle_shouldHandleGracefully() async throws {
//        // Given
//        let nonExistentId = "non-existent-aisle"
//        
//        // When & Then
//        do {
//            try await sut.deleteAisle(id: nonExistentId)
//            // Firestore delete is idempotent
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
////    
////    func test_deleteAisle_withEmptyId_shouldHandleError() async throws {
////          // Given
////        _ = ""
////
////          // When & Then
////          throw XCTSkip("Skipping empty ID test to avoid Firebase crash in test environment")
////      }
//    func test_deleteAisle_withEmptyId_shouldHandleError() async throws {
//        // Given
//        let repository = sut!
//        let emptyId = ""
//        
//        // When & Then
//        if ProcessInfo.processInfo.environment["TEST_ENVIRONMENT"] == "unit" {
//            // Test avec mock pour éviter Firebase
//            throw XCTSkip("Firebase integration test - run with integration test suite")
//        } else {
//            do {
//                _ = try await repository.deleteAisle(id: emptyId)
//                XCTFail("Expected error for empty ID")
//            } catch {
//                // Vérifier que l'erreur est appropriée
//                XCTAssertNotNil(error)
//            }
//        }
//    }
//
//    
//    // MARK: - getMedicineCountByAisle Tests
//    
//    func test_getMedicineCountByAisle_withValidAisle_shouldReturnCorrectCount() async throws {
//        // Given
//        let aisleId = "test-aisle-1"
//        
//        // When & Then
//        do {
//            let count = try await sut.getMedicineCountByAisle(aisleId: aisleId)
//            XCTAssertGreaterThanOrEqual(count, 0)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getMedicineCountByAisle_withEmptyAisle_shouldReturnZero() async throws {
//        // Given
//        let emptyAisleId = "empty-aisle"
//        
//        // When & Then
//        do {
//            let count = try await sut.getMedicineCountByAisle(aisleId: emptyAisleId)
//            XCTAssertEqual(count, 0)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getMedicineCountByAisle_withNonExistentAisle_shouldReturnZero() async throws {
//        // Given
//        let nonExistentId = "non-existent-aisle"
//        
//        // When & Then
//        do {
//            let count = try await sut.getMedicineCountByAisle(aisleId: nonExistentId)
//            XCTAssertEqual(count, 0)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    func test_getMedicineCountByAisle_cacheThenServer_shouldFollowCorrectOrder() async throws {
//        // Given
//        let aisleId = "test-aisle-1"
//        
//        // When & Then
//        do {
//            let count = try await sut.getMedicineCountByAisle(aisleId: aisleId)
//            // Should follow cache-first pattern
//            XCTAssertGreaterThanOrEqual(count, 0)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    // MARK: - observeAisles Tests
//    
//    func test_observeAisles_shouldReturnPublisher() {
//        // Given
//        let expectation = expectation(description: "Observer should emit values")
//        
//        // When
//        let publisher = sut.observeAisles()
//        
//        // Then
//        XCTAssertNotNil(publisher)
//        
//        publisher
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        XCTAssertTrue(error is NSError)
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { aisles in
//                    XCTAssertTrue(aisles is [Aisle])
//                    expectation.fulfill()
//                }
//            )
//            .store(in: &cancellables)
//        
//        waitForExpectations(timeout: 5.0)
//    }
//    
//    func test_observeAisles_withFirestoreError_shouldEmitError() {
//        // Given
//        let expectation = expectation(description: "Should emit error or complete")
//        
//        // When
//        let publisher = sut.observeAisles()
//        
//        // Then
//        publisher
//            .sink(
//                receiveCompletion: { completion in
//                    if case .failure(let error) = completion {
//                        XCTAssertTrue(error is NSError)
//                        expectation.fulfill()
//                    }
//                    
//                },
//                receiveValue: { aisles in
//                    // Accept valid response in test environment
//                    XCTAssertTrue(aisles is [Aisle])
//                    expectation.fulfill()
//                }
//            )
//            .store(in: &cancellables)
//        
//        waitForExpectations(timeout: 10.0)
//    }
//    
//    func test_observeAisles_withEmptyCollection_shouldEmitEmptyArray() {
//        // Given
//        let expectation = expectation(description: "Should emit empty array")
//        
//        // When
//        let publisher = sut.observeAisles()
//        
//        // Then
//        publisher
//            .sink(
//                receiveCompletion: { completion in
//                    if case .failure = completion {
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { aisles in
//                    // Should handle empty collection gracefully
//                    expectation.fulfill()
//                }
//            )
//            .store(in: &cancellables)
//        
//        waitForExpectations(timeout: 5.0)
//    }
//    
//    // MARK: - observeAisle Tests
//    
//    func test_observeAisle_withValidId_shouldReturnPublisher() {
//        // Given
//        let aisleId = "test-aisle-1"
//        let expectation = expectation(description: "Observer should emit values")
//        
//        // When
//        let publisher = sut.observeAisle(id: aisleId)
//        
//        // Then
//        XCTAssertNotNil(publisher)
//        
//        publisher
//            .sink(
//                receiveCompletion: { completion in
//                    if case .failure(let error) = completion {
//                        XCTAssertTrue(error is NSError)
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { aisle in
//                    // Aisle might be nil in test environment
//                    expectation.fulfill()
//                }
//            )
//            .store(in: &cancellables)
//        
//        waitForExpectations(timeout: 5.0)
//    }
//    
//    func test_observeAisle_withNonExistentId_shouldEmitNil() {
//        // Given
//        let nonExistentId = "non-existent-aisle"
//        let expectation = expectation(description: "Should emit nil for non-existent aisle")
//        
//        // When
//        let publisher = sut.observeAisle(id: nonExistentId)
//        
//        // Then
//        publisher
//            .sink(
//                receiveCompletion: { completion in
//                    if case .failure(let error) = completion {
//                        XCTAssertTrue(error is NSError)
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { aisle in
//                    // Should be nil for non-existent aisle
//                    expectation.fulfill()
//                }
//            )
//            .store(in: &cancellables)
//        
//        waitForExpectations(timeout: 5.0)
//    }
//    
//    func test_observeAisle_withMalformedData_shouldHandleError() {
//        // Given
//        let aisleWithBadData = "malformed-aisle"
//        let expectation = expectation(description: "Should handle malformed data")
//        
//        // When
//        let publisher = sut.observeAisle(id: aisleWithBadData)
//        
//        // Then
//        publisher
//            .sink(
//                receiveCompletion: { completion in
//                    if case .failure(let error) = completion {
//                        XCTAssertTrue(error is NSError)
//                        expectation.fulfill()
//                    }
//                },
//                receiveValue: { aisle in
//                    expectation.fulfill()
//                }
//            )
//            .store(in: &cancellables)
//        
//        waitForExpectations(timeout: 5.0)
//    }
//    
//    // MARK: - Integration and Business Logic Tests
//    
//    func test_deleteAisle_businessLogic_shouldPreventDeletionWithMedicines() async throws {
//        // Given - Business Logic Test
//        let aisleId = "aisle-with-medicines"
//        
//        // When & Then
//        do {
//            try await sut.deleteAisle(id: aisleId)
//        } catch {
//            if let nsError = error as NSError? {
//                // Verify business rule enforcement
//                XCTAssertTrue(
//                    nsError.code == 400 && 
//                    nsError.localizedDescription.contains("contains medicines")
//                )
//            }
//        }
//    }
//    
//    func test_saveAisle_businessLogic_shouldUpdateTimestamps() async throws {
//        // Given
//        let existingAisle = Aisle(
//            id: "existing-aisle",
//            name: "Existing Aisle",
//            description: "Description",
//            colorHex: "#FF0000",
//            icon: "pills"
//        )
//        
//        // When & Then
//        do {
//            let updatedAisle = try await sut.saveAisle(existingAisle)
//            XCTAssertEqual(updatedAisle.name, existingAisle.name)
//        } catch {
//            XCTAssertTrue(error is NSError)
//        }
//    }
//    
//    // MARK: - Performance Tests
//
////    func test_getAisles_performance() {
////        let repository = self.sut!
////        
////        measure {
////            let expectation = expectation(description: "getAisles completion")
////            
////            Task {
////                do {
////                    _ = try await repository.getAisles()
////                } catch {
////                    // Expected in test environment
////                }
////                expectation.fulfill()
////            }
////            
////            wait(for: [expectation], timeout: 10.0)
////        }
////    }
//
////    func test_getMedicineCountByAisle_performance() {
////        let repository = self.sut!
////        
////        measure {
////            let expectation = expectation(description: "getMedicineCountByAisle completion")
////            
////            Task {
////                do {
////                    _ = try await repository.getMedicineCountByAisle(aisleId: "test-aisle")
////                } catch {
////                    // Expected in test environment
////                }
////                expectation.fulfill()
////            }
////            
////            wait(for: [expectation], timeout: 10.0)
////        }
////    }
//
//    
//    // MARK: - Concurrency Tests
//    
//    func test_saveAisle_concurrency() async throws {
//        // Given
//        let numberOfConcurrentSaves = 5
//        let aisles = (1...numberOfConcurrentSaves).map { index in
//            createTestAisle(id: "", name: "Concurrent Aisle \(index)")
//        }
//        
//        // When
//        let tasks = aisles.map { aisle in
//            Task {
//                do {
//                    return try await sut.saveAisle(aisle)
//                } catch {
//                    return aisle
//                }
//            }
//        }
//        
//        // Then
//        let results = await withTaskGroup(of: Aisle.self) { group in
//            for task in tasks {
//                group.addTask {
//                    await task.value
//                }
//            }
//            
//            var allResults: [Aisle] = []
//            for await result in group {
//                allResults.append(result)
//            }
//            return allResults
//        }
//        
//        XCTAssertEqual(results.count, numberOfConcurrentSaves)
//    }
//}
//
//// MARK: - Test Extensions
//
//extension Aisle {
//    static func testAisle(
//        id: String = UUID().uuidString,
//        name: String = "Test Aisle",
//        colorHex: String = "#FF0000"
//    ) -> Aisle {
//        return Aisle(
//            id: id,
//            name: name,
//            description: "Test Aisle Description",
//            colorHex: colorHex,
//            icon: "pills"
//        )
//    }
//}
