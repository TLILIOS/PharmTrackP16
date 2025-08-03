import XCTest
@testable import MediStock

@MainActor
final class AisleRepositoryTests: XCTestCase {
    
    private var repository: AisleRepository!
    private var mockDataService: MockDataServiceAdapterForAisleTests!
    
    override func setUp() {
        super.setUp()
        mockDataService = MockDataServiceAdapterForAisleTests()
        repository = AisleRepository(dataService: mockDataService)
    }
    
    override func tearDown() {
        repository = nil
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - Test: Fetch Aisles with Firebase Error
    
    func testFetchAislesWithFirebaseError() async throws {
        // Given
        mockDataService.shouldThrowError = true
        mockDataService.errorToThrow = AuthError.networkError
        
        // When/Then
        do {
            _ = try await repository.fetchAisles()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
    
    // MARK: - Test: Save Aisle with Network Timeout
    
    func testSaveAisleWithNetworkTimeout() async throws {
        // Given
        let aisle = Aisle(
            id: UUID().uuidString,
            name: "Test Aisle",
            description: "Test Description",
            colorHex: "#0080FF",
            icon: "pills"
        )
        
        mockDataService.shouldThrowError = true
        mockDataService.errorToThrow = AuthError.networkError
        mockDataService.operationDelay = 5.0 // Simulate timeout
        
        // When/Then
        do {
            _ = try await repository.saveAisle(aisle)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is AuthError)
        }
    }
    
    // MARK: - Test: Delete Aisle with Dependencies
    
    func testDeleteAisleWithDependencies() async throws {
        // Given
        let aisleId = "aisle-with-dependencies"
        
        // Configure mock to simulate aisle with medicines
        mockDataService.mockAisles = [
            Aisle(id: aisleId, name: "Pharmacy Aisle", description: "Has medicines", colorHex: "#FF0000", icon: "cross.case")
        ]
        mockDataService.shouldThrowError = true
        mockDataService.errorToThrow = ValidationError.aisleContainsMedicines(count: 3)
        
        // When/Then
        do {
            try await repository.deleteAisle(id: aisleId)
            XCTFail("Expected error - aisle has dependencies")
        } catch {
            XCTAssertTrue(error is ValidationError)
            if case ValidationError.aisleContainsMedicines(let count) = error {
                XCTAssertEqual(count, 3)
            } else {
                XCTFail("Expected aisleContainsMedicines error")
            }
        }
    }
    
    // MARK: - Test: Concurrent Aisle Operations
    
    func testConcurrentAisleOperations() async throws {
        // Given
        let aisles = (0..<10).map { index in
            Aisle(
                id: "concurrent-\(index)",
                name: "Aisle \(index)",
                description: "Description \(index)",
                colorHex: "#0080FF",
                icon: "pills"
            )
        }
        
        mockDataService.shouldSimulateConcurrency = true
        mockDataService.concurrentOperations = []
        
        // When: Execute multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            // Add save operations
            for aisle in aisles {
                group.addTask {
                    do {
                        _ = try await self.repository.saveAisle(aisle)
                    } catch {
                        XCTFail("Save operation failed: \(error)")
                    }
                }
            }
            
            // Add fetch operations
            for _ in 0..<5 {
                group.addTask {
                    do {
                        _ = try await self.repository.fetchAisles()
                    } catch {
                        XCTFail("Fetch operation failed: \(error)")
                    }
                }
            }
            
            // Add delete operations with slight delay to ensure saves complete first
            for i in 0..<3 {
                group.addTask {
                    do {
                        // Small delay to increase likelihood saves complete first
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                        try await self.repository.deleteAisle(id: "concurrent-\(i)")
                    } catch {
                        XCTFail("Delete operation failed: \(error)")
                    }
                }
            }
        }
        
        // Then: Verify all operations completed successfully
        let operations = mockDataService.concurrentOperations
        
        // Verify operation counts
        let saveCount = operations.filter { $0.contains("save") }.count
        let fetchCount = operations.filter { $0.contains("fetch") }.count
        let deleteCount = operations.filter { $0.contains("delete") }.count
        
        XCTAssertEqual(saveCount, 10, "Expected 10 save operations")
        XCTAssertEqual(fetchCount, 5, "Expected 5 fetch operations")
        XCTAssertEqual(deleteCount, 3, "Expected 3 delete operations")
        
        // Verify thread safety - no operations should be dropped
        XCTAssertEqual(operations.count, 18, "Expected 18 total operations")
        
        // Verify data consistency after concurrent operations
        let finalAisles = mockDataService.mockAisles
        
        // Debug: Print remaining aisle IDs
        let remainingIds = finalAisles.map { $0.id }.sorted()
        print("Remaining aisle IDs: \(remainingIds)")
        
        // Count how many aisles remain
        // Since operations are concurrent, we cannot guarantee exact order
        // But we should have between 7-10 aisles (depending on timing)
        XCTAssertGreaterThanOrEqual(finalAisles.count, 7, "Should have at least 7 aisles")
        XCTAssertLessThanOrEqual(finalAisles.count, 10, "Should have at most 10 aisles")
        
        // If we have exactly 7, check that the right ones were deleted
        if finalAisles.count == 7 {
            let expectedDeleted = ["concurrent-0", "concurrent-1", "concurrent-2"]
            for deletedId in expectedDeleted {
                XCTAssertFalse(remainingIds.contains(deletedId), "Aisle \(deletedId) should have been deleted")
            }
        }
    }
    
    // MARK: - Test: Paginated Fetch with Edge Cases
    
    func testFetchAislesPaginatedEdgeCases() async throws {
        // Test 1: Empty result
        mockDataService.mockAisles = []
        var result = try await repository.fetchAislesPaginated(limit: 20, refresh: true)
        XCTAssertTrue(result.isEmpty, "Expected empty result for no aisles")
        
        // Test 2: Exactly limit items
        mockDataService.mockAisles = (0..<20).map { index in
            Aisle(id: "\(index)", name: "Aisle \(index)", description: "", colorHex: "#0080FF", icon: "pills")
        }
        result = try await repository.fetchAislesPaginated(limit: 20, refresh: false)
        XCTAssertEqual(result.count, 20, "Expected exactly 20 items")
        
        // Test 3: More than limit items (should only return limit)
        mockDataService.mockAisles = (0..<30).map { index in
            Aisle(id: "\(index)", name: "Aisle \(index)", description: "", colorHex: "#0080FF", icon: "pills")
        }
        result = try await repository.fetchAislesPaginated(limit: 20, refresh: false)
        XCTAssertEqual(result.count, 20, "Expected only 20 items when more available")
        
        // Test 4: Invalid limit (negative or zero)
        do {
            _ = try await repository.fetchAislesPaginated(limit: 0, refresh: false)
            XCTFail("Expected error for invalid limit")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

// MARK: - Mock Data Service Adapter

final class MockDataServiceAdapterForAisleTests: DataServiceAdapter, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: Error?
    var operationDelay: TimeInterval = 0
    var mockAisles: [Aisle] = []
    var shouldSimulateConcurrency = false
    var concurrentOperations: [String] = []
    private let operationQueue = DispatchQueue(label: "mock.operations", attributes: .concurrent)
    
    override func getAisles() async throws -> [Aisle] {
        if shouldSimulateConcurrency {
            await withCheckedContinuation { continuation in
                operationQueue.async(flags: .barrier) {
                    self.concurrentOperations.append("fetch-\(Date().timeIntervalSince1970)")
                    continuation.resume()
                }
            }
        }
        
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        return mockAisles
    }
    
    override func getAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        if limit <= 0 {
            throw ValidationError.invalidId
        }
        
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        let endIndex = min(limit, mockAisles.count)
        return Array(mockAisles.prefix(endIndex))
    }
    
    override func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        if operationDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(operationDelay * 1_000_000_000))
        }
        
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        await withCheckedContinuation { continuation in
            operationQueue.async(flags: .barrier) {
                // Do both operations atomically
                if self.shouldSimulateConcurrency {
                    self.concurrentOperations.append("save-\(aisle.id)")
                }
                
                // Remove existing aisle with same ID before adding
                self.mockAisles.removeAll { $0.id == aisle.id }
                self.mockAisles.append(aisle)
                continuation.resume()
            }
        }
        
        return aisle
    }
    
    override func deleteAisle(_ aisle: Aisle) async throws {
        try await deleteAisle(id: aisle.id)
    }
    
    override func deleteAisle(id: String) async throws {
        if shouldThrowError, let error = errorToThrow {
            throw error
        }
        
        await withCheckedContinuation { continuation in
            operationQueue.async(flags: .barrier) {
                // Do both operations atomically
                if self.shouldSimulateConcurrency {
                    self.concurrentOperations.append("delete-\(id)")
                }
                
                // Ensure the deletion actually happens
                let countBefore = self.mockAisles.count
                self.mockAisles.removeAll { $0.id == id }
                let countAfter = self.mockAisles.count
                
                // Debug output
                if countBefore == countAfter {
                    print("Warning: Delete operation for id '\(id)' did not remove any aisle")
                }
                
                continuation.resume()
            }
        }
    }
}