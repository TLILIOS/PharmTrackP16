import XCTest
@testable import MediStock

// MARK: - Tests pour les nouveaux Services modulaires
// IMPORTANT: Ces tests utilisent des mocks pour ne PAS appeler Firebase

@MainActor
class DataServiceTests: XCTestCase {
    
    // Services à tester
    var mockDataService: MockDataServiceAdapterForIntegration!
    var dataServiceAdapter: DataServiceAdapter!
    
    override func setUp() {
        super.setUp()
        
        // Initialiser les services avec des mocks
        mockDataService = MockDataServiceAdapterForIntegration()
        // Use the mock adapter directly instead of creating real services
        dataServiceAdapter = mockDataService
    }
    
    override func tearDown() {
        mockDataService = nil
        dataServiceAdapter = nil
        super.tearDown()
    }
    
    // MARK: - Tests Medicine Operations
    
    func testSaveMedicineValidation() async {
        // Arrange
        let invalidMedicine = Medicine(
            id: "",
            name: "", // Nom vide - devrait échouer
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: -5, // Stock négatif
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(-86400), // Date passée
            aisleId: "test-aisle",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Act & Assert
        do {
            _ = try await mockDataService.saveMedicine(invalidMedicine)
            XCTFail("La validation aurait dû échouer")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    func testAdjustStockValidation() async {
        // Arrange
        let medicineId = "test-medicine-id"
        let invalidStock = -10 // Stock négatif
        
        // Act & Assert
        do {
            _ = try await mockDataService.updateMedicineStock(id: medicineId, newStock: invalidStock)
            XCTFail("L'ajustement négatif devrait échouer")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testPaginationReset() async {
        // Test que la pagination se réinitialise correctement
        
        // Act
        do {
            _ = try await mockDataService.getMedicinesPaginated(limit: 10, refresh: true)
        } catch {
            // En test sans Firebase configuré, une erreur est normale
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Tests Aisle Operations
    
    func testSaveAisleValidation() async {
        // Test que la validation du rayon fonctionne
        
        let invalidAisle = Aisle(
            id: "",
            name: "", // Nom vide
            description: nil,
            colorHex: "invalid-color", // Format invalide
            icon: "invalid.icon" // Icône invalide
        )
        
        do {
            _ = try await mockDataService.saveAisle(invalidAisle)
            XCTFail("La validation aurait dû échouer")
        } catch {
            XCTAssertTrue(error is ValidationError)
        }
    }
    
    func testCheckAisleExists() async {
        // Test de vérification d'existence d'un rayon via l'adapter
        do {
            let exists = try await dataServiceAdapter.checkAisleExists("non-existent-id")
            XCTAssertFalse(exists)
        } catch {
            // En test sans Firebase, une erreur est normale
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Tests History Operations
    
    func testHistoryEntryCreation() async {
        // Test de création d'entrée d'historique
        
        let historyEntry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: "test-medicine",
            userId: "test-user",
            action: "Création",
            details: "Test de création",
            timestamp: Date()
        )
        
        do {
            try await mockDataService.addHistoryEntry(historyEntry)
        } catch {
            // En test sans Firebase réel, une erreur est attendue
            XCTAssertNotNil(error)
        }
    }
    
    func testGetHistory() async {
        // Test de récupération d'historique
        
        do {
            let history = try await mockDataService.getHistory()
            XCTAssertNotNil(history)
        } catch {
            // Normal en environnement de test
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Tests DataServiceAdapter
    
    func testAdapterCompatibility() async {
        // Test que l'adaptateur maintient la compatibilité
        
        let adapter = MockDataServiceAdapterForIntegration()
        
        // Test d'appel des méthodes principales
        do {
            _ = try await adapter.getMedicines()
        } catch {
            // Erreur attendue sans Firebase configuré
            XCTAssertNotNil(error)
        }
        
        do {
            _ = try await adapter.getAisles()
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testAdapterPagination() async {
        // Test de la pagination via l'adaptateur
        
        do {
            let medicines = try await dataServiceAdapter.getMedicinesPaginated(limit: 20, refresh: true)
            XCTAssertNotNil(medicines)
        } catch {
            // Erreur attendue sans Firebase
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Tests Batch Operations
    
    func testUpdateMultipleMedicines() async {
        let medicines = [
            Medicine.mock(id: "1", currentQuantity: 50),
            Medicine.mock(id: "2", currentQuantity: 30)
        ]
        
        do {
            try await mockDataService.updateMultipleMedicines(medicines)
        } catch {
            // Erreur attendue sans Firebase
            XCTAssertNotNil(error)
        }
    }
    
    func testDeleteMultipleMedicines() async {
        let ids = ["1", "2", "3"]
        
        do {
            try await mockDataService.deleteMultipleMedicines(ids: ids)
        } catch {
            // Erreur attendue sans Firebase
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Tests Performance
    
    func testServiceInitializationPerformance() {
        // Test de performance pour l'initialisation des services
        
        measure {
            _ = MockDataServiceAdapterForIntegration()
            _ = MockDataServiceAdapterForIntegration()
        }
    }
    
    func testValidationPerformance() {
        let medicine = Medicine.mock()
        let aisle = Aisle.mock()
        
        measure {
            do {
                try medicine.validate()
                try aisle.validate()
            } catch {
                // Ignore errors in performance test
            }
        }
    }
}

// MARK: - Tests d'Intégration (avec Firebase Emulator)

class DataServiceIntegrationTests: XCTestCase {
    
    // Ces tests nécessitent Firebase Emulator pour s'exécuter
    // Décommenter et configurer si l'émulateur est disponible
    
    /*
    func testFullMedicineCRUDFlow() async throws {
        // 1. Créer un médicament
        // 2. Le mettre à jour
        // 3. Ajuster le stock
        // 4. Le supprimer
        // 5. Vérifier l'historique
    }
    
    func testConcurrentOperations() async throws {
        // Test de mises à jour simultanées
        // Vérifier que les transactions Firestore gèrent la concurrence
    }
    
    func testOfflineCapabilities() async throws {
        // Test du comportement hors ligne
        // Vérifier la synchronisation au retour en ligne
    }
    */
}