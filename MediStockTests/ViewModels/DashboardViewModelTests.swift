import XCTest
import Combine
@testable @preconcurrency import MediStock

@MainActor
final class DashboardViewModelTests: XCTestCase, Sendable {
    
    var sut: DashboardViewModel!
    var mockGetUserUseCase: MockGetUserUseCase!
    var mockGetMedicinesUseCase: MockGetMedicinesUseCase!
    var mockGetAislesUseCase: MockGetAislesUseCase!
    var mockGetRecentHistoryUseCase: MockGetRecentHistoryUseCase!
    var mockAppCoordinator: MockAppCoordinator!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockGetUserUseCase = MockGetUserUseCase()
        mockGetMedicinesUseCase = MockGetMedicinesUseCase()
        mockGetAislesUseCase = MockGetAislesUseCase()
        mockGetRecentHistoryUseCase = MockGetRecentHistoryUseCase()
        mockAppCoordinator = MockAppCoordinator()
        
        sut = DashboardViewModel(
            getUserUseCase: mockGetUserUseCase,
            getMedicinesUseCase: mockGetMedicinesUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            getRecentHistoryUseCase: mockGetRecentHistoryUseCase,
            appCoordinator: mockAppCoordinator
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockGetUserUseCase = nil
        mockGetMedicinesUseCase = nil
        mockGetAislesUseCase = nil
        mockGetRecentHistoryUseCase = nil
        mockAppCoordinator = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.state, .idle)
        XCTAssertNil(sut.userName)
        XCTAssertEqual(sut.totalMedicines, 0)
        XCTAssertEqual(sut.totalAisles, 0)
        XCTAssertEqual(sut.criticalStockMedicines.count, 0)
        XCTAssertEqual(sut.expiringMedicines.count, 0)
        XCTAssertEqual(sut.recentHistory.count, 0)
        XCTAssertEqual(sut.medicines.count, 0)
        XCTAssertEqual(sut.aisles.count, 0)
    }
    
    // MARK: - Published Properties Tests
    
    func testStatePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "State change through fetch")
        
        // Configure successful data
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = []
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                if case .loading = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Trigger state change
        await sut.fetchData()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testUserNamePropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "User name change through fetch")
        
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = []
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        sut.$userName
            .dropFirst()
            .sink { userName in
                if userName == "Test User" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchData()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testTotalMedicinesPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Total medicines change through fetch")
        
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        let testMedicines = [
            TestHelpers.createTestMedicine(name: "Medicine 1"),
            TestHelpers.createTestMedicine(name: "Medicine 2")
        ]
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        sut.$totalMedicines
            .dropFirst()
            .sink { totalMedicines in
                if totalMedicines == 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchData()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testCriticalStockMedicinesPropertyIsPublished() async {
        let expectation = XCTestExpectation(description: "Critical stock medicines change through fetch")
        
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        let testMedicine = TestHelpers.createTestMedicine(
            name: "Critical Medicine",
            currentQuantity: 2,
            criticalThreshold: 5
        )
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = [testMedicine]
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        sut.$criticalStockMedicines
            .dropFirst()
            .sink { medicines in
                if medicines.count == 1 && medicines.first?.name == "Critical Medicine" {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        await sut.fetchData()
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Reset State Tests
    
    func testResetState() async {
        // Given - First trigger a state change through fetchData
        mockGetUserUseCase.shouldThrowError = true
        mockGetUserUseCase.errorToThrow = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        
        await sut.fetchData()
        
        // Verify we're in error state
        if case .error = sut.state {
            // Expected
        } else {
            XCTFail("Expected error state")
        }
        
        // When
        sut.resetState()
        
        // Then
        XCTAssertEqual(sut.state, .idle)
    }
    
    // MARK: - Fetch Data Tests
    
    func testFetchData_Success() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        let testMedicines = [
            TestHelpers.createTestMedicine(name: "Medicine 1", currentQuantity: 10, criticalThreshold: 5),
            TestHelpers.createTestMedicine(name: "Medicine 2", currentQuantity: 2, criticalThreshold: 5)
        ]
        let testAisles = [
            TestHelpers.createTestAisle(id: "aisle1", name: "Aisle 1", colorHex: "#007AFF"),
            TestHelpers.createTestAisle(id: "aisle2", name: "Aisle 2", colorHex: "#007AFF")
        ]
        let testHistory = [
            TestHelpers.createTestHistoryEntry(medicineId: "1"),
            TestHelpers.createTestHistoryEntry(medicineId: "2")
        ]
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        mockGetAislesUseCase.returnAisles = testAisles
        mockGetRecentHistoryUseCase.returnHistory = testHistory
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.userName, "Test User")
        XCTAssertEqual(sut.totalMedicines, 2)
        XCTAssertEqual(sut.totalAisles, 2)
        XCTAssertEqual(sut.medicines.count, 2)
        XCTAssertEqual(sut.aisles.count, 2)
        XCTAssertEqual(sut.recentHistory.count, 2)
        
        // Critical stock should contain only Medicine 2 (quantity 2 <= threshold 5)
        XCTAssertEqual(sut.criticalStockMedicines.count, 1)
        XCTAssertEqual(sut.criticalStockMedicines.first?.name, "Medicine 2")
        
        // Verify use case calls
        XCTAssertEqual(mockGetUserUseCase.callCount, 1)
        XCTAssertEqual(mockGetMedicinesUseCase.callCount, 1)
        XCTAssertEqual(mockGetAislesUseCase.callCount, 1)
        XCTAssertEqual(mockGetRecentHistoryUseCase.callCount, 1)
        XCTAssertEqual(mockGetRecentHistoryUseCase.lastLimit, 10)
    }
    
    func testFetchData_WithUserError_ShowsError() async {
        // Given
        mockGetUserUseCase.shouldThrowError = true
        mockGetUserUseCase.errorToThrow = NSError(
            domain: "UserError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "User not found"]
        )
        
        // When
        await sut.fetchData()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("User not found"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testFetchData_WithMedicinesError_ShowsError() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.shouldThrowError = true
        mockGetMedicinesUseCase.errorToThrow = NSError(
            domain: "MedicineError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Failed to load medicines"]
        )
        
        // When
        await sut.fetchData()
        
        // Then
        if case .error(let message) = sut.state {
            XCTAssertTrue(message.contains("Failed to load medicines"))
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testFetchData_LoadingStates() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = []
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // loading then success
        
        sut.$state
            .dropFirst() // Skip initial idle
            .sink { state in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.fetchData()
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertEqual(sut.state, .success)
    }
    
    // MARK: - Critical Stock Filtering Tests
    
    func testFetchData_FiltersCriticalStock() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        let testMedicines = [
            TestHelpers.createTestMedicine(
                name: "Normal Stock",
                currentQuantity: 10,
                criticalThreshold: 5
            ),
            TestHelpers.createTestMedicine(
                name: "Critical Stock 1",
                currentQuantity: 3,
                criticalThreshold: 5
            ),
            TestHelpers.createTestMedicine(
                name: "Critical Stock 2",
                currentQuantity: 1,
                criticalThreshold: 5
            ),
            TestHelpers.createTestMedicine(
                name: "Zero Threshold",
                currentQuantity: 1,
                criticalThreshold: 0
            )
        ]
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.criticalStockMedicines.count, 2)
        
        // Should be sorted by current quantity (lowest first)
        XCTAssertEqual(sut.criticalStockMedicines[0].name, "Critical Stock 2") // quantity: 1
        XCTAssertEqual(sut.criticalStockMedicines[1].name, "Critical Stock 1") // quantity: 3
    }
    
    // MARK: - Expiring Medicines Filtering Tests
    
    func testFetchData_FiltersExpiringMedicines() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        let calendar = Calendar.current
        let today = Date()
        let tenDaysFromNow = calendar.date(byAdding: .day, value: 10, to: today)!
        let twentyDaysFromNow = calendar.date(byAdding: .day, value: 20, to: today)!
        let fortyDaysFromNow = calendar.date(byAdding: .day, value: 40, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let testMedicines = [
            TestHelpers.createTestMedicine(
                name: "Expiring Soon 1",
                expiryDate: tenDaysFromNow
            ),
            TestHelpers.createTestMedicine(
                name: "Expiring Soon 2",
                expiryDate: twentyDaysFromNow
            ),
            TestHelpers.createTestMedicine(
                name: "Not Expiring Soon",
                expiryDate: fortyDaysFromNow
            ),
            TestHelpers.createTestMedicine(
                name: "Already Expired",
                expiryDate: yesterday
            ),
            TestHelpers.createTestMedicine(
                name: "No Expiry",
                expiryDate: nil
            )
        ]
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.expiringMedicines.count, 2)
        
        // Should be sorted by expiry date (earliest first)
        XCTAssertEqual(sut.expiringMedicines[0].name, "Expiring Soon 1")
        XCTAssertEqual(sut.expiringMedicines[1].name, "Expiring Soon 2")
    }
    
    // MARK: - Cache Tests
    
    func testFetchData_UsesCacheWhenRecent() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = [TestHelpers.createTestMedicine()]
        mockGetAislesUseCase.returnAisles = [TestHelpers.createTestAisle(id: "test1", name: "Test Aisle", colorHex: "#007AFF")]
        mockGetRecentHistoryUseCase.returnHistory = []
        
        // First fetch
        await sut.fetchData()
        XCTAssertEqual(mockGetUserUseCase.callCount, 1)
        
        // When - Second fetch immediately
        await sut.fetchData()
        
        // Then - Should not call use cases again due to cache
        XCTAssertEqual(mockGetUserUseCase.callCount, 1)
        XCTAssertEqual(mockGetMedicinesUseCase.callCount, 1)
        XCTAssertEqual(mockGetAislesUseCase.callCount, 1)
        XCTAssertEqual(mockGetRecentHistoryUseCase.callCount, 1)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToMedicineDetail() {
        // Given
        let testMedicine = TestHelpers.createTestMedicine()
        var handlerCalled = false
        
        sut.navigateToMedicineDetailHandler = { medicine in
            XCTAssertEqual(medicine.id, testMedicine.id)
            handlerCalled = true
        }
        
        // When
        sut.navigateToMedicineDetail(testMedicine)
        
        // Then
        XCTAssertTrue(handlerCalled)
    }
    
    func testNavigateToMedicineList_WithCoordinator() {
        // When
        sut.navigateToMedicineList()
        
        // Then
        XCTAssertEqual(mockAppCoordinator.navigationCallCount, 1)
        XCTAssertEqual(mockAppCoordinator.lastDestination, .medicineList)
    }
    
    func testNavigateToMedicineList_WithoutCoordinator() {
        // Given
        sut = DashboardViewModel(
            getUserUseCase: mockGetUserUseCase,
            getMedicinesUseCase: mockGetMedicinesUseCase,
            getAislesUseCase: mockGetAislesUseCase,
            getRecentHistoryUseCase: mockGetRecentHistoryUseCase,
            appCoordinator: nil
        )
        
        var handlerCalled = false
        sut.navigateToMedicineListHandler = {
            handlerCalled = true
        }
        
        // When
        sut.navigateToMedicineList()
        
        // Then
        XCTAssertTrue(handlerCalled)
    }
    
    func testNavigateToAisles_WithCoordinator() {
        // When
        sut.navigateToAisles()
        
        // Then
        XCTAssertEqual(mockAppCoordinator.navigationCallCount, 1)
        XCTAssertEqual(mockAppCoordinator.lastDestination, .aisles)
    }
    
    func testNavigateToHistory_WithCoordinator() {
        // When
        sut.navigateToHistory()
        
        // Then
        XCTAssertEqual(mockAppCoordinator.navigationCallCount, 1)
        XCTAssertEqual(mockAppCoordinator.lastDestination, .history)
    }
    
    func testNavigateToCriticalStock_WithCoordinator() {
        // When
        sut.navigateToCriticalStock()
        
        // Then
        XCTAssertEqual(mockAppCoordinator.navigationCallCount, 1)
        XCTAssertEqual(mockAppCoordinator.lastDestination, .criticalStock)
    }
    
    func testNavigateToExpiringMedicines_WithCoordinator() {
        // When
        sut.navigateToExpiringMedicines()
        
        // Then
        XCTAssertEqual(mockAppCoordinator.navigationCallCount, 1)
        XCTAssertEqual(mockAppCoordinator.lastDestination, .expiringMedicines)
    }
    
    func testNavigateToAdjustStock_WithCoordinator() {
        // When
        sut.navigateToAdjustStock()
        
        // Then
        XCTAssertEqual(mockAppCoordinator.navigationCallCount, 1)
        if case .adjustStock(let medicineId) = mockAppCoordinator.lastDestination {
            XCTAssertEqual(medicineId, "")
        } else {
            XCTFail("Expected adjustStock destination")
        }
    }
    
    // MARK: - Helper Methods Tests
    
    func testGetMedicineName_ExistingMedicine() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        let testMedicine = TestHelpers.createTestMedicine(id: "med1", name: "Aspirin")
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = [testMedicine]
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        await sut.fetchData()
        
        // When
        let medicineName = sut.getMedicineName(for: "med1")
        
        // Then
        XCTAssertEqual(medicineName, "Aspirin")
    }
    
    func testGetMedicineName_NonExistentMedicine() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "Test User")
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = []
        mockGetAislesUseCase.returnAisles = []
        mockGetRecentHistoryUseCase.returnHistory = []
        
        await sut.fetchData()
        
        // When
        let medicineName = sut.getMedicineName(for: "nonexistent")
        
        // Then
        XCTAssertEqual(medicineName, "Médicament inconnu")
    }
    
    // MARK: - Complex Integration Tests
    
    func testFetchData_CompleteWorkflow() async {
        // Given
        let testUser = User(id: "1", email: "test@example.com", displayName: "John Doe")
        let calendar = Calendar.current
        let today = Date()
        let expiryDate = calendar.date(byAdding: .day, value: 15, to: today)!
        
        let testMedicines = [
            TestHelpers.createTestMedicine(
                id: "med1",
                name: "Critical Medicine",
                currentQuantity: 2,
                criticalThreshold: 5,
                expiryDate: expiryDate
            ),
            TestHelpers.createTestMedicine(
                id: "med2",
                name: "Normal Medicine",
                currentQuantity: 20,
                criticalThreshold: 5
            )
        ]
        
        let testAisles = [
            TestHelpers.createTestAisle(id: "aisle1", name: "Pharmacy", colorHex: "#007AFF"),
            TestHelpers.createTestAisle(id: "aisle2", name: "Emergency", colorHex: "#007AFF")
        ]
        
        let testHistory = [
            TestHelpers.createTestHistoryEntry(medicineId: "med1"),
            TestHelpers.createTestHistoryEntry(medicineId: "med2")
        ]
        
        mockGetUserUseCase.returnUser = testUser
        mockGetMedicinesUseCase.returnMedicines = testMedicines
        mockGetAislesUseCase.returnAisles = testAisles
        mockGetRecentHistoryUseCase.returnHistory = testHistory
        
        // When
        await sut.fetchData()
        
        // Then
        XCTAssertEqual(sut.state, .success)
        XCTAssertEqual(sut.userName, "John Doe")
        XCTAssertEqual(sut.totalMedicines, 2)
        XCTAssertEqual(sut.totalAisles, 2)
        XCTAssertEqual(sut.medicines.count, 2)
        XCTAssertEqual(sut.aisles.count, 2)
        XCTAssertEqual(sut.recentHistory.count, 2)
        
        // Critical stock
        XCTAssertEqual(sut.criticalStockMedicines.count, 1)
        XCTAssertEqual(sut.criticalStockMedicines.first?.name, "Critical Medicine")
        
        // Expiring medicines (within 30 days)
        XCTAssertEqual(sut.expiringMedicines.count, 1)
        XCTAssertEqual(sut.expiringMedicines.first?.name, "Critical Medicine")
        
        // Test helper method
        XCTAssertEqual(sut.getMedicineName(for: "med1"), "Critical Medicine")
        XCTAssertEqual(sut.getMedicineName(for: "med2"), "Normal Medicine")
        XCTAssertEqual(sut.getMedicineName(for: "unknown"), "Médicament inconnu")
    }
}

