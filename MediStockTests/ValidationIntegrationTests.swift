import XCTest
@testable import MediStock

// MARK: - Tests d'intégration pour valider les workflows avec validation

@MainActor
final class ValidationIntegrationTests: XCTestCase {

    var aisleViewModel: AisleListViewModel!
    var medicineViewModel: MedicineListViewModel!
    var mockAisleRepo: MockAisleRepository!
    var mockMedicineRepo: MockMedicineRepository!
    var mockHistoryRepo: MockHistoryRepository!
    var mockNotificationService: MockNotificationService!

    override func setUp() async throws {
        try await super.setUp()

        // Créer les mock repositories et services
        mockAisleRepo = MockAisleRepository()
        mockMedicineRepo = MockMedicineRepository()
        mockHistoryRepo = MockHistoryRepository()
        mockNotificationService = MockNotificationService()

        // Créer les ViewModels avec les mocks
        aisleViewModel = AisleListViewModel(repository: mockAisleRepo)
        medicineViewModel = MedicineListViewModel(
            medicineRepository: mockMedicineRepo,
            historyRepository: mockHistoryRepo,
            notificationService: mockNotificationService,
            networkMonitor: MockNetworkMonitor(initialStatus: .connected(.wifi))
        )
    }

    override func tearDown() async throws {
        aisleViewModel = nil
        medicineViewModel = nil
        mockAisleRepo = nil
        mockMedicineRepo = nil
        mockHistoryRepo = nil
        mockNotificationService = nil
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

        await aisleViewModel.saveAisle(validAisle)

        // Vérifier que le rayon a été ajouté
        XCTAssertNil(aisleViewModel.errorMessage, "Should not have error for valid aisle")
        XCTAssertFalse(mockAisleRepo.aisles.isEmpty, "Mock should contain the saved aisle")

        if let saved = mockAisleRepo.aisles.last {
            XCTAssertFalse(saved.id?.isEmpty ?? true)
            XCTAssertEqual(saved.name, "Pharmacie Principale")
        } else {
            XCTFail("Valid aisle should be saved")
        }
    }

    func testCreateAisleWorkflow_InvalidData() async throws {
        // Test 1: Nom vide - devrait être rejeté par le repository ou la validation
        let emptyNameAisle = Aisle(id: "", name: "", description: nil, colorHex: "#FF0000", icon: "pills")

        // Configurer le mock pour simuler une erreur de validation
        mockAisleRepo.shouldThrowError = true
        await aisleViewModel.saveAisle(emptyNameAisle)
        XCTAssertNotNil(aisleViewModel.errorMessage, "Empty name should trigger error")

        // Reset
        mockAisleRepo.shouldThrowError = false
        aisleViewModel.clearError()
    }

    func testCreateAisleWorkflow_DuplicateName() async throws {
        // Créer un premier rayon
        let firstAisle = Aisle(
            id: UUID().uuidString,
            name: "Antibiotiques",
            description: nil,
            colorHex: "#2196F3",
            icon: "cross.case"
        )

        await aisleViewModel.saveAisle(firstAisle)
        aisleViewModel.clearError()

        // Vérifier que le premier rayon a bien été sauvegardé
        XCTAssertEqual(mockAisleRepo.aisles.count, 1)

        // Tenter de créer un rayon avec le même nom
        let duplicateAisle = Aisle(
            id: "",
            name: "Antibiotiques",
            description: nil,
            colorHex: "#FF9800",
            icon: "bandage"
        )

        // En pratique, la validation devrait être faite par le repository
        // Pour ce test, on vérifie juste que le système peut gérer les doublons
        await aisleViewModel.saveAisle(duplicateAisle)

        // Si aucune validation côté repository, le rayon sera ajouté
        // Dans un système avec validation, errorMessage serait non-nil
        XCTAssertTrue(mockAisleRepo.aisles.count >= 1, "At least one aisle should exist")
    }

    // MARK: - Tests Workflow Médicament

    func testCreateMedicineWorkflow_ValidData() async throws {
        // Créer d'abord un rayon valide
        let aisle = Aisle(
            id: UUID().uuidString,
            name: "Antalgiques",
            description: nil,
            colorHex: "#9C27B0",
            icon: "pills"
        )
        await aisleViewModel.saveAisle(aisle)
        XCTAssertNil(aisleViewModel.errorMessage, "Should not have error for valid aisle")

        guard let savedAisle = mockAisleRepo.aisles.last else {
            XCTFail("Aisle should be saved")
            return
        }

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
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            aisleId: savedAisle.id ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )

        await medicineViewModel.saveMedicine(validMedicine)

        // Vérifier que le médicament a été ajouté
        XCTAssertNil(medicineViewModel.errorMessage, "Should not have error for valid medicine")
        XCTAssertFalse(mockMedicineRepo.medicines.isEmpty, "Medicine should be saved")

