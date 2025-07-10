import XCTest
@testable import MediStock

@MainActor
final class DashboardViewModelTests: XCTestCase {
    
    var sut: DashboardViewModel!
    var mockGetUserUseCase: MockGetUserUseCase!
    var mockGetMedicinesUseCase: MockGetMedicinesUseCase!
    var mockGetAislesUseCase: MockGetAislesUseCase!
    var mockGetRecentHistoryUseCase: MockGetRecentHistoryUseCase!
    
    override func setUp() {
        super.setUp()
        mockGetUserUseCase = MockGetUserUseCase()
        mockGetMedicinesUseCase = MockGetMedicinesUseCase()
        mockGetAislesUseCase = MockGetAislesUseCase()
        mockGetRecentHistoryUseCase = MockGetRecentHistoryUseCase()
        
        sut = DashboardViewModel(
            getUserUseCase: mockGetUserUseCase,
            getMedicinesUseCase: mockGetMedicinesUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            getRecentHistoryUseCase: mockGetRecentHistoryUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockGetUserUseCase = nil
        mockGetMedicinesUseCase = nil
        mockGetAislesUseCase = nil
        mockGetRecentHistoryUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertNil(sut.userName)
        XCTAssertEqual(sut.totalMedicines, 0)
        XCTAssertEqual(sut.totalAisles, 0)
        XCTAssertTrue(sut.criticalStockMedicines.isEmpty)
        XCTAssertTrue(sut.expiringMedicines.isEmpty)
        XCTAssertTrue(sut.recentHistory.isEmpty)
        XCTAssertTrue(sut.medicines.isEmpty)
        XCTAssertTrue(sut.aisles.isEmpty)
    }
    
    // MARK: - Reset State Tests
    
    func testResetState() {
        // Given
        sut.state = .error("Some error")
        
        // When
        sut.resetState()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Fetch Data Tests
    
    func testFetchData_Success() async {
        // Given
        let user = TestDataFactory.createTestUser(name: "John Doe")
        let medicines = TestDataFactory.createMultipleMedicines(count: 5)
        let aisles = TestDataFactory.createMultipleAisles(count: 3)
        let history = TestDataFactory.createMultipleHistoryEntries(count: 10)
        
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.medicines = medicines
        mockGetAislesUseCase.aisles = aisles
        mockGetRecentHistoryUseCase.historyEntries = history
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.userName, "John Doe")
        XCTAssertEqual(sut.totalMedicines, 5)
        XCTAssertEqual(sut.totalAisles, 3)
        XCTAssertEqual(sut.medicines.count, 5)
        XCTAssertEqual(sut.aisles.count, 3)
        XCTAssertEqual(sut.recentHistory.count, 10)
    }
    
    func testFetchData_Failure() async {
        // Given
        mockGetUserUseCase.shouldThrowError = true
        let expectedError = "Failed to get user"
        mockGetUserUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.state, .error("Erreur lors du chargement des données: \(expectedError)"))
        XCTAssertNil(sut.userName)
        XCTAssertEqual(sut.totalMedicines, 0)
    }
    
    func testFetchData_LoadingState() async {
        // Given
        let user = TestDataFactory.createTestUser()
        mockGetUserUseCase.user = user
        mockGetUserUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.fetchData()
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertEqual(sut.state, .loading)
        
        await task.value
        
        // Then
        XCTAssertEqual(sut.state, .success)
    }
    
    // MARK: - Critical Stock Filtering Tests
    
