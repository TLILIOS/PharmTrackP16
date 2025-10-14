import XCTest
import Combine
@testable import MediStock

/// Exemple de test migré pour utiliser la nouvelle architecture
/// Comparer avec l'ancienne version pour voir les améliorations
@MainActor
final class ExampleMigratedTest: BaseTestCase {
    
    // MARK: - Properties
    
    private var viewModel: MedicineListViewModel!
    private var mockRepository: MockMedicineRepository!
    private var mockHistoryRepository: MockHistoryRepository!
    private var mockNotificationService: MockNotificationService!
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        // Utiliser les helpers de BaseTestCase pour créer les mocks
        mockRepository = createMockMedicineRepository()
        mockHistoryRepository = createMockHistoryRepository()
        mockNotificationService = MockNotificationService()
        
        // Initialiser le ViewModel avec les mocks
        viewModel = MedicineListViewModel(
            medicineRepository: mockRepository,
            historyRepository: mockHistoryRepository,
            notificationService: mockNotificationService
        )
    }
    
    // MARK: - Tests
    
    func testLoadMedicinesWithMockData() async throws {
        // Given - Configurer les données de test
        let testMedicines = [
            Medicine.mock(id: "1", name: "Doliprane", currentQuantity: 50),
            Medicine.mock(id: "2", name: "Aspirine", currentQuantity: 5, criticalThreshold: 10),
            Medicine.mock(id: "3", name: "Ibuprofène", expiryDate: Date().addingTimeInterval(10 * 24 * 60 * 60))
        ]
        mockRepository.medicines = testMedicines
        
        // When - Charger les médicaments
        await viewModel.loadMedicines()
        
        // Then - Vérifier les résultats
        XCTAssertEqual(viewModel.medicines.count, 3)
        XCTAssertEqual(viewModel.criticalMedicines.count, 1) // Aspirine
        XCTAssertEqual(viewModel.expiringMedicines.count, 1) // Ibuprofène
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testErrorHandlingWithMock() async {
        // Given - Configurer une erreur simulée
        mockRepository.shouldThrowError = true
        
        // When - Tenter de charger les médicaments
        await viewModel.loadMedicines()
        
        // Then - Vérifier la gestion d'erreur
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.medicines.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testAsyncOperationWithTimeout() async throws {
        // Utiliser le helper waitForAsync de BaseTestCase
        try await waitForAsync(timeout: 3) {
            // Given
            self.mockRepository.medicines = TestData.mockMedicines
            
            // When
            await self.viewModel.loadMedicines()
            
            // Then
            XCTAssertGreaterThan(self.viewModel.medicines.count, 0)
        }
    }
    
    func testPerformanceWithMeasure() async throws {
        // Given - Grande quantité de données
        let largeMedicineSet = (0..<1000).map { index in
            Medicine.mock(id: "\(index)", name: "Medicine \(index)")
        }
        mockRepository.medicines = largeMedicineSet
        
        // Mesurer les performances avec le helper de BaseTestCase
        await measureAsyncTime(description: "Loading 1000 medicines") {
            await viewModel.loadMedicines()
        }
    }
}

// MARK: - Comparaison Avant/Après

/*
 AVANT (avec Firebase et XCTestCase):
 
 class OldTest: XCTestCase {
     var cancellables: Set<AnyCancellable>!
     
     func setUp() {
         cancellables = Set<AnyCancellable>()
         // Configuration Firebase complexe
         // Timeout de 2+ minutes pour les tests
     }
     
     func testWithFirebase() async {
         // Dépendance directe à Firebase
         let service = FirebaseDataService()
         // Test lent et fragile
     }
 }
 
 APRÈS (avec BaseTestCase et Mocks):
 
 class NewTest: BaseTestCase {
     // cancellables déjà dans BaseTestCase
     
     func setUp() {
         super.setUp()
         // Mocks rapides, pas de Firebase
     }
     
     func testWithMocks() async {
         // Utilise MockDataServiceAdapter
         // Test rapide et fiable
     }
 }
*/