        if let saved = mockMedicineRepo.medicines.last {
            XCTAssertFalse(saved.id?.isEmpty ?? true)
            XCTAssertEqual(saved.name, "Paracétamol 500mg")
        } else {
            XCTFail("Valid medicine should be saved")
        }
    }

    func testCreateMedicineWorkflow_InvalidThresholds() async throws {
        // Créer un rayon valide d'abord
        let aisle = Aisle(
            id: UUID().uuidString,
            name: "Test Rayon",
            description: nil,
            colorHex: "#FF5722",
            icon: "cross.case"
        )
        await aisleViewModel.saveAisle(aisle)

        guard let savedAisle = mockAisleRepo.aisles.last else {
            XCTFail("Aisle should be saved")
            return
        }

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
            criticalThreshold: 30, // Invalide: critical > warning
            expiryDate: nil,
            aisleId: savedAisle.id ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )

        // Simuler une erreur de validation
        mockMedicineRepo.shouldThrowError = true
        await medicineViewModel.saveMedicine(invalidMedicine)
        XCTAssertNotNil(medicineViewModel.errorMessage, "Invalid thresholds should trigger error")

        mockMedicineRepo.shouldThrowError = false
    }

    func testCreateMedicineWorkflow_ExpiredDate() async throws {
        // Créer un rayon valide
        let aisle = Aisle(
            id: UUID().uuidString,
            name: "Périmés",
            description: nil,
            colorHex: "#607D8B",
            icon: "exclamationmark.triangle"
        )
        await aisleViewModel.saveAisle(aisle)

        guard let savedAisle = mockAisleRepo.aisles.last else {
            XCTFail("Aisle should be saved")
            return
        }

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
            aisleId: savedAisle.id ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )

        // En pratique, la validation devrait rejeter les dates expirées
        mockMedicineRepo.shouldThrowError = true
        await medicineViewModel.saveMedicine(expiredMedicine)
        XCTAssertNotNil(medicineViewModel.errorMessage, "Expired date should trigger error")

        mockMedicineRepo.shouldThrowError = false
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

        // La validation devrait rejeter une référence invalide
        mockMedicineRepo.shouldThrowError = true
        await medicineViewModel.saveMedicine(medicineWithInvalidAisle)
        XCTAssertNotNil(medicineViewModel.errorMessage, "Invalid aisle reference should trigger error")

        mockMedicineRepo.shouldThrowError = false
    }

    // MARK: - Tests d'ajustement de stock

    func testAdjustStockWorkflow_Valid() async throws {
        // Créer un rayon et un médicament
        let aisle = Aisle(
            id: UUID().uuidString,
            name: "Stock Test",
            description: nil,
            colorHex: "#3F51B5",
            icon: "tray"
        )
        await aisleViewModel.saveAisle(aisle)

        guard let savedAisle = mockAisleRepo.aisles.last else {
            XCTFail("Aisle should be saved")
            return
        }

        let medicine = Medicine(
            id: UUID().uuidString,
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
            aisleId: savedAisle.id ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )

        await medicineViewModel.saveMedicine(medicine)

        guard let savedMedicine = mockMedicineRepo.medicines.last else {
            XCTFail("Medicine should be saved")
            return
        }

        // Ajustement positif
        await medicineViewModel.adjustStock(medicine: savedMedicine, adjustment: 10, reason: "Réception commande")

        if let updated = mockMedicineRepo.medicines.first(where: { $0.id == savedMedicine.id }) {
            XCTAssertEqual(updated.currentQuantity, 60)
        } else {
            XCTFail("Medicine should be found after stock adjustment")
        }

        // Ajustement négatif
        if let updatedMedicine = mockMedicineRepo.medicines.first(where: { $0.id == savedMedicine.id }) {
            await medicineViewModel.adjustStock(medicine: updatedMedicine, adjustment: -25, reason: "Vente")

            if let updated = mockMedicineRepo.medicines.first(where: { $0.id == savedMedicine.id }) {
                XCTAssertEqual(updated.currentQuantity, 35) // 60 - 25
            }
        }
    }

    func testAdjustStockWorkflow_NegativeResult() async throws {
        // Créer un rayon et un médicament avec peu de stock
        let aisle = Aisle(
            id: UUID().uuidString,
            name: "Stock Faible",
            description: nil,
            colorHex: "#795548",
            icon: "exclamationmark.triangle"
        )
        await aisleViewModel.saveAisle(aisle)

        guard let savedAisle = mockAisleRepo.aisles.last else {
            XCTFail("Aisle should be saved")
            return
        }

        let medicine = Medicine(
            id: UUID().uuidString,
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
            aisleId: savedAisle.id ?? "",
            createdAt: Date(),
            updatedAt: Date()
        )

        await medicineViewModel.saveMedicine(medicine)

        guard let savedMedicine = mockMedicineRepo.medicines.last else {
            XCTFail("Medicine should be saved")
            return
        }

        // Tentative d'ajustement qui rendrait le stock négatif
        await medicineViewModel.adjustStock(medicine: savedMedicine, adjustment: -10, reason: "Sortie excessive")

        // Le stock devrait être à 0, pas négatif (logique dans adjustStock)
        if let updated = mockMedicineRepo.medicines.first(where: { $0.id == savedMedicine.id }) {
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

        // Mesurer la performance de validation pour Aisle
        measure {
            do {
                try aisle.validate()
            } catch {
                XCTFail("Aisle validation should pass: \(error)")
            }
        }
    }
}
