import XCTest
@testable import MediStock

// MARK: - Tests pour AisleListViewModel

@MainActor
class AisleListViewModelTests: XCTestCase {
    
    var viewModel: AisleListViewModel!
    var mockRepository: MockAisleRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockAisleRepository()
        viewModel = AisleListViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Tests de Chargement
    
    func testLoadAislesSuccess() async {
        // Arrange
        let expectedAisles = TestData.mockAisles
        mockRepository.aisles = expectedAisles
        
        // Act
        await viewModel.loadAisles()
        
        // Assert
        XCTAssertEqual(viewModel.aisles.count, min(20, expectedAisles.count))
        XCTAssertEqual(viewModel.aisles.first?.id, expectedAisles.first?.id)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadAislesFailure() async {
        // Arrange
        mockRepository.shouldThrowError = true
        
        // Act
        await viewModel.loadAisles()
        
        // Assert
        XCTAssertTrue(viewModel.aisles.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Tests de Pagination
    
    func testLoadMoreAisles() async {
        // Arrange
        // Configurer 30 aisles dans le mock pour tester la pagination
        mockRepository.aisles = TestData.mockAisles

        // Charger le premier batch (20 éléments, donc hasMoreAisles sera true)
        await viewModel.loadAisles()

        // Vérifier que hasMoreAisles est true après le premier chargement
        XCTAssertTrue(viewModel.hasMoreAisles, "Should have more aisles when loading exactly 20 items")
        XCTAssertEqual(viewModel.aisles.count, 20)

        // Act - Charger la page suivante
        await viewModel.loadMoreAisles()

        // Assert
        XCTAssertEqual(viewModel.aisles.count, 30)
        XCTAssertFalse(viewModel.isLoadingMore)
    }
    
    func testLoadMoreAislesWhenNoMore() async {
        // Arrange
        // Charger d'abord des données puis attendre que hasMoreAisles soit false
        mockRepository.aisles = Array(TestData.mockAisles.prefix(5)) // Moins que la limite
        await viewModel.loadAisles()

        let initialCount = viewModel.aisles.count

        // Act
        await viewModel.loadMoreAisles()

        // Assert
        XCTAssertEqual(viewModel.aisles.count, initialCount)
    }
    
    // MARK: - Tests de Sauvegarde
    
    func testSaveAisleSuccess() async {
        // Arrange
        let newAisle = Aisle(
            id: "",
            name: "Nouveau Rayon",
            description: nil,
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // Act
        await viewModel.saveAisle(newAisle)
        
        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testSaveAisleUpdate() async {
        // Arrange
        let existingAisle = TestData.mockAisles.first!

        // Utiliser makeMock pour initialiser avec des données
        viewModel = AisleListViewModel.makeMock(aisles: [existingAisle], repository: mockRepository)

        let updatedAisle = Aisle(
            id: existingAisle.id,
            name: "Updated Name",
            description: existingAisle.description,
            colorHex: existingAisle.colorHex,
            icon: existingAisle.icon
        )

        mockRepository.aisles = [updatedAisle]

        // Act
        await viewModel.saveAisle(updatedAisle)

        // Assert
        XCTAssertEqual(viewModel.aisles.first?.name, "Updated Name")
        XCTAssertEqual(viewModel.aisles.count, 1)
    }
    
    func testSaveAisleFailure() async {
        // Arrange
        mockRepository.shouldThrowError = true
        let newAisle = Aisle(
            id: "",
            name: "New Aisle",
            description: nil,
            colorHex: "#FF0000",
            icon: "pills"
        )
        
        // Act
        await viewModel.saveAisle(newAisle)
        
        // Assert
        XCTAssertNotNil(viewModel.errorMessage)
    }
    
    // MARK: - Tests de Suppression
    
    func testDeleteAisleSuccess() async {
        // Arrange
        let aisleToDelete = TestData.mockAisles.first!

        // Initialiser le repository avec des données
        mockRepository.aisles = TestData.mockAisles

        // Charger les données dans le viewModel
        await viewModel.loadAisles()

        let initialCount = viewModel.aisles.count

        // Act
        await viewModel.deleteAisle(aisleToDelete)

        // Assert
        XCTAssertFalse(viewModel.aisles.contains { $0.id == aisleToDelete.id })
        XCTAssertEqual(viewModel.aisles.count, initialCount - 1)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testDeleteAisleFailure() async {
        // Arrange
        let aisleToDelete = TestData.mockAisles.first!
        mockRepository.shouldThrowError = true

        // Utiliser makeMock pour initialiser avec des données
        viewModel = AisleListViewModel.makeMock(aisles: TestData.mockAisles, repository: mockRepository)
        let initialCount = viewModel.aisles.count

        // Act
        await viewModel.deleteAisle(aisleToDelete)

        // Assert
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.aisles.count, initialCount) // L'aisle ne devrait pas être supprimé
    }
    
    // MARK: - Tests d'État UI
    
    func testClearError() {
        // Arrange
        viewModel.errorMessage = "Some error"
        
        // Act
        viewModel.clearError()
        
        // Assert
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testHasMoreAislesLogic() async {
        // Arrange - Less than 20 aisles
        mockRepository.aisles = Array(TestData.mockAisles.prefix(10))

        // Act
        await viewModel.loadAisles()

        // Assert
        XCTAssertFalse(viewModel.hasMoreAisles)

        // Arrange - Exactly 20 aisles (force refresh to bypass debouncing)
        mockRepository.aisles = Array(TestData.mockAisles.prefix(20))

        // Act - Force refresh to bypass debouncing
        await viewModel.loadAisles(forceRefresh: true)

        // Assert
        XCTAssertTrue(viewModel.hasMoreAisles)
    }
}