// MARK: - SearchViewModel Tests

@MainActor
final class SearchViewModelTests: XCTestCase {
    
    var sut: SearchViewModel!
    var mockSearchMedicineUseCase: MockSearchMedicineUseCase!
    var mockSearchAisleUseCase: MockSearchAisleUseCase!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        
        mockSearchMedicineUseCase = MockSearchMedicineUseCase()
        mockSearchAisleUseCase = MockSearchAisleUseCase()
        
        sut = SearchViewModel(
            searchMedicineUseCase: mockSearchMedicineUseCase,
            searchAisleUseCase: mockSearchAisleUseCase
        )
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockSearchMedicineUseCase = nil
        mockSearchAisleUseCase = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertEqual(sut.medicineResults.count, 0)
        XCTAssertEqual(sut.aisleResults.count, 0)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    // MARK: - Search Tests
    
    func testSearch_WithEmptyQuery_ClearsResults() async {
        // Given - First populate with some results
        let testMedicines = [TestHelpers.createTestMedicine()]
        let testAisles = [TestHelpers.createTestAisle(id: "test1", name: "Test Aisle", colorHex: "#007AFF")]
        
        mockSearchMedicineUseCase.returnMedicines = testMedicines
        mockSearchAisleUseCase.returnAisles = testAisles
        
        // Populate results first
        await sut.search(query: "test")
        XCTAssertEqual(sut.medicineResults.count, 1)
        XCTAssertEqual(sut.aisleResults.count, 1)
        
        // When - Search with empty query
        await sut.search(query: "")
        
        // Then
        XCTAssertEqual(sut.medicineResults.count, 0)
        XCTAssertEqual(sut.aisleResults.count, 0)
        XCTAssertEqual(mockSearchMedicineUseCase.callCount, 1) // Should only be called once for "test"
        XCTAssertEqual(mockSearchAisleUseCase.callCount, 1)
    }
    
