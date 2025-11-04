import Foundation

#if !UNIT_TESTS_ONLY
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseAppCheck
#endif

/// Configuration centralisée pour l'environnement de test
class TestConfiguration {
    
    /// Configure Firebase pour les tests en désactivant les services non nécessaires
    static func setupFirebaseForTesting() {
        #if !UNIT_TESTS_ONLY
        // Désactiver AppCheck complètement en mode test
        AppCheck.setAppCheckProviderFactory(nil)
        
        // Vérifier si on doit utiliser les émulateurs Firebase
        if ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "1" {
            configureFirebaseEmulators()
        } else {
            // En mode test unitaire, on ne configure pas Firebase du tout
            if ProcessInfo.processInfo.environment["UNIT_TESTS_ONLY"] == "1" {
                return
            }
            
            // Configuration minimale pour les tests d'intégration
            configureMinimalFirebase()
        }
        #else
        #endif
    }
    
    /// Configure les émulateurs Firebase pour les tests locaux
    private static func configureFirebaseEmulators() {
        #if !UNIT_TESTS_ONLY
        // Auth emulator
        Auth.auth().useEmulator(withHost: "localhost", port: 9099)
        
        // Firestore emulator
        let settings = Firestore.firestore().settings
        settings.host = "localhost:8080"
        settings.cacheSettings = MemoryCacheSettings()
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings
        
        #endif
    }
    
    /// Configuration minimale de Firebase pour les tests
    private static func configureMinimalFirebase() {
        #if !UNIT_TESTS_ONLY
        // Désactiver la persistance pour accélérer les tests
        let settings = Firestore.firestore().settings
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
        
        #endif
    }
    
    /// Nettoie l'état de Firebase après les tests
    static func tearDownFirebase() async {
        #if !UNIT_TESTS_ONLY
        // Sign out si un utilisateur est connecté
        do {
            try Auth.auth().signOut()
        } catch {
        }
        
        // Terminer toutes les opérations Firestore en cours
        do {
            try await Firestore.firestore().terminate()
        } catch {
        }
        #endif
    }
    
    /// Configure l'environnement de test pour des performances optimales
    static func configureTestEnvironment() {
        // Désactiver les animations pour accélérer les tests UI
        UIView.setAnimationsEnabled(false)

        // Vérifier si on est en mode test
        _ = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        // Configurer les timeouts pour les tests
        URLSession.shared.configuration.timeoutIntervalForRequest = 5.0
        URLSession.shared.configuration.timeoutIntervalForResource = 10.0
    }
    
    /// Vérifie si on est en mode test unitaire uniquement
    static var isUnitTestMode: Bool {
        ProcessInfo.processInfo.environment["UNIT_TESTS_ONLY"] == "1"
    }
    
    /// Vérifie si on doit utiliser les émulateurs Firebase
    static var shouldUseEmulators: Bool {
        ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "1"
    }
}