import Foundation
import Combine
@testable import MediStock

// MARK: - Mock Medicine Repository

class MockMedicineRepository: MedicineRepositoryProtocol {
    var medicines: [Medicine] = []
    var shouldThrowError = false
    var fetchMedicinesCallCount = 0
    var saveMedicineCallCount = 0
    var deleteMedicineCallCount = 0
    
    func fetchMedicines() async throws -> [Medicine] {
        fetchMedicinesCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return medicines
    }
    
    func fetchMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Test error"])
        }
        return Array(medicines.prefix(limit))
    }
    
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        saveMedicineCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
        } else {
            medicines.append(medicine)
        }
        
        return medicine
    }
    
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "Test", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
        }
        
        var updated = medicines[index]
        updated.currentQuantity = newStock
        medicines[index] = updated
        
        return updated
    }
    
    func deleteMedicine(id: String) async throws {
        deleteMedicineCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        medicines.removeAll { $0.id == id }
    }
    
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        for medicine in medicines {
            if let index = self.medicines.firstIndex(where: { $0.id == medicine.id }) {
                self.medicines[index] = medicine
            }
        }
    }
    
    func deleteMultipleMedicines(ids: [String]) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        medicines.removeAll { ids.contains($0.id) }
    }
}

// MARK: - Mock Aisle Repository

class MockAisleRepository: AisleRepositoryProtocol {
    var aisles: [Aisle] = []
    var shouldThrowError = false
    
    func fetchAisles() async throws -> [Aisle] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return aisles
    }
    
    func fetchAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return Array(aisles.prefix(limit))
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        if let index = aisles.firstIndex(where: { $0.id == aisle.id }) {
            aisles[index] = aisle
        } else {
            aisles.append(aisle)
        }
        
        return aisle
    }
    
    func deleteAisle(id: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        aisles.removeAll { $0.id == id }
    }
}

// MARK: - Mock History Repository

class MockHistoryRepository: HistoryRepositoryProtocol {
    var history: [HistoryEntry] = []
    var shouldThrowError = false
    var addHistoryEntryCallCount = 0
    
    func fetchHistory() async throws -> [HistoryEntry] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return history
    }
    
    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        addHistoryEntryCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        history.append(entry)
    }
    
    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        return history.filter { $0.medicineId == medicineId }
    }
}

// MARK: - Mock Auth Repository

@MainActor
class MockAuthRepository: AuthRepositoryProtocol {
    @Published var currentUser: User?
    var signInCallCount = 0
    var signOutCallCount = 0
    var shouldThrowError = false
    
    var currentUserPublisher: Published<User?>.Publisher {
        $currentUser
    }
    
    init() {
        self.currentUser = nil
    }
    
    func signIn(email: String, password: String) async throws {
        signInCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        }
        
        currentUser = User(
            id: "test-user-id",
            email: email,
            displayName: "Test User"
        )
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        
        currentUser = User(
            id: "new-user-id",
            email: email,
            displayName: displayName
        )
    }
    
    func signOut() async throws {
        signOutCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: 0)
        }
        currentUser = nil
    }
    
    func getCurrentUser() -> User? {
        return currentUser
    }
}

// MARK: - Mock Notification Service

class MockNotificationService: NotificationService {
    var checkExpirationsCallCount = 0

    override func checkExpirations(medicines: [Medicine]) async {
        checkExpirationsCallCount += 1
    }
}

// MARK: - Mock Auth Service (Standalone)

@MainActor
class MockAuthServiceStandalone: ObservableObject {
    @Published var currentUser: User?
    var signInCallCount = 0
    var signUpCallCount = 0
    var signOutCallCount = 0
    var resetPasswordCallCount = 0
    var shouldThrowError = false
    var errorToThrow: Error?

    init() {
        self.currentUser = nil
    }

    func signIn(email: String, password: String) async throws {
        signInCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        // Validation basique pour les tests
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.wrongPassword
        }
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }

        currentUser = User(
            id: "mock-user-\(UUID().uuidString)",
            email: email,
            displayName: "Mock User"
        )
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        signUpCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        // Validation basique
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard !password.isEmpty else {
            throw AuthError.weakPassword
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        currentUser = User(
            id: "mock-user-\(UUID().uuidString)",
            email: email,
            displayName: displayName
        )
    }

    func signOut() async throws {
        signOutCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        currentUser = nil
    }

    func resetPassword(email: String) async throws {
        resetPasswordCallCount += 1

        if shouldThrowError {
            throw errorToThrow ?? AuthError.unknownError(NSError(domain: "MockAuthService", code: 0))
        }

        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard email.contains("@") else {
            throw AuthError.invalidEmail
        }
    }

    func getCurrentUser() -> User? {
        return currentUser
    }
}

// MARK: - Sample Data for Previews and Tests

extension MockMedicineRepository {
    static func withSampleData() -> MockMedicineRepository {
        let repo = MockMedicineRepository()
        repo.medicines = [
            Medicine(
                id: "1",
                name: "Paracétamol",
                description: "Antalgique et antipyrétique",
                dosage: "500mg",
                form: "Comprimé",
                reference: "PAR-500",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 200,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Medicine(
                id: "2",
                name: "Ibuprofène",
                description: "Anti-inflammatoire",
                dosage: "400mg",
                form: "Comprimé",
                reference: "IBU-400",
                unit: "comprimés",
                currentQuantity: 15,
                maxQuantity: 150,
                warningThreshold: 30,
                criticalThreshold: 10,
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                aisleId: "aisle1",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
        return repo
    }
}

extension MockAisleRepository {
    static func withSampleData() -> MockAisleRepository {
        let repo = MockAisleRepository()

        var aisle1 = Aisle(
            name: "Antalgiques",
            description: "Médicaments contre la douleur",
            colorHex: "#FF6B6B",
            icon: "pills.fill"
        )
        aisle1.id = "aisle1"

        var aisle2 = Aisle(
            name: "Antibiotiques",
            description: "Médicaments antibactériens",
            colorHex: "#4ECDC4",
            icon: "cross.case.fill"
        )
        aisle2.id = "aisle2"

        repo.aisles = [aisle1, aisle2]
        return repo
    }
}

extension MockHistoryRepository {
    static func withSampleData() -> MockHistoryRepository {
        let repo = MockHistoryRepository()
        repo.history = [
            HistoryEntry(
                id: "h1",
                medicineId: "1",
                userId: "user1",
                action: "Ajout stock",
                details: "Ajout de 50 comprimés",
                timestamp: Date()
            ),
            HistoryEntry(
                id: "h2",
                medicineId: "2",
                userId: "user1",
                action: "Modification",
                details: "Mise à jour des seuils d'alerte",
                timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            )
        ]
        return repo
    }
}