    func testSearch_WithQuery_ReturnsResults() async {
        // Given
        let testMedicines = [TestHelpers.createTestMedicine(name: "Aspirin")]
        let testAisles = [TestHelpers.createTestAisle(id: "test1", name: "Pharmacy", colorHex: "#007AFF")]
        
        mockSearchMedicineUseCase.returnMedicines = testMedicines
        mockSearchAisleUseCase.returnAisles = testAisles
        
        // When
        await sut.search(query: "test")
        
        // Then
        XCTAssertEqual(sut.medicineResults.count, 1)
        XCTAssertEqual(sut.aisleResults.count, 1)
        XCTAssertEqual(sut.medicineResults.first?.name, "Aspirin")
        XCTAssertEqual(sut.aisleResults.first?.name, "Pharmacy")
        XCTAssertEqual(mockSearchMedicineUseCase.callCount, 1)
        XCTAssertEqual(mockSearchAisleUseCase.callCount, 1)
        XCTAssertEqual(mockSearchMedicineUseCase.lastQuery, "test")
        XCTAssertEqual(mockSearchAisleUseCase.lastQuery, "test")
    }
    
    func testSearch_WithError_SetsErrorMessage() async {
        // Given
        mockSearchMedicineUseCase.shouldThrowError = true
        mockSearchMedicineUseCase.errorToThrow = NSError(
            domain: "SearchError",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Search failed"]
        )
        
        // When
        await sut.search(query: "test")
        
        // Then
        XCTAssertEqual(sut.error, "Search failed")
        XCTAssertFalse(sut.isLoading)
    }
    
    func testSearch_LoadingStates() async {
        // Given
        let testMedicines = [TestHelpers.createTestMedicine()]
        let testAisles = [TestHelpers.createTestAisle(id: "test1", name: "Test Aisle", colorHex: "#007AFF")]
        
        mockSearchMedicineUseCase.returnMedicines = testMedicines
        mockSearchAisleUseCase.returnAisles = testAisles
        
        let loadingExpectation = XCTestExpectation(description: "Loading state changes")
        loadingExpectation.expectedFulfillmentCount = 2 // true then false
        
        sut.$isLoading
            .dropFirst() // Skip initial false
            .sink { _ in
                loadingExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        await sut.search(query: "test")
        
        // Then
        await fulfillment(of: [loadingExpectation], timeout: 2.0)
        XCTAssertFalse(sut.isLoading)
    }
}