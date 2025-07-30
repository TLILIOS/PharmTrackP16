import XCTest
@testable import MediStock

// MARK: - Tests d'intégration pour valider les workflows avec validation

final class ValidationIntegrationTests: XCTestCase {
    
    var dataService: DataServiceRefactored!
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        dataService = DataServiceRefactored()
        appState = AppState()
    }
    
    override func tearDown() async throws {
        dataService = nil
        appState = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests Workflow Rayon
    
    func testCreateAisleWorkflow_ValidData() async throws {
        // Données valides
        let validAisle = Aisle(
            id: "",
            name: "Pharmacie Principale",
            description: "Médicaments courants",
            colorHex: "#4CAF50",
            icon: "pills.fill"
        )
        
        do {
            let saved = try await appState.saveAisle(validAisle)
            XCTAssertFalse(saved.id.isEmpty)
            XCTAssertEqual(saved.name, "Pharmacie Principale")
            XCTAssertTrue(appState.aisles.contains { $0.id == saved.id })
        } catch {
            XCTFail("Valid aisle should be saved: \(error)")
        }
    }
    
    func testCreateAisleWorkflow_InvalidData() async throws {
        // Test 1: Nom vide
        let emptyNameAisle = Aisle(id: "", name: "", description: nil, colorHex: "#FF0000", icon: "pills")
        
        await appState.saveAisle(emptyNameAisle)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("nom") ?? false)
        
        // Reset error
        appState.clearError()
        
        // Test 2: Couleur invalide
        let invalidColorAisle = Aisle(id: "", name: "Test", description: nil, colorHex: "rouge", icon: "pills")
        
        await appState.saveAisle(invalidColorAisle)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("couleur") ?? false)
        
        // Reset error
        appState.clearError()
        
        // Test 3: Icône invalide
        let invalidIconAisle = Aisle(id: "", name: "Test", description: nil, colorHex: "#FF0000", icon: "custom.icon")
        
        await appState.saveAisle(invalidIconAisle)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("icône") ?? false)
    }
    
    func testCreateAisleWorkflow_DuplicateName() async throws {
        // Créer un premier rayon
        let firstAisle = Aisle(
            id: "",
            name: "Antibiotiques",
            description: nil,
            colorHex: "#2196F3",
            icon: "cross.case"
        )
        
        _ = try await appState.saveAisle(firstAisle)
        
        // Tenter de créer un rayon avec le même nom
        let duplicateAisle = Aisle(
            id: "",
            name: "Antibiotiques", // Même nom!
            description: nil,
            colorHex: "#FF9800",
            icon: "bandage"
        )
        
        await appState.saveAisle(duplicateAisle)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("existe déjà") ?? false)
    }
    
    // MARK: - Tests Workflow Médicament
    
    func testCreateMedicineWorkflow_ValidData() async throws {
        // Créer d'abord un rayon valide
        let aisle = Aisle(
            id: "",
            name: "Antalgiques",
            description: nil,
            colorHex: "#9C27B0",
            icon: "pills"
        )
        let savedAisle = try await appState.saveAisle(aisle)
        
        // Créer un médicament valide
        let validMedicine = Medicine(
            id: "",
            name: "Paracétamol 500mg",
            description: "Antalgique et antipyrétique",
            dosage: "500mg",
            form: "Comprimé",
            reference: "PARA500",
            unit: "boîte",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60), // 1 an
            aisleId: savedAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            let saved = try await appState.saveMedicine(validMedicine)
            XCTAssertFalse(saved.id.isEmpty)
            XCTAssertEqual(saved.name, "Paracétamol 500mg")
            XCTAssertTrue(appState.medicines.contains { $0.id == saved.id })
        } catch {
            XCTFail("Valid medicine should be saved: \(error)")
        }
    }
    
    func testCreateMedicineWorkflow_InvalidThresholds() async throws {
        // Créer un rayon valide d'abord
        let aisle = Aisle(
            id: "",
            name: "Test Rayon",
            description: nil,
            colorHex: "#FF5722",
            icon: "cross.case"
        )
        let savedAisle = try await appState.saveAisle(aisle)
        
        // Médicament avec seuils invalides (critical > warning)
        let invalidMedicine = Medicine(
            id: "",
            name: "Test Médicament",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 30, // Invalide!
            expiryDate: nil,
            aisleId: savedAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await appState.saveMedicine(invalidMedicine)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("seuil") ?? false)
    }
    
    func testCreateMedicineWorkflow_ExpiredDate() async throws {
        // Créer un rayon valide
        let aisle = Aisle(
            id: "",
            name: "Périmés",
            description: nil,
            colorHex: "#607D8B",
            icon: "exclamationmark.triangle"
        )
        let savedAisle = try await appState.saveAisle(aisle)
        
        // Médicament avec date d'expiration passée
        let expiredMedicine = Medicine(
            id: "",
            name: "Médicament Périmé",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "flacon",
            currentQuantity: 10,
            maxQuantity: 50,
            warningThreshold: 15,
            criticalThreshold: 5,
            expiryDate: Date().addingTimeInterval(-86400), // Hier
            aisleId: savedAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await appState.saveMedicine(expiredMedicine)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("expiration") ?? false)
    }
    
    func testCreateMedicineWorkflow_InvalidAisleReference() async throws {
        // Médicament avec référence de rayon inexistante
        let medicineWithInvalidAisle = Medicine(
            id: "",
            name: "Médicament Orphelin",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "tube",
            currentQuantity: 20,
            maxQuantity: 100,
            warningThreshold: 15,
            criticalThreshold: 5,
            expiryDate: nil,
            aisleId: "non-existent-aisle-id",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        await appState.saveMedicine(medicineWithInvalidAisle)
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.errorMessage?.contains("rayon") ?? false)
    }
    
    // MARK: - Tests d'ajustement de stock
    
    func testAdjustStockWorkflow_Valid() async throws {
        // Créer un rayon et un médicament
        let aisle = Aisle(
            id: "",
            name: "Stock Test",
            description: nil,
            colorHex: "#3F51B5",
            icon: "tray"
        )
        let savedAisle = try await appState.saveAisle(aisle)
        
        let medicine = Medicine(
            id: "",
            name: "Test Stock",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "unité",
            currentQuantity: 50,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: savedAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        let savedMedicine = try await appState.saveMedicine(medicine)
        
        // Ajustement positif
        await appState.adjustStock(medicine: savedMedicine, adjustment: 10, reason: "Réception commande")
        
        if let updated = appState.medicines.first(where: { $0.id == savedMedicine.id }) {
            XCTAssertEqual(updated.currentQuantity, 60)
        } else {
            XCTFail("Medicine should be found after stock adjustment")
        }
        
        // Ajustement négatif
        await appState.adjustStock(medicine: savedMedicine, adjustment: -25, reason: "Vente")
        
        if let updated = appState.medicines.first(where: { $0.id == savedMedicine.id }) {
            XCTAssertEqual(updated.currentQuantity, 35) // 60 - 25
        }
    }
    
    func testAdjustStockWorkflow_NegativeResult() async throws {
        // Créer un rayon et un médicament avec peu de stock
        let aisle = Aisle(
            id: "",
            name: "Stock Faible",
            description: nil,
            colorHex: "#795548",
            icon: "exclamationmark.circle"
        )
        let savedAisle = try await appState.saveAisle(aisle)
        
        let medicine = Medicine(
            id: "",
            name: "Stock Faible",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "unité",
            currentQuantity: 5,
            maxQuantity: 100,
            warningThreshold: 20,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: savedAisle.id,
            createdAt: Date(),
            updatedAt: Date()
        )
        let savedMedicine = try await appState.saveMedicine(medicine)
        
        // Tentative d'ajustement qui rendrait le stock négatif
        await appState.adjustStock(medicine: savedMedicine, adjustment: -10, reason: "Sortie excessive")
        
        // Le stock devrait être à 0, pas négatif
        if let updated = appState.medicines.first(where: { $0.id == savedMedicine.id }) {
            XCTAssertEqual(updated.currentQuantity, 0)
            XCTAssertGreaterThanOrEqual(updated.currentQuantity, 0)
        }
    }
    
    // MARK: - Tests de performance
    
    func testValidationPerformance() throws {
        let aisle = Aisle(
            id: "",
            name: "Performance Test",
            description: "Test de performance de validation",
            colorHex: "#000000",
            icon: "speedometer"
        )
        
        let medicine = Medicine(
            id: "",
            name: "Medicine Performance",
            description: "Test",
            dosage: "100mg",
            form: "Comprimé",
            reference: "PERF001",
            unit: "boîte",
            currentQuantity: 100,
            maxQuantity: 200,
            warningThreshold: 50,
            criticalThreshold: 25,
            expiryDate: Date().addingTimeInterval(86400),
            aisleId: "test-id",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // Mesurer la performance de validation
        measure {
            do {
                try aisle.validate()
                try medicine.validate()
            } catch {
                XCTFail("Validation should pass")
            }
        }
    }
}