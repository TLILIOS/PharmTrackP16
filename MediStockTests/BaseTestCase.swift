import XCTest
import Combine
@testable import MediStock

/// Classe de base pour tous les tests unitaires
/// Fournit une configuration commune et des utilitaires pour les tests
@MainActor
class BaseTestCase: XCTestCase {

    /// Set pour stocker les subscriptions Combine
    var cancellables: Set<AnyCancellable>!

    /// Configuration globale exécutée une seule fois avant tous les tests
    override class func setUp() {
        super.setUp()

        // Configurer l'environnement de test
        TestConfiguration.configureTestEnvironment()

        // Configurer Firebase seulement si nécessaire
        if !TestConfiguration.isUnitTestMode {
            TestConfiguration.setupFirebaseForTesting()
        }
    }

    /// Configuration exécutée avant chaque test
    override func setUp() {
        super.setUp()

        // Initialiser le set de cancellables
        cancellables = Set<AnyCancellable>()

        // Nettoyer UserDefaults pour avoir un état propre
        clearUserDefaults()

        // Configurer les timeouts par défaut
        continueAfterFailure = false
    }

    /// Nettoyage exécuté après chaque test
    override func tearDown() {
        // Annuler toutes les subscriptions Combine
        cancellables?.forEach { $0.cancel() }
        cancellables = nil

        // Nettoyer UserDefaults
        clearUserDefaults()

        super.tearDown()
    }

    /// Nettoyage global après tous les tests
    override class func tearDown() {
        super.tearDown()

        // Nettoyer Firebase si configuré
        if !TestConfiguration.isUnitTestMode {
            Task {
                await TestConfiguration.tearDownFirebase()
            }
        }
    }

    // MARK: - Utilitaires de Test

    /// Timeout par défaut pour les tests unitaires
    var defaultTimeout: TimeInterval { 5.0 }

    /// Timeout pour les opérations réseau
    var networkTimeout: TimeInterval { 10.0 }

    /// Attend qu'une expectation soit remplie avec le timeout par défaut
    func waitForExpectation(
        _ expectation: XCTestExpectation,
        timeout: TimeInterval? = nil
    ) {
        wait(for: [expectation], timeout: timeout ?? defaultTimeout)
    }

    /// Attend plusieurs expectations avec options personnalisées
    func waitForMultipleExpectations(
        _ expectations: [XCTestExpectation],
        timeout: TimeInterval? = nil,
        enforceOrder: Bool = false
    ) {
        if enforceOrder {
            wait(for: expectations, timeout: timeout ?? defaultTimeout, enforceOrder: true)
        } else {
            wait(for: expectations, timeout: timeout ?? defaultTimeout)
        }
    }

    /// Utilitaire pour attendre une opération async
    func waitForAsync(
        timeout: TimeInterval? = nil,
        operation: @escaping () async throws -> Void
    ) async throws {
        let expectation = expectation(description: "Async operation")

        Task {
            do {
                try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: timeout ?? defaultTimeout)
    }

    /// Vérifie qu'une closure throws une erreur spécifique
    func assertThrows<T, E: Error>(
        _ expression: @autoclosure () throws -> T,
        error expectedError: E,
        file: StaticString = #file,
        line: UInt = #line
    ) where E: Equatable {
        do {
            _ = try expression()
            XCTFail("Expected error \(expectedError) but no error was thrown", file: file, line: line)
        } catch let caughtError as E {
            XCTAssertEqual(caughtError, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected error \(expectedError) but got \(error)", file: file, line: line)
        }
    }

    /// Vérifie qu'une closure async throws une erreur
    func assertAsyncThrows<T>(
        _ expression: @escaping () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error but no error was thrown", file: file, line: line)
        } catch {
            // Success - an error was thrown
        }
    }

    /// Nettoie UserDefaults pour les tests
    private func clearUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Mock Helpers

    /// Crée un mock repository avec des données par défaut
    func createMockMedicineRepository(
        medicines: [Medicine] = TestData.mockMedicines
    ) -> MockMedicineRepository {
        let repo = MockMedicineRepository()
        repo.medicines = medicines
        return repo
    }

    /// Crée un mock aisle repository
    func createMockAisleRepository(
        aisles: [Aisle] = TestData.mockAisles
    ) -> MockAisleRepository {
        let repo = MockAisleRepository()
        repo.aisles = aisles
        return repo
    }

    /// Crée un mock history repository
    func createMockHistoryRepository(
        history: [HistoryEntry] = []
    ) -> MockHistoryRepository {
        let repo = MockHistoryRepository()
        repo.history = history
        return repo
    }

    // MARK: - Performance Testing

    /// Mesure le temps d'exécution d'un bloc de code
    func measureTime(
        description: String,
        block: () throws -> Void
    ) rethrows {
        let start = CFAbsoluteTimeGetCurrent()
        try block()
        let end = CFAbsoluteTimeGetCurrent()
        let elapsed = end - start
    }

    /// Mesure le temps d'exécution d'un bloc async
    func measureAsyncTime(
        description: String,
        block: () async throws -> Void
    ) async rethrows {
        let start = CFAbsoluteTimeGetCurrent()
        try await block()
        let end = CFAbsoluteTimeGetCurrent()
        let elapsed = end - start
    }
}