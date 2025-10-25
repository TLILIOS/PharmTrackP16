import XCTest
import Combine
@testable import MediStock

// MARK: - Exemple de Test Migré avec Mocks

/// Ce fichier montre un exemple complet de test unitaire utilisant les nouveaux mocks
/// au lieu d'appeler Firebase directement

@MainActor
final class ExampleMigratedViewModelTest: XCTestCase {

    // MARK: - Properties

    var authViewModel: AuthViewModel!
    var medicineViewModel: MedicineListViewModel!

    var mockAuthService: MockAuthService!
    var mockDataService: MockDataService!

    var cancellables: Set<AnyCancellable>!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()

        // Créer les mocks
        mockAuthService = MockAuthService()
        mockDataService = MockDataService()

        // Configurer avec des données de test
        mockDataService.seedTestData()

        // Injecter les mocks dans les ViewModels
        authViewModel = AuthViewModel(authService: mockAuthService)
        medicineViewModel = MedicineListViewModel(dataService: mockDataService)

        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        authViewModel = nil
        medicineViewModel = nil
        mockAuthService = nil
        mockDataService = nil
        super.tearDown()
    }

    // MARK: - Tests d'Authentification

    func testSignInSuccess() async throws {
        // Given - Configuration du test
        let email = "test@example.com"
        let password = "SecurePassword123"

        // When - Exécution de l'action
        try await authViewModel.signIn(email: email, password: password)

        // Then - Vérifications
        XCTAssertEqual(mockAuthService.signInCallCount, 1, "Sign in devrait être appelé une fois")
        XCTAssertEqual(mockAuthService.lastSignInEmail, email, "L'email devrait correspondre")
        XCTAssertNotNil(mockAuthService.currentUser, "Un utilisateur devrait être connecté")
        XCTAssertEqual(authViewModel.isAuthenticated, true, "L'utilisateur devrait être authentifié")
        XCTAssertNil(authViewModel.errorMessage, "Aucune erreur ne devrait être présente")
    }

    func testSignInWithInvalidCredentials() async {
        // Given - Configurer le mock pour échouer
        mockAuthService.shouldFailSignIn = true
        let email = "wrong@example.com"
        let password = "wrongpassword"

        // When & Then
        do {
            try await authViewModel.signIn(email: email, password: password)
            XCTFail("La connexion devrait échouer avec des credentials invalides")
        } catch {
            // Vérifier que l'erreur est bien levée
            XCTAssertNotNil(error, "Une erreur devrait être levée")
            XCTAssertEqual(mockAuthService.signInCallCount, 1, "Sign in devrait être appelé une fois")
            XCTAssertNil(mockAuthService.currentUser, "Aucun utilisateur ne devrait être connecté")
            XCTAssertEqual(authViewModel.isAuthenticated, false, "L'utilisateur ne devrait pas être authentifié")
        }
    }

    func testSignOutSuccess() async throws {
        // Given - Connecter d'abord un utilisateur
        let testUser = User(id: "test-123", email: "test@example.com", displayName: "Test User")
        mockAuthService.setMockUser(testUser)
        authViewModel.currentUser = testUser

        // When
        try await authViewModel.signOut()

        // Then
        XCTAssertEqual(mockAuthService.signOutCallCount, 1, "Sign out devrait être appelé une fois")
        XCTAssertNil(mockAuthService.currentUser, "L'utilisateur devrait être déconnecté")
        XCTAssertEqual(authViewModel.isAuthenticated, false, "Le statut devrait être non authentifié")
    }

    func testResetPassword() async throws {
        // Given
        let email = "reset@example.com"

        // When
        try await authViewModel.resetPassword(email: email)

        // Then
        XCTAssertEqual(mockAuthService.resetPasswordCallCount, 1, "Reset password devrait être appelé")
        XCTAssertEqual(mockAuthService.lastResetPasswordEmail, email, "L'email devrait correspondre")
    }

    // MARK: - Tests de Gestion des Médicaments

    func testFetchMedicinesSuccess() async throws {
        // Given - Les données sont déjà chargées via seedTestData()
        XCTAssertEqual(mockDataService.medicines.count, 1, "Devrait avoir 1 médicament de test")

        // When
        try await medicineViewModel.fetchMedicines()

        // Then
        XCTAssertEqual(mockDataService.getMedicinesCallCount, 1, "Get medicines devrait être appelé une fois")
        XCTAssertEqual(medicineViewModel.medicines.count, 1, "Devrait avoir 1 médicament dans le ViewModel")
        XCTAssertEqual(medicineViewModel.medicines.first?.name, "Doliprane 500mg")
        XCTAssertFalse(medicineViewModel.isLoading, "Le chargement devrait être terminé")
        XCTAssertNil(medicineViewModel.errorMessage, "Aucune erreur ne devrait être présente")
    }

    func testFetchMedicinesWithNetworkError() async {
        // Given - Configurer le mock pour échouer
        mockDataService.shouldFailGetMedicines = true

        // When & Then
        do {
            try await medicineViewModel.fetchMedicines()
            XCTFail("Devrait échouer avec une erreur réseau")
        } catch {
            XCTAssertNotNil(error, "Une erreur devrait être levée")
            XCTAssertEqual(medicineViewModel.medicines.count, 0, "Aucun médicament ne devrait être chargé")
            XCTAssertNotNil(medicineViewModel.errorMessage, "Un message d'erreur devrait être présent")
        }
    }

    func testSaveMedicineSuccess() async throws {
        // Given - Créer un nouveau médicament
        let newMedicine = Medicine(
            id: "", // Empty ID pour création
            name: "Aspirine 500mg",
            description: "Anti-inflammatoire",
            dosage: "500mg",
            form: "comprimé",
            reference: "ASP500",
            unit: "comprimés",
            currentQuantity: 150,
            maxQuantity: 500,
            warningThreshold: 100,
            criticalThreshold: 50,
            expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
            aisleId: "aisle-1", // Référence au rayon existant
            createdAt: Date(),
            updatedAt: Date()
        )

        // When
        let savedMedicine = try await medicineViewModel.saveMedicine(newMedicine)

        // Then
        XCTAssertEqual(mockDataService.saveMedicineCallCount, 1, "Save medicine devrait être appelé une fois")
        XCTAssertFalse(savedMedicine.id.isEmpty, "Un ID devrait être généré")
        XCTAssertEqual(savedMedicine.name, "Aspirine 500mg")
        XCTAssertEqual(mockDataService.medicines.count, 2, "Devrait avoir 2 médicaments maintenant")

        // Vérifier l'historique
        let history = try await mockDataService.getHistory()
        let creationEntry = history.first { $0.action == "Création" }
        XCTAssertNotNil(creationEntry, "Une entrée d'historique devrait être créée")
    }

    func testUpdateMedicineStock() async throws {
        // Given - Utiliser le médicament de test existant
        let medicine = mockDataService.medicines.first!
        let originalStock = medicine.currentQuantity
        let newStock = 75

        // When
        let updatedMedicine = try await medicineViewModel.updateStock(
            for: medicine.id,
            newStock: newStock
        )

        // Then
        XCTAssertEqual(mockDataService.updateStockCallCount, 1, "Update stock devrait être appelé une fois")
        XCTAssertEqual(updatedMedicine.currentQuantity, newStock, "Le stock devrait être mis à jour")
        XCTAssertNotEqual(updatedMedicine.currentQuantity, originalStock, "Le stock devrait avoir changé")

        // Vérifier l'historique
        let history = try await mockDataService.getHistory()
        let stockEntry = history.first { $0.action == "Ajout stock" }
        XCTAssertNotNil(stockEntry, "Une entrée d'historique de stock devrait être créée")
    }

    func testDeleteMedicine() async throws {
        // Given
        let medicine = mockDataService.medicines.first!
        let initialCount = mockDataService.medicines.count

        // When
        try await medicineViewModel.deleteMedicine(id: medicine.id)

        // Then
        XCTAssertEqual(mockDataService.deleteMedicineCallCount, 1, "Delete medicine devrait être appelé une fois")
        XCTAssertEqual(mockDataService.medicines.count, initialCount - 1, "Un médicament devrait être supprimé")
        XCTAssertFalse(mockDataService.medicines.contains { $0.id == medicine.id }, "Le médicament ne devrait plus exister")

        // Vérifier l'historique
        let history = try await mockDataService.getHistory()
        let deletionEntry = history.first { $0.action == "Suppression" }
        XCTAssertNotNil(deletionEntry, "Une entrée d'historique de suppression devrait être créée")
    }

    // MARK: - Tests de Validation

    func testSaveMedicineWithInvalidData() async {
        // Given - Médicament avec nom vide (invalide)
        let invalidMedicine = Medicine(
            id: "",
            name: "", // Nom vide = invalide
            description: nil,
            dosage: "500mg",
            form: "comprimé",
            reference: "INV500",
            unit: "comprimés",
            currentQuantity: 100,
            maxQuantity: 500,
            warningThreshold: 50,
            criticalThreshold: 20,
            expiryDate: nil,
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )

        // When & Then
        do {
            _ = try await medicineViewModel.saveMedicine(invalidMedicine)
            XCTFail("Devrait échouer avec des données invalides")
        } catch let error as ValidationError {
            XCTAssertTrue(true, "Une erreur de validation devrait être levée")
            XCTAssertEqual(mockDataService.saveMedicineCallCount, 1, "La validation est côté service")
        } catch {
            XCTFail("Devrait lever une ValidationError, pas \(error)")
        }
    }

    func testUpdateStockWithNegativeValue() async {
        // Given
        let medicine = mockDataService.medicines.first!
        let negativeStock = -10

        // When & Then
        do {
            _ = try await medicineViewModel.updateStock(for: medicine.id, newStock: negativeStock)
            XCTFail("Ne devrait pas accepter un stock négatif")
        } catch let error as ValidationError {
            if case .negativeQuantity = error {
                XCTAssertTrue(true, "Une erreur de quantité négative devrait être levée")
            } else {
                XCTFail("Devrait lever une erreur negativeQuantity")
            }
        } catch {
            XCTFail("Devrait lever une ValidationError, pas \(error)")
        }
    }

    // MARK: - Tests de Listeners en Temps Réel

    func testRealtimeListenerNotifiesChanges() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Listener devrait être notifié")
        var receivedMedicines: [Medicine] = []

        // Démarrer le listener
        mockDataService.startListeningToMedicines { medicines in
            receivedMedicines = medicines
            expectation.fulfill()
        }

        // When - Ajouter un nouveau médicament
        let newMedicine = Medicine(
            id: "new-med",
            name: "Nouveau Médicament",
            description: nil,
            dosage: "100mg",
            form: "gélule",
            reference: "NEW100",
            unit: "gélules",
            currentQuantity: 50,
            maxQuantity: 200,
            warningThreshold: 30,
            criticalThreshold: 10,
            expiryDate: nil,
            aisleId: "aisle-1",
            createdAt: Date(),
            updatedAt: Date()
        )

        _ = try await mockDataService.saveMedicine(newMedicine)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(mockDataService.isListening, "Le listener devrait être actif")
        XCTAssertEqual(receivedMedicines.count, 2, "Devrait recevoir les médicaments mis à jour")

        // Cleanup
        mockDataService.stopListening()
        XCTAssertFalse(mockDataService.isListening, "Le listener devrait être arrêté")
    }

    // MARK: - Tests de Performance

    func testFetchMedicinesPerformance() {
        // Given - Ajouter beaucoup de médicaments
        for i in 0..<100 {
            let medicine = Medicine(
                id: "med-\(i)",
                name: "Medicine \(i)",
                description: nil,
                dosage: "100mg",
                form: "comprimé",
                reference: "REF\(i)",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 500,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: nil,
                aisleId: "aisle-1",
                createdAt: Date(),
                updatedAt: Date()
            )
            mockDataService.medicines.append(medicine)
        }

        // When & Then - Mesurer la performance
        measure {
            Task {
                do {
                    try await medicineViewModel.fetchMedicines()
                } catch {
                    XCTFail("Fetch ne devrait pas échouer: \(error)")
                }
            }
        }
    }

    // MARK: - Tests de Concurrence

    func testConcurrentStockUpdates() async throws {
        // Given
        let medicine = mockDataService.medicines.first!

        // When - Plusieurs mises à jour en parallèle
        async let update1 = medicineViewModel.updateStock(for: medicine.id, newStock: 90)
        async let update2 = medicineViewModel.updateStock(for: medicine.id, newStock: 80)
        async let update3 = medicineViewModel.updateStock(for: medicine.id, newStock: 70)

        // Then - Toutes les mises à jour devraient se terminer sans erreur
        let results = try await [update1, update2, update3]
        XCTAssertEqual(results.count, 3, "Les 3 mises à jour devraient réussir")
        XCTAssertEqual(mockDataService.updateStockCallCount, 3, "Devrait avoir 3 appels")
    }
}

// MARK: - Exemple de ViewModel pour les Tests

/// Example simple de ViewModel pour démontrer l'injection de dépendances
@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func signIn(email: String, password: String) async throws {
        do {
            try await authService.signIn(email: email, password: password)
            currentUser = authService.currentUser
            isAuthenticated = currentUser != nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func signOut() async throws {
        try await authService.signOut()
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws {
        try await authService.resetPassword(email: email)
    }
}

@MainActor
class MedicineListViewModel: ObservableObject {
    @Published var medicines: [Medicine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    func fetchMedicines() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            medicines = try await dataService.getMedicines()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        do {
            let saved = try await dataService.saveMedicine(medicine)
            // Rafraîchir la liste
            try await fetchMedicines()
            return saved
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func updateStock(for id: String, newStock: Int) async throws -> Medicine {
        do {
            let updated = try await dataService.updateMedicineStock(id: id, newStock: newStock)
            // Mettre à jour la liste locale
            if let index = medicines.firstIndex(where: { $0.id == id }) {
                medicines[index] = updated
            }
            return updated
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func deleteMedicine(id: String) async throws {
        try await dataService.deleteMedicine(id: id)
        medicines.removeAll { $0.id == id }
    }
}
