import Foundation
import Security

// MARK: - Keychain Service for Secure Storage

enum KeychainError: LocalizedError {
    case duplicateItem
    case itemNotFound
    case invalidData
    case unhandledError(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "L'élément existe déjà dans le Keychain"
        case .itemNotFound:
            return "Élément non trouvé dans le Keychain"
        case .invalidData:
            return "Données invalides"
        case .unhandledError(let status):
            return "Erreur Keychain: \(status)"
        }
    }
}

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    private let service = "com.medistock.app"
    
    // MARK: - Save Data
    
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
    
    // MARK: - Load Data
    
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
    
    // MARK: - Delete Data
    
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
    
    // MARK: - Secure Token Storage
    
    func saveAuthToken(_ token: String) throws {
        try save(token, for: "auth_token")
    }
    
    func loadAuthToken() -> String? {
        try? loadString(for: "auth_token")
    }
    
    func deleteAuthToken() {
        try? delete(for: "auth_token")
    }
    
    // MARK: - User Credentials (if needed for biometric re-auth)
    
    func saveUserCredentials(email: String, password: String) throws {
        let credentials = ["email": email, "password": password]
        let data = try JSONEncoder().encode(credentials)
        try save(data, for: "user_credentials")
    }
    
    func loadUserCredentials() -> (email: String, password: String)? {
        guard let data = try? load(for: "user_credentials"),
              let credentials = try? JSONDecoder().decode([String: String].self, from: data),
              let email = credentials["email"],
              let password = credentials["password"] else {
            return nil
        }
        return (email, password)
    }
    
    func deleteUserCredentials() {
        try? delete(for: "user_credentials")
    }
}