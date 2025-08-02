import XCTest
@testable import MediStock

// MARK: - Base Test Case Optimisé

/// Classe de base pour tous les tests avec optimisations de performance intégrées
@MainActor
class OptimizedTestCase: XCTestCase {
    
    // MARK: - Setup/TearDown Optimisés
    
    override func setUp() {
        super.setUp()
        
        // Désactiver les animations
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        
        // Configurer les timeouts courts
        continueAfterFailure = false
        
        // Désactiver les logs verbeux en test
        ProcessInfo.processInfo.setValue("1", forKey: "DISABLE_VERBOSE_LOGGING")
        
        // Configuration de performance
        setupTestPerformanceOptimizations()
    }
    
    override func tearDown() {
        // Nettoyage minimal et rapide
        super.tearDown()
    }
    
    
    // MARK: - Helpers d'Optimisation
    
    private func setupTestPerformanceOptimizations() {
        // Configuration globale pour des tests rapides
        UserDefaults.standard.set(true, forKey: "DisableAnimations")
        UserDefaults.standard.set(true, forKey: "UseMemoryOnlyCache")
        UserDefaults.standard.set(0, forKey: "NetworkDelay")
    }
    
    /// Attente optimisée pour les tests (max 1ms)
    func optimizedWait() async {
        try? await Task.sleep(nanoseconds: TestPerformanceConfig.Timeouts.testSleep)
    }
    
    /// Création rapide de données de test
    func createTestMedicines(count: Int) -> [Medicine] {
        return (0..<min(count, TestPerformanceConfig.DatasetSizes.standardTestItems)).map { index in
            Medicine(
                id: "test-med-\(index)",
                name: "Medicine \(index)",
                description: "Test description",
                dosage: "100mg",
                form: "comprimé",
                reference: "REF-\(index)",
                unit: "comprimés",
                currentQuantity: 50,
                maxQuantity: 100,
                warningThreshold: 20,
                criticalThreshold: 10,
                expiryDate: Date().addingTimeInterval(86400 * 365),
                aisleId: "test-aisle",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
    
    func createTestAisles(count: Int) -> [Aisle] {
        return (0..<min(count, TestPerformanceConfig.DatasetSizes.quickTestItems)).map { index in
            Aisle(
                id: "test-aisle-\(index)",
                name: "Aisle \(index)",
                description: "Test aisle description",
                colorHex: "#FF0000",
                icon: "pills"
            )
        }
    }
    
    // MARK: - Assertions Optimisées
    
    /// Assert avec timeout court pour les opérations async
    func assertWithTimeout<T>(
        _ operation: @escaping () async throws -> T,
        timeout: TimeInterval = TestPerformanceConfig.Timeouts.asyncOperation,
        file: StaticString = #file,
        line: UInt = #line,
        assertion: @escaping (T) -> Void
    ) async {
        let expectation = self.expectation(description: "Async operation")
        
        Task {
            do {
                let result = try await operation()
                assertion(result)
                expectation.fulfill()
            } catch {
                XCTFail("Operation failed: \(error)", file: file, line: line)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: timeout)
    }
}

// MARK: - Mock Factory Optimisé

extension OptimizedTestCase {
    
    /// Crée un mock repository optimisé pour les medicines
    func createOptimizedMedicineRepository() -> MockMedicineRepository {
        let repo = MockMedicineRepository()
        repo.medicines = createTestMedicines(count: TestPerformanceConfig.DatasetSizes.quickTestItems)
        return repo
    }
    
    /// Crée un mock repository optimisé pour les aisles
    func createOptimizedAisleRepository() -> MockAisleRepository {
        let repo = MockAisleRepository()
        repo.aisles = createTestAisles(count: TestPerformanceConfig.DatasetSizes.quickTestItems)
        return repo
    }
    
    /// Crée un mock data service optimisé
    func createOptimizedDataService() -> DataServiceAdapter {
        // Retourne un mock pour éviter l'initialisation Firebase
        return MockDataServiceAdapterForIntegration()
    }
}

// MARK: - Extensions pour Tests Rapides

extension XCTestExpectation {
    
    /// Crée une expectation avec timeout court par défaut
    static func optimized(description: String) -> XCTestExpectation {
        let exp = XCTestExpectation(description: description)
        exp.assertForOverFulfill = true
        return exp
    }
}