    func testFetchData_CriticalStockFiltering() async {
        // Given
        let user = TestDataFactory.createTestUser()
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", currentQuantity: 5, criticalThreshold: 10), // Critical
            TestDataFactory.createTestMedicine(id: "2", currentQuantity: 15, criticalThreshold: 10), // Not critical
            TestDataFactory.createTestMedicine(id: "3", currentQuantity: 2, criticalThreshold: 5), // Critical
            TestDataFactory.createTestMedicine(id: "4", currentQuantity: 0, criticalThreshold: 0) // No threshold
        ]
        
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.medicines = medicines
        mockGetAislesUseCase.aisles = []
        mockGetRecentHistoryUseCase.historyEntries = []
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.criticalStockMedicines.count, 2)
        XCTAssertEqual(sut.criticalStockMedicines[0].id, "3") // Sorted by lowest quantity first
        XCTAssertEqual(sut.criticalStockMedicines[1].id, "1")
    }
    
    // MARK: - Expiring Medicines Filtering Tests
    
    func testFetchData_ExpiringMedicinesFiltering() async {
        // Given
        let user = TestDataFactory.createTestUser()
        let today = Date()
        let calendar = Calendar.current
        
        let medicines = [
            TestDataFactory.createTestMedicine(id: "1", expiryDate: calendar.date(byAdding: .day, value: 10, to: today)), // Expiring soon
            TestDataFactory.createTestMedicine(id: "2", expiryDate: calendar.date(byAdding: .day, value: 40, to: today)), // Not expiring soon
            TestDataFactory.createTestMedicine(id: "3", expiryDate: calendar.date(byAdding: .day, value: 5, to: today)), // Expiring sooner
            TestDataFactory.createTestMedicine(id: "4", expiryDate: calendar.date(byAdding: .day, value: -5, to: today)), // Already expired
            TestDataFactory.createTestMedicine(id: "5", expiryDate: nil) // No expiry date
        ]
        
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.medicines = medicines
        mockGetAislesUseCase.aisles = []
        mockGetRecentHistoryUseCase.historyEntries = []
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.expiringMedicines.count, 2)
        XCTAssertEqual(sut.expiringMedicines[0].id, "3") // Sorted by expiry date
        XCTAssertEqual(sut.expiringMedicines[1].id, "1")
    }
    
    // MARK: - Cache Tests
    
    func testFetchData_CacheExpiration() async {
        // Given
        let user = TestDataFactory.createTestUser()
        let medicines = TestDataFactory.createMultipleMedicines(count: 3)
        let aisles = TestDataFactory.createMultipleAisles(count: 2)
        
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.medicines = medicines
        mockGetAislesUseCase.aisles = aisles
        mockGetRecentHistoryUseCase.historyEntries = []
        
        // First fetch
        await sut.fetchData()
        XCTAssertEqual(mockGetUserUseCase.callCount, 1)
        
        // Second fetch immediately (should use cache)
        await sut.fetchData()
        XCTAssertEqual(mockGetUserUseCase.callCount, 1) // Should not increase
        
        // Wait for cache expiration and fetch again
        // Note: In real implementation, we would need to simulate time passage
        // For now, we test the cache logic with empty data scenario
        sut.medicines = [] // Simulate empty data to trigger fresh fetch
        await sut.fetchData()
        XCTAssertEqual(mockGetUserUseCase.callCount, 2)
    }
    
    // MARK: - Navigation Handler Tests
    
    func testNavigateToMedicineDetail() {
        // Given
        let medicine = TestDataFactory.createTestMedicine()
        var capturedMedicine: Medicine?
        sut.navigateToMedicineDetailHandler = { medicine in
            capturedMedicine = medicine
        }
        
        // When
        sut.navigateToMedicineDetail(medicine)
        
        // Then
        XCTAssertEqual(capturedMedicine?.id, medicine.id)
    }
    
    func testNavigateToMedicineList() {
        // Given
        var navigateCalled = false
        sut.navigateToMedicineListHandler = {
            navigateCalled = true
        }
        
        // When
        sut.navigateToMedicineList()
        
        // Then
        XCTAssertTrue(navigateCalled)
    }
    
    func testNavigateToAisles() {
        // Given
        var navigateCalled = false
        sut.navigateToAislesHandler = {
            navigateCalled = true
        }
        
        // When
        sut.navigateToAisles()
        
        // Then
        XCTAssertTrue(navigateCalled)
    }
    
    func testNavigateToHistory() {
        // Given
        var navigateCalled = false
        sut.navigateToHistoryHandler = {
            navigateCalled = true
        }
        
        // When
        sut.navigateToHistory()
        
        // Then
        XCTAssertTrue(navigateCalled)
    }
    
    func testNavigateToCriticalStock() {
        // Given
        var navigateCalled = false
        sut.navigateToCriticalStockHandler = {
            navigateCalled = true
        }
        
        // When
        sut.navigateToCriticalStock()
        
        // Then
        XCTAssertTrue(navigateCalled)
    }
    
    func testNavigateToExpiringMedicines() {
        // Given
        var navigateCalled = false
        sut.navigateToExpiringMedicinesHandler = {
            navigateCalled = true
        }
        
        // When
        sut.navigateToExpiringMedicines()
        
        // Then
        XCTAssertTrue(navigateCalled)
    }
    
    func testNavigateToAdjustStock() {
        // Given
        var navigateCalled = false
        sut.navigateToAdjustStockHandler = {
            navigateCalled = true
        }
        
        // When
        sut.navigateToAdjustStock()
        
        // Then
        XCTAssertTrue(navigateCalled)
    }
    
    // MARK: - Helper Methods Tests
    
    func testGetMedicineName_ExistingMedicine() async {
        // Given
        let medicine = TestDataFactory.createTestMedicine(id: "test-id", name: "Test Medicine")
        mockGetUserUseCase.user = TestDataFactory.createTestUser()
        mockGetMedicinesUseCase.medicines = [medicine]
        mockGetAislesUseCase.aisles = []
        mockGetRecentHistoryUseCase.historyEntries = []
        
        await sut.fetchData()
        
        // When
        let medicineName = sut.getMedicineName(for: "test-id")
        
        // Then
        XCTAssertEqual(medicineName, "Test Medicine")
    }
    
    func testGetMedicineName_NonExistingMedicine() async {
        // Given
        mockGetUserUseCase.user = TestDataFactory.createTestUser()
        mockGetMedicinesUseCase.medicines = []
        mockGetAislesUseCase.aisles = []
        mockGetRecentHistoryUseCase.historyEntries = []
        
        await sut.fetchData()
        
        // When
        let medicineName = sut.getMedicineName(for: "non-existing-id")
        
        // Then
        XCTAssertEqual(medicineName, "Médicament inconnu")
    }
    
    // MARK: - Edge Cases Tests
    
    func testFetchData_EmptyCollections() async {
        // Given
        let user = TestDataFactory.createTestUser()
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.medicines = []
        mockGetAislesUseCase.aisles = []
        mockGetRecentHistoryUseCase.historyEntries = []
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.totalMedicines, 0)
        XCTAssertEqual(sut.totalAisles, 0)
        XCTAssertTrue(sut.criticalStockMedicines.isEmpty)
        XCTAssertTrue(sut.expiringMedicines.isEmpty)
        XCTAssertTrue(sut.recentHistory.isEmpty)
    }
    
    func testFetchData_PartialFailure() async {
        // Given
        let user = TestDataFactory.createTestUser()
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.shouldThrowError = true
        let expectedError = "Failed to get medicines"
        mockGetMedicinesUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.state, .error("Erreur lors du chargement des données: \(expectedError)"))
    }
    
    // MARK: - History Limit Tests
    
    func testFetchData_HistoryLimit() async {
        // Given
        let user = TestDataFactory.createTestUser()
        let history = TestDataFactory.createMultipleHistoryEntries(count: 15)
        
        mockGetUserUseCase.user = user
        mockGetMedicinesUseCase.medicines = []
        mockGetAislesUseCase.aisles = []
        mockGetRecentHistoryUseCase.historyEntries = history
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(mockGetRecentHistoryUseCase.lastLimit, 10)
        XCTAssertEqual(sut.recentHistory.count, 15) // Should return all provided entries
    }
}

