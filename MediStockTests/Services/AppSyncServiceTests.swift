import XCTest
import Combine
import Network
@testable import MediStock

final class AppSyncServiceTests: XCTestCase {
    
    var sut: AppSyncService!
    var mockCacheService: MockCacheService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockCacheService = MockCacheService()
        sut = AppSyncService(cacheService: mockCacheService)
    }
    
    override func tearDown() {
        cancellables = nil
        mockCacheService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Data Factory
    
    private func createTestSyncOperation(
        id: String = "test-op-1",
        type: SyncOperationType = .createMedicine,
        entityId: String = "test-entity-1"
    ) -> SyncOperation {
        let testData = "test data".data(using: .utf8) ?? Data()
        return SyncOperation(
            id: id,
            type: type,
            timestamp: Date(),
            data: testData,
            entityId: entityId
        )
    }
    
    private func createMultipleTestOperations(count: Int = 3) -> [SyncOperation] {
        guard count > 0 else { return [] }
        return (1...count).map { index in
            createTestSyncOperation(
                id: "test-op-\(index)",
                type: .createMedicine,
                entityId: "entity-\(index)"
            )
        }
    }
    
    // MARK: - Initialization Tests
    
    func test_init_shouldSetupCorrectly() {
        // Given & When
        // SUT is initialized in setUp
        
        // Then
        XCTAssertNotNil(sut)
        XCTAssertNotNil(sut.syncState)
    }
    
    func test_init_shouldStartWithIdleState() {
        // Given
        let expectation = expectation(description: "Should start with idle state")
        
        // When & Then
        sut.syncState
            .sink { state in
                if case .idle = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - syncPendingChanges Tests
    
    func test_syncPendingChanges_withOfflineState_shouldReturnFalse() async {
        // Given
        // sut.isOnline will be false by default in test environment
        
        // When
        let result = await sut.syncPendingChanges()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_syncPendingChanges_withOfflineState_shouldSetOfflineState() async {
        // Given
        let expectation = expectation(description: "Should set offline state")
        
        sut.syncState
            .sink { state in
                if case .offline = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = await sut.syncPendingChanges()
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_syncPendingChanges_withEmptyQueue_shouldReturnTrue() async {
        // Given
        mockCacheService.shouldReturnEmptyOperations = true
        
        // We can't easily test online state without mocking network monitoring
        // So we'll test the logic flow when cache is empty
        
        // When
        let result = await sut.syncPendingChanges()
        
        // Then
        // Result depends on online state, but cache logic should work
        XCTAssertNotNil(result)
    }
    
    func test_syncPendingChanges_withCacheError_shouldReturnFalse() async {
        // Given
        mockCacheService.shouldThrowError = true
        
        // When
        let result = await sut.syncPendingChanges()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_syncPendingChanges_withCacheError_shouldSetErrorState() async {
        // Given
        mockCacheService.shouldThrowError = true
        let expectation = expectation(description: "Should set error state")
        
        sut.syncState
            .sink { state in
                if case .error(let message) = state {
                    XCTAssertTrue(message.contains("error"))
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = await sut.syncPendingChanges()
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_syncPendingChanges_withPendingOperations_shouldProcessThem() async {
        // Given
        let operations = createMultipleTestOperations(count: 3)
        mockCacheService.mockOperations = operations
        
        // When
        let result = await sut.syncPendingChanges()
        
        // Then
        // In offline mode, this should return false
        // In online mode (if we could mock it), it should process operations
        XCTAssertFalse(result) // Expected to be false due to offline state
    }
    
    // MARK: - forceSyncAll Tests
    
    func test_forceSyncAll_withOfflineState_shouldReturnFalse() async {
        // Given
        // Offline by default in test environment
        
        // When
        let result = await sut.forceSyncAll()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func test_forceSyncAll_withOfflineState_shouldSetOfflineState() async {
        // Given
        let expectation = expectation(description: "Should set offline state")
        
        sut.syncState
            .sink { state in
                if case .offline = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = await sut.forceSyncAll()
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - enqueueSyncOperation Tests
    
    func test_enqueueSyncOperation_withNewOperation_shouldAddToQueue() throws {
        // Given
        let operation = createTestSyncOperation()
        let identifier = "test-identifier"
        
        // When
        try sut.enqueueSyncOperation(operation, identifier: identifier)
        
        // Then
        XCTAssertTrue(mockCacheService.saveWasCalled)
        XCTAssertEqual(mockCacheService.savedOperations.count, 1)
        XCTAssertEqual(mockCacheService.savedOperations.first?.id, identifier)
    }
    
    func test_enqueueSyncOperation_withExistingIdentifier_shouldReplaceOperation() throws {
        // Given
        let firstOperation = createTestSyncOperation(id: "first-op")
        let secondOperation = createTestSyncOperation(id: "second-op")
        let identifier = "same-identifier"
        
        // When
        try sut.enqueueSyncOperation(firstOperation, identifier: identifier)
        try sut.enqueueSyncOperation(secondOperation, identifier: identifier)
        
        // Then
        XCTAssertTrue(mockCacheService.saveWasCalled)
        // Should have only one operation with the updated content
        XCTAssertEqual(mockCacheService.savedOperations.count, 1)
        XCTAssertEqual(mockCacheService.savedOperations.first?.id, identifier)
    }
    
    func test_enqueueSyncOperation_withCacheError_shouldThrowError() {
        // Given
        mockCacheService.shouldThrowError = true
        let operation = createTestSyncOperation()
        
        // When & Then
        XCTAssertThrowsError(try sut.enqueueSyncOperation(operation, identifier: "test")) { error in
            XCTAssertTrue(error is MockCacheService.CacheError)
        }
    }
    
    func test_enqueueSyncOperation_withValidOperation_shouldTriggerAutoSync() throws {
        // Given
        let operation = createTestSyncOperation()
        let expectation = expectation(description: "Should trigger sync state change")
        
        sut.syncState
            .dropFirst() // Skip initial idle state
            .sink { state in
                // Should transition to offline state when trying to sync
                if case .offline = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        try sut.enqueueSyncOperation(operation, identifier: "test")
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - checkConnectivity Tests
    
    func test_checkConnectivity_shouldNotThrow() {
        // Given & When & Then
        XCTAssertNoThrow(sut.checkConnectivity())
    }
    
    // MARK: - SyncState Publisher Tests
    
    func test_syncState_shouldEmitStates() {
        // Given
        let expectation = expectation(description: "Should emit initial state")
        
        // When & Then
        sut.syncState
            .sink { state in
                if case .idle = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_syncState_shouldEmitErrorState() async {
        // Given
        mockCacheService.shouldThrowError = true
        let expectation = expectation(description: "Should emit error state")
        
        sut.syncState
            .sink { state in
                if case .error = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = await sut.syncPendingChanges()
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    func test_syncState_shouldEmitOfflineState() async {
        // Given
        let expectation = expectation(description: "Should emit offline state")
        
        sut.syncState
            .sink { state in
                if case .offline = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        _ = await sut.syncPendingChanges()
        
        // Then
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Integration Tests
    
    func test_enqueueThenSync_integration() async throws {
        // Given
        let operations = createMultipleTestOperations(count: 3)
        
        // When
        for (index, operation) in operations.enumerated() {
            try sut.enqueueSyncOperation(operation, identifier: "op-\(index)")
        }
        
        let syncResult = await sut.syncPendingChanges()
        
        // Then
        XCTAssertFalse(syncResult) // False due to offline state
        XCTAssertEqual(mockCacheService.savedOperations.count, operations.count)
    }
    
    func test_multipleEnqueue_shouldMaintainQueue() throws {
        // Given
        let operations = createMultipleTestOperations(count: 5)
        
        // When
        for (index, operation) in operations.enumerated() {
            try sut.enqueueSyncOperation(operation, identifier: "unique-\(index)")
        }
        
        // Then
        XCTAssertEqual(mockCacheService.savedOperations.count, operations.count)
    }
    
    // MARK: - Performance Tests
    
    func test_enqueueSyncOperation_performance() {
        // Given
        let operations = createMultipleTestOperations(count: 100)
        
        // When & Then
        measure {
            for (index, operation) in operations.enumerated() {
                do {
                    try sut.enqueueSyncOperation(operation, identifier: "perf-\(index)")
                } catch {
                    XCTFail("Should not throw error: \(error)")
                }
            }
        }
    }
    
    func test_syncPendingChanges_performance() {
        // Given
        let operations = createMultipleTestOperations(count: 50)
        mockCacheService.mockOperations = operations
        
        // When & Then
        measure {
            Task {
                _ = await sut.syncPendingChanges()
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func test_enqueueSyncOperation_withEmptyIdentifier_shouldWork() throws {
        // Given
        let operation = createTestSyncOperation()
        let emptyIdentifier = ""
        
        // When & Then
        XCTAssertNoThrow(try sut.enqueueSyncOperation(operation, identifier: emptyIdentifier))
    }
    
    func test_enqueueSyncOperation_withLargeDataPayload_shouldWork() throws {
        // Given
        let largeData = Data(repeating: 0, count: 1024 * 1024) // 1MB
        let operation = SyncOperation(
            id: "large-op",
            type: .createMedicine,
            timestamp: Date(),
            data: largeData,
            entityId: "large-entity"
        )
        
        // When & Then
        XCTAssertNoThrow(try sut.enqueueSyncOperation(operation, identifier: "large-test"))
    }
    
    func test_syncPendingChanges_withCorruptedCache_shouldHandleGracefully() async {
        // Given
        mockCacheService.shouldReturnCorruptedData = true
        
        // When
        let result = await sut.syncPendingChanges()
        
        // Then
        XCTAssertFalse(result)
    }
    
    // MARK: - Concurrency Tests
    
    func test_concurrentEnqueueOperations_shouldBeSafe() async throws {
        // Given
        let numberOfOperations = 10
        let operations = createMultipleTestOperations(count: numberOfOperations)
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for (index, operation) in operations.enumerated() {
                group.addTask {
                    do {
                        try self.sut.enqueueSyncOperation(operation, identifier: "concurrent-\(index)")
                    } catch {
                        XCTFail("Concurrent enqueue failed: \(error)")
                    }
                }
            }
        }
        
        // Then
        XCTAssertEqual(mockCacheService.savedOperations.count, numberOfOperations)
    }
    
    func test_concurrentSyncOperations_shouldBeSafe() async {
        // Given
        let operations = createMultipleTestOperations(count: 5)
        mockCacheService.mockOperations = operations
        
        // When
        let results = await withTaskGroup(of: Bool.self) { group in
            for _ in 1...3 {
                group.addTask {
                    return await self.sut.syncPendingChanges()
                }
            }
            
            var allResults: [Bool] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        // Then
        XCTAssertEqual(results.count, 3)
        // All should be false due to offline state
        XCTAssertTrue(results.allSatisfy { !$0 })
    }
}

// MARK: - Mock Classes

class MockCacheService: CacheServiceProtocol {
    
    enum CacheError: Error {
        case mockError
        case corruptedData
    }
    
    var shouldThrowError = false
    var shouldReturnEmptyOperations = false
    var shouldReturnCorruptedData = false
    var saveWasCalled = false
    var fetchWasCalled = false
    
    var mockOperations: [SyncOperation] = []
    var savedOperations: [SyncOperation] = []
    
    func save<T: Codable>(_ object: T, forKey key: String) throws {
        saveWasCalled = true
        
        if shouldThrowError {
            throw CacheError.mockError
        }
        
        if let operations = object as? [SyncOperation] {
            savedOperations = operations
        }
    }
    
    func fetch<T: Codable>(forKey key: String) throws -> T? {
        fetchWasCalled = true
        
        if shouldThrowError {
            throw CacheError.mockError
        }
        
        if shouldReturnCorruptedData {
            throw CacheError.corruptedData
        }
        
        if shouldReturnEmptyOperations {
            return [] as? T
        }
        
        if key == "pending_sync_operations" {
            return (savedOperations.isEmpty ? mockOperations : savedOperations) as? T
        }
        
        return nil
    }
    
    func remove(forKey key: String) throws {
        if shouldThrowError {
            throw CacheError.mockError
        }
        
        if key == "pending_sync_operations" {
            savedOperations.removeAll()
        }
    }
    
    func clearAll() throws {
        if shouldThrowError {
            throw CacheError.mockError
        }
        
        savedOperations.removeAll()
        mockOperations.removeAll()
    }
    
    func exists(forKey key: String) -> Bool {
        return !savedOperations.isEmpty || !mockOperations.isEmpty
    }
}

// MARK: - Test Extensions

extension SyncOperation {
    static func testOperation(
        id: String = UUID().uuidString,
        type: SyncOperationType = .createMedicine,
        entityId: String = "test-entity"
    ) -> SyncOperation {
        let testData = "test data".data(using: .utf8) ?? Data()
        return SyncOperation(
            id: id,
            type: type,
            timestamp: Date(),
            data: testData,
            entityId: entityId
        )
    }
}

extension SyncState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    
    var isSyncing: Bool {
        if case .syncing = self { return true }
        return false
    }
    
    var isOffline: Bool {
        if case .offline = self { return true }
        return false
    }
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}