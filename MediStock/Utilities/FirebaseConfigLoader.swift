import Foundation
import FirebaseCore

// MARK: - Gestionnaire de configuration Firebase sécurisé

/// Charge la configuration Firebase depuis xcconfig ou GoogleService-Info.plist
/// Permet d'éviter d'exposer l'API Key dans le code source
enum FirebaseConfigLoader {

    // MARK: - Configuration Environment

    enum Environment {
        case production
        case test

        var configFileName: String {
            switch self {
            case .production:
                return "GoogleService-Info"
            case .test:
                return "GoogleService-Info-Test"
            }
        }
    }

    // MARK: - Public Methods

    /// Configure Firebase selon l'environnement
    /// - Parameter environment: Environnement de configuration
    static func configure(for environment: Environment = .production) {
        // Skip Firebase initialization during unit tests
        if ProcessInfo.processInfo.environment["UNIT_TESTS_ONLY"] == "1" {
            print("⚠️ Skipping Firebase configuration (UNIT_TESTS_ONLY mode)")
            return
        }

        #if DEBUG
        #endif

        // Vérifier si Firebase est déjà configuré
        guard FirebaseApp.app() == nil else {
            #if DEBUG
            #endif
            return
        }

        // Charger depuis xcconfig si disponible
        if let options = loadFromXCConfig() {
            FirebaseApp.configure(options: options)
            #if DEBUG
            #endif
            return
        }

        // Fallback: Charger depuis GoogleService-Info.plist
        if let options = loadFromPlist(environment: environment) {
            FirebaseApp.configure(options: options)
            #if DEBUG
            #endif
            return
        }

        // Si aucune configuration n'est trouvée, utiliser la configuration par défaut
        #if DEBUG
        #endif
        FirebaseApp.configure()
    }

    /// Configure Firebase pour les tests (ne configure pas réellement Firebase)
    static func configureForTesting() {
        // Pour les tests, on ne configure pas Firebase
        // Les mocks seront utilisés à la place
        #if DEBUG
        #endif
    }

    // MARK: - Private Methods

    /// Charge la configuration depuis les variables xcconfig
    private static func loadFromXCConfig() -> FirebaseOptions? {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_API_KEY") as? String,
              let projectID = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_PROJECT_ID") as? String,
              let appID = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_APP_ID") as? String,
              let gcmSenderID = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_GCM_SENDER_ID") as? String,
              !apiKey.isEmpty,
              !apiKey.hasPrefix("$") else {
            return nil
        }

        let options = FirebaseOptions(googleAppID: appID, gcmSenderID: gcmSenderID)
        options.apiKey = apiKey
        options.projectID = projectID

        if let storageBucket = Bundle.main.object(forInfoDictionaryKey: "FIREBASE_STORAGE_BUCKET") as? String {
            options.storageBucket = storageBucket
        }

        return options
    }

    /// Charge la configuration depuis le fichier plist
    private static func loadFromPlist(environment: Environment) -> FirebaseOptions? {
        let fileName = environment.configFileName

        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            #if DEBUG
            #endif
            return nil
        }

        return options
    }
}

// MARK: - Firebase Configuration Manager

/// Manager pour gérer l'initialisation de Firebase de manière centralisée
@MainActor
final class FirebaseConfigManager {
    static let shared = FirebaseConfigManager()

    private(set) var isConfigured = false
    private(set) var environment: FirebaseConfigLoader.Environment = .production

    private init() {}

    /// Configure Firebase pour l'application
    /// - Parameter environment: Environnement à utiliser
    func configure(for environment: FirebaseConfigLoader.Environment = .production) {
        guard !isConfigured else {
            #if DEBUG
            #endif
            return
        }

        self.environment = environment
        FirebaseConfigLoader.configure(for: environment)
        isConfigured = true

        #if DEBUG
        #endif
    }

    /// Configure Firebase pour les tests (utilise des mocks)
    func configureForTesting() {
        // Pour les tests, on ne configure pas vraiment Firebase
        // On utilisera les mocks à la place
        isConfigured = true
        environment = .test

        #if DEBUG
        #endif
    }

    /// Réinitialise la configuration (utile pour les tests)
    func reset() {
        isConfigured = false
    }
}