// MARK: - SearchViewModel Tests

@MainActor
final class SearchViewModelTests: XCTestCase {
    
    var sut: SearchViewModel!
    var mockSearchMedicineUseCase: MockSearchMedicineUseCase!
    var mockSearchAisleUseCase: MockSearchAisleUseCase!
    
    override func setUp() {
        super.setUp()
        mockSearchMedicineUseCase = MockSearchMedicineUseCase()
        mockSearchAisleUseCase = MockSearchAisleUseCase()
        
        sut = SearchViewModel(
            searchMedicineUseCase: mockSearchMedicineUseCase,
            searchAisleUseCase: mockSearchAisleUseCase
        )
    }
    
    override func tearDown() {
        sut = nil
        mockSearchMedicineUseCase = nil
        mockSearchAisleUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertTrue(sut.medicineResults.isEmpty)
        XCTAssertTrue(sut.aisleResults.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Search Tests
    
    func testSearch_Success() async {
        // Given
        let medicines = TestDataFactory.createMultipleMedicines(count: 3)
        let aisles = TestDataFactory.createMultipleAisles(count: 2)
        mockSearchMedicineUseCase.medicines = medicines
        mockSearchAisleUseCase.aisles = aisles
        
        // When
        await sut.search(query: "test")
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
        XCTAssertEqual(sut.medicineResults.count, 3)
        XCTAssertEqual(sut.aisleResults.count, 2)
        XCTAssertEqual(mockSearchMedicineUseCase.lastQuery, "test")
        XCTAssertEqual(mockSearchAisleUseCase.lastQuery, "test")
    }
    
    func testSearch_EmptyQuery() async {
        // Given
        mockSearchMedicineUseCase.medicines = TestDataFactory.createMultipleMedicines(count: 3)
        mockSearchAisleUseCase.aisles = TestDataFactory.createMultipleAisles(count: 2)
        
        // When
        await sut.search(query: "")
        
        // Then
        XCTAssertTrue(sut.medicineResults.isEmpty)
        XCTAssertTrue(sut.aisleResults.isEmpty)
        XCTAssertEqual(mockSearchMedicineUseCase.callCount, 0)
        XCTAssertEqual(mockSearchAisleUseCase.callCount, 0)
    }
    
    func testSearch_Failure() async {
        // Given
        mockSearchMedicineUseCase.shouldThrowError = true
        let expectedError = "Search failed"
        mockSearchMedicineUseCase.errorToThrow = NSError(
            domain: "TestError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: expectedError]
        )
        
        // When
        await sut.search(query: "test")
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.error, expectedError)
        XCTAssertTrue(sut.medicineResults.isEmpty)
        XCTAssertTrue(sut.aisleResults.isEmpty)
    }
    
    func testSearch_LoadingState() async {
        // Given
        mockSearchMedicineUseCase.medicines = []
        mockSearchAisleUseCase.aisles = []
        mockSearchMedicineUseCase.delayNanoseconds = 50_000_000 // 50ms delay
        
        // When
        let task = Task {
            await sut.search(query: "test")
        }
        
        // Give the task a moment to start
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        // Check loading state
        XCTAssertTrue(sut.isLoading)
        XCTAssertNil(sut.error)
        
        await task.value
        
        // Then
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSearch_ConcurrentSearches() async {
        // Given
        mockSearchMedicineUseCase.medicines = TestDataFactory.createMultipleMedicines(count: 2)
        mockSearchAisleUseCase.aisles = TestDataFactory.createMultipleAisles(count: 1)
        
        // When - Perform concurrent searches
        async let search1 = sut.search(query: "query1")
        async let search2 = sut.search(query: "query2")
        
        await search1
        await search2
        
        // Then
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(mockSearchMedicineUseCase.callCount, 2)
        XCTAssertEqual(mockSearchAisleUseCase.callCount, 2)
    }
}