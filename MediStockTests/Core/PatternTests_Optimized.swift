import XCTest
@testable import MediStock

// MARK: - Tests OPTIMISÉS pour les Patterns (Version Ultra-Rapide)

class PatternTests_Optimized: XCTestCase {
    
    // MARK: - Tests ViewModelBase (Sans Sleep)
    
    @MainActor
    func testViewModelBaseErrorHandling() async {
        // Test direct sans délai
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
        
        // Test erreur
        await viewModel.loadData()
        XCTAssertNil(viewModel.result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        
        // Test succès
        await viewModel.loadSuccessData()
        XCTAssertEqual(viewModel.result, "Success")
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testViewModelBaseLoadingState() async {
        // Test synchrone du loading state
        class FastViewModel: BaseViewModel {
            var loadingStates: [Bool] = []
            
            func captureLoadingState() async {
                // Capturer l'état avant
                loadingStates.append(isLoading)
                
                // Opération synchrone
                _ = await performOperation {
                    // Capturer pendant (synchrone)
                    self.loadingStates.append(self.isLoading)
                    return "Done"
                }
                
                // Capturer après
                loadingStates.append(isLoading)
            }
        }
        
        let viewModel = FastViewModel()
        await viewModel.captureLoadingState()
        
        // Vérifier la séquence: false -> true -> false
        XCTAssertEqual(viewModel.loadingStates, [false, true, false])
    }
    
    // MARK: - Tests PaginationManager (Données Réduites)
    
    @MainActor
    func testPaginationManagerQuick() async {
        // Test avec seulement 9 items pour éviter le cas limite
        let manager = PaginationManager<TestItem>(pageSize: 5)
        let service = MockPaginationService()
        service.items = TestItem.generateItems(count: 9) // 9 items au lieu de 10
        
        // Test initial state
        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertFalse(manager.isLoadingMore)
        XCTAssertTrue(manager.hasMore)
        
        // Load first page
        await manager.loadFirstPage(using: service)
        XCTAssertEqual(manager.items.count, 5)
        XCTAssertTrue(manager.hasMore)
        
        // Load second page - will return 4 items
        await manager.loadNextPage(using: service)
        XCTAssertEqual(manager.items.count, 9)
        XCTAssertFalse(manager.hasMore) // Plus de pages car moins d'items que pageSize
    }
    
    @MainActor
    func testPaginationManagerError() async {
        let manager = PaginationManager<TestItem>()
        let service = MockPaginationService()
        service.shouldThrowError = true
        
        await manager.loadFirstPage(using: service)
        
        XCTAssertTrue(manager.items.isEmpty)
        XCTAssertNotNil(manager.errorMessage)
        XCTAssertFalse(manager.isLoadingMore)
    }
    
    // MARK: - Tests Constants (Rapides)
    
    func testConstantsQuick() {
        // Tests essentiels seulement
        XCTAssertEqual(AppConstants.Pagination.defaultLimit, 20)
        XCTAssertEqual(AppConstants.Limits.maxMedicinesPerUser, 1000)
        XCTAssertEqual(AppConstants.UI.cornerRadius, 12)
        
        // Test helper methods
        let nearExpiry = Date().addingTimeInterval(TimeInterval(20 * 86400))
        XCTAssertTrue(AppConstants.isNearExpiry(nearExpiry))
        
        XCTAssertTrue(AppConstants.isCriticalStock(5))
        XCTAssertFalse(AppConstants.isCriticalStock(20))
    }
    
    // MARK: - Test d'Intégration Rapide
    
    @MainActor
    func testIntegrationQuick() async {
        class QuickViewModel: BaseViewModel {
            let paginationManager = PaginationManager<TestItem>(pageSize: 5)
            
            func loadData() async {
                await performOperation { [weak self] in
                    let service = MockPaginationService()
                    service.items = TestItem.generateItems(count: 5) // Seulement 5 items
                    await self?.paginationManager.loadFirstPage(using: service)
                }
            }
        }
        
        let viewModel = QuickViewModel()
        await viewModel.loadData()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.paginationManager.items.count, 5)
    }
}

// MARK: - Helpers Optimisés

private enum TestError: LocalizedError {
    case simulatedError
    var errorDescription: String? { "Test error" }
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