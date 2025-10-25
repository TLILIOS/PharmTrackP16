import XCTest
import Combine
@testable import MediStock

@MainActor
class SearchViewModelTests: BaseTestCase {
    var viewModel: SearchViewModel!
    var mockMedicineRepository: MockMedicineRepository!
    var mockDataService: MockDataServiceAdapter!
    
    override func setUp() {
        super.setUp()
        // Clear any existing recent searches from UserDefaults
        UserDefaults.standard.removeObject(forKey: "recentSearches")
        UserDefaults.standard.synchronize()
        
        mockMedicineRepository = MockMedicineRepository()
        mockDataService = MockDataServiceAdapter()
        viewModel = SearchViewModel(
            medicineRepository: mockMedicineRepository,
            dataService: mockDataService
        )
    }
    
    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "recentSearches")
        UserDefaults.standard.synchronize()
        
        viewModel = nil
        mockMedicineRepository = nil
        mockDataService = nil
        super.tearDown()
    }
    
    // MARK: - Search Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.searchResults.count, 0)
        XCTAssertFalse(viewModel.isSearching)
        XCTAssertFalse(viewModel.showingFilterSheet)
        XCTAssertEqual(viewModel.sortOption, .nameAscending)
        XCTAssertEqual(viewModel.recentSearches.count, 0)
    }
    
    func testSearchByName() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", description: "Antalgique"),
            .mock(id: "2", name: "Aspirine", description: "Anti-inflammatoire"),
            .mock(id: "3", name: "Ibuprofène", description: "Anti-inflammatoire")
        ]
        
        // Act
        viewModel.searchText = "Doliprane"
        await viewModel.performSearch("Doliprane")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Doliprane")
        XCTAssertFalse(viewModel.isSearching)
    }
    
    func testSearchByReference() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", reference: "DOL500"),
            .mock(id: "2", name: "Aspirine", reference: "ASP100"),
            .mock(id: "3", name: "Ibuprofène", reference: "IBU400")
        ]
        
        // Act
        await viewModel.performSearch("ASP")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Aspirine")
    }
    
    func testSearchByDescription() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", description: "Antalgique"),
            .mock(id: "2", name: "Aspirine", description: "Anti-inflammatoire"),
            .mock(id: "3", name: "Ibuprofène", description: "Anti-inflammatoire")
        ]
        
        // Act
        await viewModel.performSearch("Anti-inflammatoire")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 2)
        XCTAssertTrue(viewModel.searchResults.allSatisfy { $0.description?.contains("Anti-inflammatoire") ?? false })
    }
    
    func testSearchByDosage() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", dosage: "500mg"),
            .mock(id: "2", name: "Aspirine", dosage: "100mg"),
            .mock(id: "3", name: "Ibuprofène", dosage: "400mg")
        ]
        
        // Act
        await viewModel.performSearch("500mg")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.dosage, "500mg")
    }
    
    func testEmptySearchReturnsNoResults() async {
        // Arrange
        mockMedicineRepository.medicines = TestData.mockMedicines
        
        // Act
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 0)
        XCTAssertFalse(viewModel.isSearching)
    }
    
    func testSearchWithError() async {
        // Arrange
        mockMedicineRepository.shouldThrowError = true
        
        // Act
        await viewModel.performSearch("Test")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 0)
        XCTAssertFalse(viewModel.isSearching)
    }
    
    // MARK: - Filter Tests
    
    func testFilterByAisle() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", aisleId: "aisle-1"),
            .mock(id: "2", name: "Aspirine", aisleId: "aisle-2"),
            .mock(id: "3", name: "Ibuprofène", aisleId: "aisle-1")
        ]
        
        // Act
        viewModel.selectedFilters.aisleId = "aisle-1"
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 2)
        XCTAssertTrue(viewModel.searchResults.allSatisfy { $0.aisleId == "aisle-1" })
    }
    
    func testFilterByStockStatus() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", currentQuantity: 5, criticalThreshold: 10),
            .mock(id: "2", name: "Aspirine", currentQuantity: 15, warningThreshold: 20),
            .mock(id: "3", name: "Ibuprofène", currentQuantity: 50)
        ]
        
        // Act
        viewModel.selectedFilters.stockStatus = .critical
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Doliprane")
    }
    
    func testFilterByExpiring() async {
        // Arrange
        let expiringDate = Date().addingTimeInterval(10 * 24 * 60 * 60) // 10 jours
        let notExpiringDate = Date().addingTimeInterval(60 * 24 * 60 * 60) // 60 jours
        
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", expiryDate: expiringDate),
            .mock(id: "2", name: "Aspirine", expiryDate: notExpiringDate),
            .mock(id: "3", name: "Ibuprofène", expiryDate: nil)
        ]
        
        // Act
        viewModel.selectedFilters.showExpiringOnly = true
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Doliprane")
    }
    
    func testFilterByExpired() async {
        // Arrange
        let expiredDate = Date().addingTimeInterval(-1 * 24 * 60 * 60) // Hier
        let validDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 jours
        
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", expiryDate: expiredDate),
            .mock(id: "2", name: "Aspirine", expiryDate: validDate),
            .mock(id: "3", name: "Ibuprofène", expiryDate: nil)
        ]
        
        // Act
        viewModel.selectedFilters.showExpiredOnly = true
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Doliprane")
    }
    
    func testFilterByQuantityRange() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", currentQuantity: 10),
            .mock(id: "2", name: "Aspirine", currentQuantity: 25),
            .mock(id: "3", name: "Ibuprofène", currentQuantity: 50)
        ]
        
        // Act
        viewModel.selectedFilters.minQuantity = 20
        viewModel.selectedFilters.maxQuantity = 40
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Aspirine")
    }
    
    func testCombinedFilters() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", currentQuantity: 30, aisleId: "aisle-1"),
            .mock(id: "2", name: "Aspirine", currentQuantity: 5, aisleId: "aisle-1"),
            .mock(id: "3", name: "Ibuprofène", currentQuantity: 30, aisleId: "aisle-2")
        ]
        
        // Act
        viewModel.selectedFilters.aisleId = "aisle-1"
        viewModel.selectedFilters.minQuantity = 20
        await viewModel.performSearch("")
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.count, 1)
        XCTAssertEqual(viewModel.searchResults.first?.name, "Doliprane")
    }
    
    // MARK: - Sort Tests
    
    func testSortByNameAscending() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Ibuprofène"),
            .mock(id: "2", name: "Aspirine"),
            .mock(id: "3", name: "Doliprane")
        ]
        
        // Act
        viewModel.sortOption = .nameAscending
        await viewModel.performSearch("") // Empty search with filters
        viewModel.selectedFilters.aisleId = nil // Ensure we get all medicines
        await viewModel.performSearch("i") // Search for 'i' to get all with 'i'
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.first?.name, "Aspirine")
        XCTAssertEqual(viewModel.searchResults.last?.name, "Ibuprofène")
    }
    
    func testSortByNameDescending() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Aspirine"),
            .mock(id: "2", name: "Doliprane"),
            .mock(id: "3", name: "Ibuprofène")
        ]
        
        // Act
        viewModel.sortOption = .nameDescending
        await viewModel.performSearch("i") // Search for 'i' to get Aspirine and Ibuprofène
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.first?.name, "Ibuprofène")
        XCTAssertEqual(viewModel.searchResults.last?.name, "Aspirine")
    }
    
    func testSortByQuantityAscending() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", currentQuantity: 50),
            .mock(id: "2", name: "Aspirine", currentQuantity: 10),
            .mock(id: "3", name: "Ibuprofène", currentQuantity: 30)
        ]
        
        // Act
        viewModel.sortOption = .quantityAscending
        await viewModel.performSearch("i") // Search to get all medicines with 'i'
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.first?.currentQuantity, 10)
        XCTAssertEqual(viewModel.searchResults.last?.currentQuantity, 50)
    }
    
    func testSortByStockStatus() async {
        // Arrange
        mockMedicineRepository.medicines = [
            .mock(id: "1", name: "Doliprane", currentQuantity: 50), // Normal
            .mock(id: "2", name: "Aspirine", currentQuantity: 5, criticalThreshold: 10), // Critical
            .mock(id: "3", name: "Ibuprofène", currentQuantity: 15, warningThreshold: 20) // Warning
        ]
        
        // Act
        viewModel.sortOption = .stockStatus
        await viewModel.performSearch("i") // Search to get all medicines with 'i'
        
        // Assert
        XCTAssertEqual(viewModel.searchResults.first?.stockStatus, .critical)
        XCTAssertEqual(viewModel.searchResults.last?.stockStatus, .normal)
    }
    
    // MARK: - Recent Searches Tests
    
    func testAddToRecentSearches() async {
        // Arrange
        mockMedicineRepository.medicines = TestData.mockMedicines
        
        // Act
        await viewModel.performSearch("Doliprane")
        await viewModel.performSearch("Aspirine")
        
        // Assert
        XCTAssertEqual(viewModel.recentSearches.count, 2)
        XCTAssertEqual(viewModel.recentSearches.first, "Aspirine") // Most recent first
        XCTAssertEqual(viewModel.recentSearches.last, "Doliprane")
    }
    
    func testRecentSearchesLimit() async {
        // Arrange
        mockMedicineRepository.medicines = TestData.mockMedicines
        
        // Act
        for i in 1...12 {
            await viewModel.performSearch("Search \(i)")
        }
        
        // Assert
        XCTAssertEqual(viewModel.recentSearches.count, 10) // Limited to 10
        XCTAssertEqual(viewModel.recentSearches.first, "Search 12") // Most recent
        XCTAssertFalse(viewModel.recentSearches.contains("Search 1")) // Oldest removed
        XCTAssertFalse(viewModel.recentSearches.contains("Search 2")) // Oldest removed
    }
    
    func testClearRecentSearches() {
        // Arrange
        viewModel.recentSearches = ["Search 1", "Search 2", "Search 3"]
        
        // Act
        viewModel.clearRecentSearches()
        
        // Assert
        XCTAssertEqual(viewModel.recentSearches.count, 0)
    }
    
    // MARK: - Helper Methods Tests
    
    func testHasActiveFilters() {
        // Initially no filters
        XCTAssertFalse(viewModel.hasActiveFilters)
        
        // Add aisle filter
        viewModel.selectedFilters.aisleId = "aisle-1"
        XCTAssertTrue(viewModel.hasActiveFilters)
        
        // Reset and add stock status filter
        viewModel.selectedFilters = SearchFilters()
        viewModel.selectedFilters.stockStatus = .critical
        XCTAssertTrue(viewModel.hasActiveFilters)
        
        // Clear all filters
        viewModel.clearFilters()
        XCTAssertFalse(viewModel.hasActiveFilters)
    }
    
    func testActiveFiltersCount() {
        // Initially no filters
        XCTAssertEqual(viewModel.activeFiltersCount, 0)
        
        // Add multiple filters
        viewModel.selectedFilters.aisleId = "aisle-1"
        viewModel.selectedFilters.stockStatus = .critical
        viewModel.selectedFilters.showExpiringOnly = true
        viewModel.selectedFilters.minQuantity = 10
        
        XCTAssertEqual(viewModel.activeFiltersCount, 4)
    }
    
    func testApplyFilters() async {
        // Arrange
        mockMedicineRepository.medicines = TestData.mockMedicines
        viewModel.searchText = "Medicine"
        
        // Act
        viewModel.selectedFilters.aisleId = "1"
        viewModel.applyFilters()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Assert
        XCTAssertTrue(viewModel.searchResults.allSatisfy { $0.aisleId == "1" })
    }
    
    func testClearFilters() async {
        // Arrange
        mockMedicineRepository.medicines = TestData.mockMedicines
        viewModel.selectedFilters.aisleId = "1"
        viewModel.selectedFilters.stockStatus = .critical
        
        // Act
        viewModel.clearFilters()
        
        // Assert
        XCTAssertNil(viewModel.selectedFilters.aisleId)
        XCTAssertNil(viewModel.selectedFilters.stockStatus)
        XCTAssertFalse(viewModel.selectedFilters.showExpiringOnly)
        XCTAssertFalse(viewModel.selectedFilters.showExpiredOnly)
    }
    
    // MARK: - Debounce Tests
    
    func testSearchDebounce() async {
        // Arrange
        mockMedicineRepository.medicines = TestData.mockMedicines
        var searchCount = 0
        
        // Monitor search operations
        viewModel.$isSearching
            .sink { isSearching in
                if isSearching { searchCount += 1 }
            }
            .store(in: &cancellables)
        
        // Act - Rapid text changes
        viewModel.searchText = "D"
        viewModel.searchText = "Do"
        viewModel.searchText = "Dol"
        viewModel.searchText = "Doli"
        viewModel.searchText = "Dolip"
        
        // Wait for debounce
        try? await Task.sleep(nanoseconds: 400_000_000) // 0.4 second
        
        // Assert - Should only search once due to debounce
        XCTAssertLessThanOrEqual(searchCount, 2) // Initial state + 1 search
    }
}

// MARK: - Mock DataServiceAdapter

