/// Imports communs pour tous les tests
/// Ce fichier centralise les imports fréquemment utilisés dans les tests

import Foundation
import XCTest
import Combine

// Import conditionnel de Firebase pour les tests d'intégration uniquement
#if !UNIT_TESTS_ONLY
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck
#endif

// Import du module principal
@testable import MediStock

// Type aliases pour simplifier l'usage
typealias TestExpectation = XCTestExpectation
typealias TestCancellable = AnyCancellable

// Extensions globales pour les tests
extension XCTestCase {
    /// Crée une expectation avec une description par défaut basée sur le nom de la méthode
    func expectation(method: String = #function) -> TestExpectation {
        return expectation(description: "\(method) expectation")
    }
}