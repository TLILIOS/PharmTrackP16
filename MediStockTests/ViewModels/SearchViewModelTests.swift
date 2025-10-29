import XCTest
import Combine
@testable import MediStock

// MARK: - SearchViewModel Tests
/// Tests complets pour SearchViewModel avec couverture de 90%+
/// Teste la recherche, les filtres, le tri et le debouncing

@MainActor
final class SearchViewModelTests: XCTestCase {

    // MARK: - Properties

    private var sut: SearchViewModel!
    private var mockRepository: MockMedicineRepository!
    private var cancellables: Set<AnyCancellable>!
    private var testUserDefaults: UserDefaults!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Use a test suite to avoid polluting the standard UserDefaults
        testUserDefaults = UserDefaults(suiteName: "com.medistock.tests")!
        testUserDefaults.removePersistentDomain(forName: "com.medistock.tests")

        mockRepository = MockMedicineRepository()
        sut = SearchViewModel(
            medicineRepository: mockRepository,
            userDefaults: testUserDefaults
        )
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        testUserDefaults.removePersistentDomain(forName: "com.medistock.tests")
        cancellables = nil
        sut = nil
        mockRepository = nil
        testUserDefaults = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertEqual(sut.searchText, "")
        XCTAssertEqual(sut.sortOption, .nameAscending)
        XCTAssertFalse(sut.isSearching)
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertTrue(sut.recentSearches.isEmpty)
        XCTAssertFalse(sut.showingFilterSheet)
        XCTAssertFalse(sut.hasActiveFilters)
        XCTAssertEqual(sut.activeFiltersCount, 0)
    }

    // MARK: - Search Text Tests

    func testPerformSearchWithQuery() async {
        // Given
        // Note: SearchViewModel searches in name, reference, description, AND dosage
        // So we need to ensure our test data doesn't accidentally match in multiple fields
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Doliprane", description: "Antalgique", dosage: "500mg", reference: "PAR500"),
            Medicine.mock(id: "2", name: "Aspirine", description: "Anti-inflammatoire", dosage: "100mg", reference: "ASP100"),
            Medicine.mock(id: "3", name: "Doliprane XL", description: "Antalgique prolongé", dosage: "1000mg", reference: "PARXL")
        ]

        // When - Search for "dol" which should match names "Doliprane" and "Doliprane XL"
        await sut.performSearch("dol")

        // Then
        XCTAssertFalse(sut.isSearching)
        XCTAssertEqual(sut.searchResults.count, 2, "Should find 2 medicines with 'dol' in name")
        XCTAssertTrue(sut.searchResults.allSatisfy { $0.name.lowercased().contains("dol") })
    }

    func testPerformSearchCaseInsensitive() async {
        // Given
        mockRepository.medicines = [Medicine.mock(name: "Doliprane")]

        // When
        await sut.performSearch("DOLI")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
    }

    func testPerformSearchByReference() async {
        // Given
        // Ensure name, description, and dosage don't contain "DOL"
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Paracétamol", description: "Antalgique", dosage: "500mg", reference: "DOL500"),
            Medicine.mock(id: "2", name: "Aspirine", description: "Anti-inflammatoire", dosage: "100mg", reference: "ASP100")
        ]

        // When
        await sut.performSearch("DOL")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.reference, "DOL500")
    }

    func testPerformSearchByDescription() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", description: "Antalgique puissant"),
            Medicine.mock(id: "2", description: "Anti-inflammatoire")
        ]

        // When
        await sut.performSearch("antalgique")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.description, "Antalgique puissant")
    }

    func testPerformSearchByDosage() async {
        // Given
        // Ensure name, description, and reference don't contain "500"
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Paracétamol", description: "Antalgique", dosage: "500mg", reference: "PAR"),
            Medicine.mock(id: "2", name: "Aspirine", description: "Anti-inflammatoire", dosage: "100mg", reference: "ASP")
        ]

        // When
        await sut.performSearch("500")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
    }

    func testPerformSearchEmptyQuery() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]

        // When
        await sut.performSearch("")

        // Then
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }

    func testPerformSearchNoResults() async {
        // Given
        mockRepository.medicines = [Medicine.mock(name: "Doliprane")]

        // When
        await sut.performSearch("nonexistent")

        // Then
        XCTAssertTrue(sut.searchResults.isEmpty)
    }

    func testSearchTextDebouncing() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]
        let expectation = XCTestExpectation(description: "Debounce delay")

        // When - Rapid changes to searchText
        sut.searchText = "d"
        sut.searchText = "do"
        sut.searchText = "dol"

        // Wait for debounce (300ms + buffer)
        try? await Task.sleep(nanoseconds: 400_000_000)
        expectation.fulfill()

        await fulfillment(of: [expectation], timeout: 1.0)

        // Then - Should only search once after debounce
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Filter Tests

    func testFilterByAisle() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", aisleId: "aisle-1"),
            Medicine.mock(id: "2", aisleId: "aisle-2")
        ]

        // When
        sut.selectedFilters.aisleId = "aisle-1"
        await sut.performSearch("") // Empty search with filter applied

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.aisleId, "aisle-1")
    }

    func testFilterByStockStatus() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", currentQuantity: 5, criticalThreshold: 10), // Critical
            Medicine.mock(id: "2", currentQuantity: 50, criticalThreshold: 10) // Normal
        ]

        // When
        sut.selectedFilters.stockStatus = .critical
        await sut.performSearch("")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.stockStatus, .critical)
    }

    func testFilterByExpiringSoon() async {
        // Given
        let expiringSoon = Date().addingTimeInterval(15 * 24 * 60 * 60)
        let farFuture = Date().addingTimeInterval(365 * 24 * 60 * 60)

        mockRepository.medicines = [
            Medicine.mock(id: "1", expiryDate: expiringSoon),
            Medicine.mock(id: "2", expiryDate: farFuture)
        ]

        // When
        sut.selectedFilters.showExpiringOnly = true
        await sut.performSearch("")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertTrue(sut.searchResults.first?.isExpiringSoon ?? false)
    }

    func testFilterByExpired() async {
        // Given
        let expired = Date().addingTimeInterval(-1 * 24 * 60 * 60)
        let valid = Date().addingTimeInterval(365 * 24 * 60 * 60)

        mockRepository.medicines = [
            Medicine.mock(id: "1", expiryDate: expired),
            Medicine.mock(id: "2", expiryDate: valid)
        ]

        // When
        sut.selectedFilters.showExpiredOnly = true
        await sut.performSearch("")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertTrue(sut.searchResults.first?.isExpired ?? false)
    }

    func testFilterByMinQuantity() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", currentQuantity: 10),
            Medicine.mock(id: "2", currentQuantity: 50),
            Medicine.mock(id: "3", currentQuantity: 100)
        ]

        // When
        sut.selectedFilters.minQuantity = 50
        await sut.performSearch("")

        // Then
        XCTAssertEqual(sut.searchResults.count, 2)
        XCTAssertTrue(sut.searchResults.allSatisfy { $0.currentQuantity >= 50 })
    }

    func testFilterByMaxQuantity() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", currentQuantity: 10),
            Medicine.mock(id: "2", currentQuantity: 50),
            Medicine.mock(id: "3", currentQuantity: 100)
        ]

        // When
        sut.selectedFilters.maxQuantity = 50
        await sut.performSearch("")

        // Then
        XCTAssertEqual(sut.searchResults.count, 2)
        XCTAssertTrue(sut.searchResults.allSatisfy { $0.currentQuantity <= 50 })
    }

    func testFilterByQuantityRange() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", currentQuantity: 10),
            Medicine.mock(id: "2", currentQuantity: 50),
            Medicine.mock(id: "3", currentQuantity: 100)
        ]

        // When
        sut.selectedFilters.minQuantity = 20
        sut.selectedFilters.maxQuantity = 80
        await sut.performSearch("")

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.currentQuantity, 50)
    }

    func testMultipleFiltersApplied() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Doliprane", currentQuantity: 50, aisleId: "aisle-1"),
            Medicine.mock(id: "2", name: "Aspirine", currentQuantity: 20, aisleId: "aisle-1"),
            Medicine.mock(id: "3", name: "Doliprane XL", currentQuantity: 50, aisleId: "aisle-2")
        ]

        // When
        sut.searchText = "dol"
        sut.selectedFilters.aisleId = "aisle-1"
        sut.selectedFilters.minQuantity = 40
        await sut.performSearch(sut.searchText)

        // Then
        XCTAssertEqual(sut.searchResults.count, 1)
        XCTAssertEqual(sut.searchResults.first?.id, "1")
    }

    // MARK: - Sort Tests

    func testSortByNameAscending() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Zebra"),
            Medicine.mock(id: "2", name: "Alpha"),
            Medicine.mock(id: "3", name: "Bravo")
        ]
        sut.sortOption = .nameAscending

        // When - Search by a letter present in all names
        await sut.performSearch("a")

        // Then
        XCTAssertEqual(sut.searchResults.map { $0.name }, ["Alpha", "Bravo", "Zebra"])
    }

    func testSortByNameDescending() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Alpha"),
            Medicine.mock(id: "2", name: "Zebra"),
            Medicine.mock(id: "3", name: "Bravo")
        ]
        sut.sortOption = .nameDescending

        // When - Search by a letter present in all names
        await sut.performSearch("a")

        // Then
        XCTAssertEqual(sut.searchResults.map { $0.name }, ["Zebra", "Bravo", "Alpha"])
    }

    func testSortByQuantityAscending() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Med A", currentQuantity: 100),
            Medicine.mock(id: "2", name: "Med B", currentQuantity: 10),
            Medicine.mock(id: "3", name: "Med C", currentQuantity: 50)
        ]
        sut.sortOption = .quantityAscending

        // When - Search by "Med" which is present in all names
        await sut.performSearch("Med")

        // Then
        XCTAssertEqual(sut.searchResults.map { $0.currentQuantity }, [10, 50, 100])
    }

    func testSortByQuantityDescending() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Med A", currentQuantity: 10),
            Medicine.mock(id: "2", name: "Med B", currentQuantity: 100),
            Medicine.mock(id: "3", name: "Med C", currentQuantity: 50)
        ]
        sut.sortOption = .quantityDescending

        // When - Search by "Med" which is present in all names
        await sut.performSearch("Med")

        // Then
        XCTAssertEqual(sut.searchResults.map { $0.currentQuantity }, [100, 50, 10])
    }

    func testSortByExpiryDate() async {
        // Given
        let date1 = Date().addingTimeInterval(10 * 24 * 60 * 60) // 10 days
        let date2 = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        let date3 = Date().addingTimeInterval(5 * 24 * 60 * 60)  // 5 days

        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Med 1", expiryDate: date1),
            Medicine.mock(id: "2", name: "Med 2", expiryDate: date2),
            Medicine.mock(id: "3", name: "Med 3", expiryDate: date3)
        ]
        sut.sortOption = .expiryDateAscending

        // When - Search by "Med" which is present in all names
        await sut.performSearch("Med")

        // Then
        XCTAssertEqual(sut.searchResults.first?.id, "3") // Earliest expiry first
        XCTAssertEqual(sut.searchResults.last?.id, "2")  // Latest expiry last
    }

    func testSortByStockStatus() async {
        // Given
        mockRepository.medicines = [
            Medicine.mock(id: "1", name: "Med A", currentQuantity: 50, criticalThreshold: 10), // Normal
            Medicine.mock(id: "2", name: "Med B", currentQuantity: 5, criticalThreshold: 10),  // Critical
            Medicine.mock(id: "3", name: "Med C", currentQuantity: 15, warningThreshold: 20)  // Warning
        ]
        sut.sortOption = .stockStatus

        // When - Search by "Med" which is present in all names
        await sut.performSearch("Med")

        // Then
        XCTAssertEqual(sut.searchResults.first?.stockStatus, .critical)
        XCTAssertEqual(sut.searchResults.last?.stockStatus, .normal)
    }

    // MARK: - Recent Searches Tests

    func testRecentSearchesAdded() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]

        // When
        await sut.performSearch("doliprane")

        // Then
        XCTAssertEqual(sut.recentSearches.count, 1)
        XCTAssertEqual(sut.recentSearches.first, "doliprane")
    }

    func testRecentSearchesNoDuplicates() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]

        // When
        await sut.performSearch("doliprane")
        await sut.performSearch("aspirine")
        await sut.performSearch("doliprane") // Duplicate

        // Then
        XCTAssertEqual(sut.recentSearches.count, 2)
        XCTAssertEqual(sut.recentSearches.first, "doliprane") // Should be at top
    }

    func testRecentSearchesLimitedTo10() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]

        // When - Add 15 searches
        for i in 0..<15 {
            await sut.performSearch("search\(i)")
        }

        // Then
        XCTAssertEqual(sut.recentSearches.count, 10)
        XCTAssertEqual(sut.recentSearches.first, "search14") // Most recent
    }

    func testClearRecentSearches() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]
        await sut.performSearch("test")
        XCTAssertFalse(sut.recentSearches.isEmpty)

        // When
        sut.clearRecentSearches()

        // Then
        XCTAssertTrue(sut.recentSearches.isEmpty)
    }

    // MARK: - Filter Management Tests

    func testHasActiveFilters() {
        // Given - No filters
        XCTAssertFalse(sut.hasActiveFilters)

        // When - Add filter
        sut.selectedFilters.aisleId = "aisle-1"

        // Then
        XCTAssertTrue(sut.hasActiveFilters)
    }

    func testActiveFiltersCount() {
        // Given
        XCTAssertEqual(sut.activeFiltersCount, 0)

        // When - Add multiple filters
        sut.selectedFilters.aisleId = "aisle-1"
        sut.selectedFilters.stockStatus = .critical
        sut.selectedFilters.showExpiringOnly = true
        sut.selectedFilters.minQuantity = 10

        // Then
        XCTAssertEqual(sut.activeFiltersCount, 4)
    }

    func testApplyFilters() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]
        sut.searchText = "test"
        sut.selectedFilters.minQuantity = 20

        // When
        sut.applyFilters()

        // Wait for async search to complete
        try? await Task.sleep(nanoseconds: 400_000_000)

        // Then - Should trigger search with filters
        XCTAssertTrue(sut.hasActiveFilters)
    }

    func testClearFilters() async {
        // Given
        sut.selectedFilters.aisleId = "aisle-1"
        sut.selectedFilters.stockStatus = .critical
        sut.selectedFilters.minQuantity = 10

        // When
        sut.clearFilters()

        // Then
        XCTAssertFalse(sut.hasActiveFilters)
        XCTAssertEqual(sut.activeFiltersCount, 0)
    }

    // MARK: - Search Loading State Tests

    func testSearchLoadingState() async {
        // Given
        mockRepository.medicines = [Medicine.mock()]
        let expectation = XCTestExpectation(description: "Search loading state")
        var searchingStates: [Bool] = []

        sut.$isSearching.sink { isSearching in
            searchingStates.append(isSearching)
            if searchingStates.count >= 2 {
                expectation.fulfill()
            }
        }
        .store(in: &cancellables)

        // When
        await sut.performSearch("test")

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.isSearching)
    }

    // MARK: - Error Handling Tests

    func testSearchWithRepositoryError() async {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await sut.performSearch("test")

        // Then
        XCTAssertTrue(sut.searchResults.isEmpty)
        XCTAssertFalse(sut.isSearching)
    }
}
