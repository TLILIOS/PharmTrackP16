import Foundation
import Security
import CryptoKit

// MARK: - Version Sécurisée du KeychainService
// Cette version supprime complètement le stockage des mots de passe
// et n'utilise que des tokens sécurisés

class KeychainService_Secure {
    static let shared = KeychainService_Secure()
    
    private init() {}
    
    private let service = Bundle.main.bundleIdentifier ?? "com.medistock.app"
    
    // MARK: - Configuration de Migration
    
    /// Indicateur pour savoir si la migration a été effectuée
    private var isMigrationCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: "KeychainMigrationCompleted") }
        set { UserDefaults.standard.set(newValue, forKey: "KeychainMigrationCompleted") }
    }
    
    // MARK: - Save Data (Inchangé pour compatibilité)
    
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status)
        }
    }
    
    func save(_ string: String, for key: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key)
    }
    
    // MARK: - Load Data (Inchangé pour compatibilité)
    
    func load(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    func loadString(for key: String) throws -> String {
        let data = try load(for: key)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    // MARK: - Delete Data (Inchangé pour compatibilité)
    
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status)
        }
    }
    
    // MARK: - Secure Token Storage (Inchangé)
    
    func saveAuthToken(_ token: String) throws {
        try save(token, for: "auth_token")
    }
    
    func loadAuthToken() -> String? {
        try? loadString(for: "auth_token")
    }
    
    func deleteAuthToken() {
        try? delete(for: "auth_token")
    }
    
    // MARK: - 🚨 NOUVELLE API SÉCURISÉE - Remplace les Credentials
    
    /// Sauvegarde uniquement l'email et un hash pour la vérification biométrique
    /// Le mot de passe n'est JAMAIS stocké
    func saveBiometricAuthData(email: String, sessionToken: String) throws {
        // Créer un identifiant unique pour la session biométrique
        let biometricData = BiometricAuthData(
            email: email,
            sessionToken: sessionToken,
            createdAt: Date()
        )
        
        let data = try JSONEncoder().encode(biometricData)
        try save(data, for: "biometric_auth_data")
    }
    
    /// Charge les données pour l'authentification biométrique
    func loadBiometricAuthData() -> BiometricAuthData? {
        guard let data = try? load(for: "biometric_auth_data"),
              let authData = try? JSONDecoder().decode(BiometricAuthData.self, from: data) else {
            return nil
        }
        
        // Vérifier que la session n'est pas expirée (24h)
        let expirationDate = authData.createdAt.addingTimeInterval(24 * 60 * 60)
        if Date() > expirationDate {
            try? delete(for: "biometric_auth_data")
            return nil
        }
        
        return authData
    }
    
    /// Supprime les données d'authentification biométrique
    func deleteBiometricAuthData() {
        try? delete(for: "biometric_auth_data")
    }
    
    // MARK: - 🔄 API de Migration (Temporaire)
    
    /// Migre les anciennes credentials vers le nouveau système
    /// Cette méthode sera appelée UNE SEULE FOIS lors de la mise à jour
    func migrateFromOldCredentials() {
        guard !isMigrationCompleted else { return }
        
        // Si des anciennes credentials existent
        if let oldCredentials = loadUserCredentials_Legacy() {
            // Log pour audit (sans exposer le mot de passe)
            print("Migration: Détection d'anciennes credentials pour \(oldCredentials.email)")
            
            // Supprimer immédiatement les anciennes données
            try? delete(for: "user_credentials")
            
            // Note: L'utilisateur devra se reconnecter pour générer un nouveau token
            // Ceci est intentionnel pour la sécurité
        }
        
        // Marquer la migration comme complétée
        isMigrationCompleted = true
    }
    
    // MARK: - ⚠️ API Dépréciées (Pour Compatibilité Temporaire)
    
    @available(*, deprecated, message: "Utiliser saveBiometricAuthData à la place")
    func saveUserCredentials(email: String, password: String) throws {
        // NE STOCKE PLUS LE MOT DE PASSE
        // Génère un warning de compilation pour forcer la migration
        print("⚠️ ATTENTION: Tentative de stockage de mot de passe bloquée")
        print("⚠️ Migrez vers saveBiometricAuthData()")
        
        // Pour la rétrocompatibilité, on stocke uniquement l'email
        let safeData = ["email": email]
        let data = try JSONEncoder().encode(safeData)
        try save(data, for: "user_email_only")
    }
    
    @available(*, deprecated, message: "Utiliser loadBiometricAuthData à la place")
    func loadUserCredentials() -> (email: String, password: String)? {
        // Pour la migration progressive, on retourne nil
        // Cela forcera l'app à demander une nouvelle authentification
        return nil
    }
    
    @available(*, deprecated, message: "Utiliser deleteBiometricAuthData à la place")
    func deleteUserCredentials() {
        try? delete(for: "user_credentials")
        try? delete(for: "user_email_only")
    }
    
    // MARK: - Private Legacy Methods
    
    /// Méthode privée pour charger les anciennes credentials (migration uniquement)
    private func loadUserCredentials_Legacy() -> (email: String, password: String)? {
        guard let data = try? load(for: "user_credentials"),
              let credentials = try? JSONDecoder().decode([String: String].self, from: data),
              let email = credentials["email"],
              let password = credentials["password"] else {
            return nil
        }
        return (email, password)
    }
}

// MARK: - Nouveau Modèle Sécurisé

struct BiometricAuthData: Codable {
    let email: String
    let sessionToken: String
    let createdAt: Date
}

// MARK: - Extension pour la Migration Progressive

extension KeychainService_Secure {
    /// Méthode helper pour faciliter la migration dans l'app
    static func performMigrationIfNeeded() {
        shared.migrateFromOldCredentials()
    }
}