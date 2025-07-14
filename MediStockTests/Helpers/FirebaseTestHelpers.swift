import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

// MARK: - Firebase Test Mode Configuration

class FirebaseTestConfig {
    static let shared = FirebaseTestConfig()
    
    private var isTestMode = false
    
    func enableTestMode() {
        isTestMode = true
        // Disable Firebase network operations
        if let app = FirebaseApp.app() {
            // Force offline mode
            Firestore.firestore(app: app).settings.isPersistenceEnabled = false
            Firestore.firestore(app: app).disableNetwork { _ in }
        }
    }
    
    func disableTestMode() {
        isTestMode = false
    }
}

// MARK: - Mock Extensions for Existing Firebase Classes

extension FirebaseAuthRepository {
    func enableTestMode() {
        // Override network calls with immediate failures
    }
    
    func mapFirebaseErrorForTesting(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        if nsError.domain == AuthErrorDomain {
            switch nsError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                return .invalidEmail
            case AuthErrorCode.wrongPassword.rawValue:
                return .wrongPassword
            case AuthErrorCode.userNotFound.rawValue:
                return .userNotFound
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return .emailAlreadyInUse
            case AuthErrorCode.weakPassword.rawValue:
                return .weakPassword
            case AuthErrorCode.networkError.rawValue:
                return .networkError
            default:
                return .unknownError(error)
            }
        }
        
        return .unknownError(error)
    }
}

// MARK: - Test Data Helpers

struct TestDataHelper {
    static func createTestAisle(
        id: String = UUID().uuidString,
        name: String = "Test Aisle",
        colorHex: String = "#FF0000"
    ) -> Aisle {
        return Aisle(
            id: id,
            name: name,
            description: "Test Description",
            colorHex: colorHex,
            icon: "pills"
        )
    }
    
    static func createTestMedicine(
        id: String = UUID().uuidString,
        name: String = "Test Medicine",
        aisleId: String = "test-aisle"
    ) -> Medicine {
        return Medicine(
            id: id,
            name: name,
            aisleId: aisleId,
            expirationDate: Date().addingTimeInterval(86400 * 30),
            quantity: 10,
            minQuantity: 5,
            description: "Test Description"
        )
    }
    
    static func createTestUser(
        id: String = UUID().uuidString,
        email: String = "test@example.com"
    ) -> User {
        return User(
            id: id,
            email: email,
            displayName: "Test User"
        )
    }
}

// MARK: - In-Memory Cache for Tests

class TestDataCache {
    static let shared = TestDataCache()
    
    private var aisles: [String: Aisle] = [:]
    private var medicines: [String: Medicine] = [:]
    private var currentUser: User?
    
    func reset() {
        aisles.removeAll()
        medicines.removeAll()
        currentUser = nil
    }
    
    // Aisle operations
    func setAisles(_ aisles: [Aisle]) {
        self.aisles = Dictionary(uniqueKeysWithValues: aisles.map { ($0.id, $0) })
    }
    
    func getAisles() -> [Aisle] {
        return Array(aisles.values)
    }
    
    func addAisle(_ aisle: Aisle) {
        aisles[aisle.id] = aisle
    }
    
    func removeAisle(id: String) {
        aisles.removeValue(forKey: id)
    }
    
    // Medicine operations
    func setMedicines(_ medicines: [Medicine]) {
        self.medicines = Dictionary(uniqueKeysWithValues: medicines.map { ($0.id, $0) })
    }
    
    func getMedicines() -> [Medicine] {
        return Array(medicines.values)
    }
    
    func addMedicine(_ medicine: Medicine) {
        medicines[medicine.id] = medicine
    }
    
    func removeMedicine(id: String) {
        medicines.removeValue(forKey: id)
    }
    
    // User operations
    func setCurrentUser(_ user: User?) {
        currentUser = user
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
}

// MARK: - Firebase Extensions for Test Mode

extension MediStock.FirebaseAisleRepository {
    func enableTestModeWithCache() {
        // This allows tests to run without network calls
        TestDataCache.shared.setAisles([
            TestDataHelper.createTestAisle(id: "1", name: "Test Aisle 1"),
            TestDataHelper.createTestAisle(id: "2", name: "Test Aisle 2")
        ])
    }
    
    func getAisle(id: String) async throws -> Aisle? {
        // In test mode, return from cache
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            return TestDataCache.shared.getAisles().first { $0.id == id }
        }
        
        // Normal Firebase implementation would go here
        throw NSError(domain: "FirebaseError", code: 14, userInfo: nil)
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        // In test mode, save to cache
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
            var savedAisle = aisle
            if savedAisle.id.isEmpty {
                savedAisle = Aisle(
                    id: UUID().uuidString,
                    name: aisle.name,
                    description: aisle.description,
                    colorHex: aisle.colorHex,
                    icon: aisle.icon
                )
            }
            TestDataCache.shared.addAisle(savedAisle)
            return savedAisle
        }
        
        // Normal Firebase implementation would go here
        throw NSError(domain: "FirebaseError", code: 14, userInfo: nil)
    }
}

extension MediStock.FirebaseMedicineRepository {
    func enableTestModeWithCache() {
        // This allows tests to run without network calls
        TestDataCache.shared.setMedicines([
            TestDataHelper.createTestMedicine(id: "1", name: "Test Medicine 1"),
            TestDataHelper.createTestMedicine(id: "2", name: "Test Medicine 2")
        ])
    }
}

// MARK: - Test Timeout Helpers

struct TestTimeout {
    static let veryShort: TimeInterval = 0.5
    static let short: TimeInterval = 1.0
    static let medium: TimeInterval = 2.0
    static let long: TimeInterval = 3.0
    
    static func wait(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}