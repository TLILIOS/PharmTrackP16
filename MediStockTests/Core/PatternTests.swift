import XCTest
@testable import MediStock

// MARK: - Tests pour les nouveaux Patterns réutilisables

class PatternTests: XCTestCase {
    
    // MARK: - Tests ViewModelBase
    
    @MainActor
    func testViewModelBaseErrorHandling() async {
        // Arrange
        class TestViewModel: BaseViewModel {
            var result: String?
            
            func loadData() async {
                result = await performOperation {
                    throw TestError.simulatedError
                }
            }
            
            func loadSuccessData() async {
                result = await performOperation {
                    return "Success"
                }
            }
        }
        
        let viewModel = TestViewModel()
        
        // Act - Test erreur
        await viewModel.loadData()
        
        // Assert
        XCTAssertNil(viewModel.result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        // Act - Test succès
        await viewModel.loadSuccessData()
        
        // Assert
        XCTAssertEqual(viewModel.result, "Success")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testViewModelBaseLoadingState() async {
        // Arrange
        class SlowViewModel: BaseViewModel {
            func slowOperation() async {
                await performOperation {
                    try await Task.sleep(nanoseconds: 1_000_000) // 1ms seulement
                }
            }
        }
        
        let viewModel = SlowViewModel()
        
        // Act
        let task = Task {
            await viewModel.slowOperation()
        }
        
        // Assert - Vérifier que isLoading passe à true
        try? await Task.sleep(nanoseconds: 100_000) // 0.1ms seulement
        XCTAssertTrue(viewModel.isLoading)
        
        await task.value
        
        // Assert - Vérifier que isLoading repasse à false
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Tests PaginationManager
    
    @MainActor
    func testPaginationManagerInitialState() {
        // Arrange & Act
        let manager = PaginationManager<TestItem>(pageSize: 25)
        
        // Assert
        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertFalse(manager.isLoadingMore)
        XCTAssertTrue(manager.hasMore)
        XCTAssertNil(manager.errorMessage)
        XCTAssertEqual(manager.pageSize, 25)
    }
    
    @MainActor
    func testPaginationManagerLoadFirstPage() async {
        // Arrange
        let manager = PaginationManager<TestItem>()
        let service = MockPaginationService()
        service.items = TestItem.generateItems(count: 30)
        
        // Act
        await manager.loadFirstPage(using: service)
        
        // Assert
        XCTAssertEqual(manager.items.count, 20) // Page size par défaut
        XCTAssertTrue(manager.hasMore)
        XCTAssertFalse(manager.isLoadingMore)
    }
    
    @MainActor
    func testPaginationManagerLoadAllPages() async {
        // Arrange
        let manager = PaginationManager<TestItem>(pageSize: 10)
        let service = MockPaginationService()
        service.items = TestItem.generateItems(count: 25) // 3 pages
        
        // Act - Charger les 3 pages
        await manager.loadFirstPage(using: service)
        XCTAssertEqual(manager.items.count, 10)
        
        await manager.loadNextPage(using: service)
        XCTAssertEqual(manager.items.count, 20)
        
        await manager.loadNextPage(using: service)
        XCTAssertEqual(manager.items.count, 25)
        XCTAssertFalse(manager.hasMore) // Plus de pages
        
        // Vérifier qu'on ne charge pas plus
        await manager.loadNextPage(using: service)
        XCTAssertEqual(manager.items.count, 25) // Pas de changement
    }
    
    @MainActor
    func testPaginationManagerErrorHandling() async {
        // Arrange
        let manager = PaginationManager<TestItem>()
        let service = MockPaginationService()
        service.shouldThrowError = true
        
        // Act
        await manager.loadFirstPage(using: service)
        
        // Assert
        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertNotNil(manager.errorMessage)
        XCTAssertFalse(manager.isLoadingMore)
    }
    
    @MainActor
    func testPaginationManagerReset() async {
        // Arrange
        let manager = PaginationManager<TestItem>()
        let service = MockPaginationService()
        service.items = TestItem.generateItems(count: 30)
        
        // Charger des données
        await manager.loadFirstPage(using: service)
        XCTAssertFalse(manager.items.isEmpty)
        
        // Act - Reset
        manager.reset()
        
        // Assert
        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertTrue(manager.hasMore)
        XCTAssertNil(manager.errorMessage)
    }
    
    // MARK: - Tests Constants
    
    func testConstantsValues() {
        // Vérifier que les constantes ont les bonnes valeurs
        XCTAssertEqual(AppConstants.Pagination.defaultLimit, 20)
        XCTAssertEqual(AppConstants.Dates.expiryWarningDaysAhead, 30)
        XCTAssertEqual(AppConstants.Limits.maxMedicinesPerUser, 1000)
        XCTAssertEqual(AppConstants.UI.cornerRadius, 12)
        XCTAssertEqual(AppConstants.Firebase.medicinesCollection, "medicines")
    }
    
    func testConstantsHelperMethods() {
        // Test isNearExpiry
        let nearExpiryDate = Date().addingTimeInterval(TimeInterval(20 * AppConstants.Dates.secondsPerDay))
        XCTAssertTrue(AppConstants.isNearExpiry(nearExpiryDate))
        
        let farExpiryDate = Date().addingTimeInterval(TimeInterval(60 * AppConstants.Dates.secondsPerDay))
        XCTAssertFalse(AppConstants.isNearExpiry(farExpiryDate))
        
        // Test isCriticalStock
        XCTAssertTrue(AppConstants.isCriticalStock(5))
        XCTAssertFalse(AppConstants.isCriticalStock(20))
        XCTAssertTrue(AppConstants.isCriticalStock(15, criticalThreshold: 20))
    }
    
    func testValidationPatterns() {
        // Test hex color validation
        let hexPattern = AppConstants.Validation.hexColorPattern
        let regex = try! NSRegularExpression(pattern: hexPattern)
        
        // Valides
        XCTAssertTrue(matchesPattern("#FF0000", regex: regex))
        XCTAssertTrue(matchesPattern("#00ff00", regex: regex))
        XCTAssertTrue(matchesPattern("#123456", regex: regex))
        
        // Invalides
        XCTAssertFalse(matchesPattern("FF0000", regex: regex)) // Manque #
        XCTAssertFalse(matchesPattern("#FF00", regex: regex)) // Trop court
        XCTAssertFalse(matchesPattern("#GGGGGG", regex: regex)) // Caractères invalides
    }
    
    // MARK: - Tests d'Intégration des Patterns
    
    @MainActor
    func testPatternsCombination() async {
        // Test d'un ViewModel utilisant tous les patterns
        class IntegratedViewModel: BaseViewModel {
            let paginationManager = PaginationManager<TestItem>()
            
            func loadData() async {
                await performOperation { [weak self] in
                    guard let self = self else { return }
                    let service = MockPaginationService()
                    service.items = TestItem.generateItems(count: 30)
                    await self.paginationManager.loadFirstPage(
                        using: service
                    )
                }
            }
        }
        
        let viewModel = IntegratedViewModel()
        
        // Act
        await viewModel.loadData()
        
        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.paginationManager.items.isEmpty)
    }
}

// MARK: - Test Helpers

private enum TestError: LocalizedError {
    case simulatedError
    
    var errorDescription: String? {
        return "Erreur simulée pour les tests"
    }
}

private struct TestItem: Identifiable {
    let id: String
    let name: String
    
    static func generateItems(count: Int) -> [TestItem] {
        (0..<count).map { TestItem(id: "\($0)", name: "Item \($0)") }
    }
}

private class MockPaginationService: PaginationService {
    var items: [TestItem] = []
    var shouldThrowError = false
    private var currentIndex = 0
    
    func fetchItems(limit: Int, refresh: Bool) async throws -> [TestItem] {
        if shouldThrowError {
            throw TestError.simulatedError
        }
        
        if refresh {
            currentIndex = 0
        }
        
        let endIndex = min(currentIndex + limit, items.count)
        let page = Array(items[currentIndex..<endIndex])
        currentIndex = endIndex
        
        return page
    }
}

private func matchesPattern(_ string: String, regex: NSRegularExpression) -> Bool {
    let range = NSRange(location: 0, length: string.utf16.count)
    return regex.firstMatch(in: string, options: [], range: range) != nil
}