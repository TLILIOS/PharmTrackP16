import Foundation
import XCTest
import UIKit

// MARK: - Configuration de Performance pour les Tests
// Objectif: Réduire le temps d'exécution de 30+ min à 5-8 min

enum TestPerformanceConfig {
    
    // MARK: - Timeouts Optimisés
    
    enum Timeouts {
        /// Timeout maximum pour toute opération asynchrone (2s max)
        static let asyncOperation: TimeInterval = 2.0
        
        /// Timeout pour les sleeps dans les tests (1ms max)
        static let testSleep: UInt64 = 1_000_000 // 1ms en nanoseconds
        
        /// Timeout pour vérifier les états loading (0.5ms)
        static let loadingStateCheck: UInt64 = 500_000 // 0.5ms
        
        /// Timeout pour les expectations XCTest
        static let expectation: TimeInterval = 1.0
    }
    
    // MARK: - Tailles de Datasets Optimisées
    
    enum DatasetSizes {
        /// Nombre maximum d'items pour les tests de performance
        static let performanceTestItems = 100 // Au lieu de 1000+
        
        /// Nombre d'items pour les tests de pagination
        static let paginationTestItems = 30 // Au lieu de 100+
        
        /// Nombre d'items pour les tests standards
        static let standardTestItems = 10
        
        /// Nombre d'items pour les tests rapides
        static let quickTestItems = 3
    }
    
    // MARK: - Configuration Firebase Mock
    
    enum FirebaseMock {
        /// Délai simulé pour les opérations Firebase (0ms)
        static let operationDelay: UInt64 = 0
        
        /// Utiliser le cache mémoire uniquement
        static let useMemoryOnly = true
        
        /// Désactiver la persistence
        static let disablePersistence = true
        
        /// Batch size pour les opérations
        static let batchSize = 10
    }
    
    // MARK: - Optimisations UI
    
    enum UIOptimizations {
        /// Désactiver toutes les animations
        static let disableAnimations = true
        
        /// Durée des animations si activées
        static let animationDuration: TimeInterval = 0.0
        
        /// Désactiver les transitions
        static let disableTransitions = true
    }
    
    // MARK: - Parallélisation
    
    enum Parallelization {
        /// Activer l'exécution parallèle des tests
        static let enableParallelExecution = true
        
        /// Nombre maximum de tests en parallèle
        static let maxConcurrentTests = 4
        
        /// Utiliser des queues séparées pour chaque test
        static let useIsolatedQueues = true
    }
}

// MARK: - Extension pour les Tests

extension XCTestCase {
    
    /// Configure les optimisations de performance pour ce test
    func setupPerformanceOptimizations() {
        // Désactiver les animations UI
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        
        // Configurer les timeouts courts
        continueAfterFailure = false
        
        // Configurer l'environnement de test
        ProcessInfo.processInfo.setValue("1", forKey: "XCTestDisablePerformanceMetrics")
    }
    
    /// Sleep optimisé pour les tests
    func performanceOptimizedSleep() async {
        try? await Task.sleep(nanoseconds: TestPerformanceConfig.Timeouts.testSleep)
    }
}

// MARK: - Mock Firebase Optimisé

protocol OptimizedFirebaseMock {
    associatedtype ItemType
    
    /// Opération sans délai
    func performInstantOperation<T>(_ operation: () throws -> T) throws -> T
    
    /// Batch operation pour performance
    func performBatchOperation<T>(_ operations: [() throws -> T]) throws -> [T]
}

extension OptimizedFirebaseMock {
    func performInstantOperation<T>(_ operation: () throws -> T) throws -> T {
        // Pas de délai, exécution immédiate
        return try operation()
    }
    
    func performBatchOperation<T>(_ operations: [() throws -> T]) throws -> [T] {
        // Exécution en batch pour optimiser
        return try operations.map { try $0() }
    }
}