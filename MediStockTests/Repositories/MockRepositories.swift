import Foundation
import Combine
@testable import MediStock

// MARK: - Mock Medicine Repository

public class MockMedicineRepository: MedicineRepositoryProtocol {
    public var shouldThrowError = false
    public var medicines: [Medicine] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    
    public init() {}
    
    public func getMedicines() async throws -> [Medicine] {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        return medicines
    }
    
    public func getMedicine(id: String) async throws -> Medicine? {
        if shouldThrowError {
            throw errorToThrow
        }
        return medicines.first { $0.id == id }
    }
    
    public func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            medicines[index] = medicine
        } else {
            let newMedicine = Medicine(
                id: medicine.id.isEmpty ? UUID().uuidString : medicine.id,
                name: medicine.name,
                description: medicine.description,
                dosage: medicine.dosage,
                form: medicine.form,
                reference: medicine.reference,
                unit: medicine.unit,
                currentQuantity: medicine.currentQuantity,
                maxQuantity: medicine.maxQuantity,
                warningThreshold: medicine.warningThreshold,
                criticalThreshold: medicine.criticalThreshold,
                expiryDate: medicine.expiryDate,
                aisleId: medicine.aisleId,
                createdAt: Date(),
                updatedAt: Date()
            )
            medicines.append(newMedicine)
            return newMedicine
        }
        return medicine
    }
    
    public func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
        }
        
        let medicine = medicines[index]
        let updatedMedicine = Medicine(
            id: medicine.id,
            name: medicine.name,
            description: medicine.description,
            dosage: medicine.dosage,
            form: medicine.form,
            reference: medicine.reference,
            unit: medicine.unit,
            currentQuantity: newStock,
            maxQuantity: medicine.maxQuantity,
            warningThreshold: medicine.warningThreshold,
            criticalThreshold: medicine.criticalThreshold,
            expiryDate: medicine.expiryDate,
            aisleId: medicine.aisleId,
            createdAt: medicine.createdAt,
            updatedAt: Date()
        )
        
        medicines[index] = updatedMedicine
        return updatedMedicine
    }
    
    public func deleteMedicine(id: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        medicines.removeAll { $0.id == id }
    }
    
    public func observeMedicines() -> AnyPublisher<[Medicine], Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return Just(medicines)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func observeMedicine(id: String) -> AnyPublisher<Medicine?, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        let medicine = medicines.first { $0.id == id }
        return Just(medicine)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock Aisle Repository

public class MockAisleRepository: AisleRepositoryProtocol {
    public var shouldThrowError = false
    public var aisles: [Aisle] = []
    public var medicineCount = 5
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public init() {}
    
    public func getAisles() async throws -> [Aisle] {
        if shouldThrowError {
            throw errorToThrow
        }
        return aisles
    }
    
    public func getAisle(id: String) async throws -> Aisle? {
        if shouldThrowError {
            throw errorToThrow
        }
        return aisles.first { $0.id == id }
    }
    
    public func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let index = aisles.firstIndex(where: { $0.id == aisle.id }) {
            aisles[index] = aisle
        } else {
            let newAisle = Aisle(
                id: aisle.id.isEmpty ? UUID().uuidString : aisle.id,
                name: aisle.name,
                description: aisle.description,
                colorHex: aisle.colorHex,
                icon: aisle.icon
            )
            aisles.append(newAisle)
            return newAisle
        }
        return aisle
    }
    
    public func deleteAisle(id: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        aisles.removeAll { $0.id == id }
    }
    
    public func getMedicineCountByAisle(aisleId: String) async throws -> Int {
        if shouldThrowError {
            throw errorToThrow
        }
        // Mock implementation - return configured count
        return medicineCount
    }
    
    public func observeAisles() -> AnyPublisher<[Aisle], Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        return Just(aisles)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func observeAisle(id: String) -> AnyPublisher<Aisle?, Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        let aisle = aisles.first { $0.id == id }
        return Just(aisle)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// MARK: - Mock History Repository

public class MockHistoryRepository: HistoryRepositoryProtocol {
    public var shouldThrowError = false
    public var historyEntries: [HistoryEntry] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public init() {}
    
    public func getAllHistory() async throws -> [HistoryEntry] {
        if shouldThrowError {
            throw errorToThrow
        }
        return historyEntries.sorted { $0.timestamp > $1.timestamp }
    }
    
    public func getHistoryForMedicine(medicineId: String) async throws -> [HistoryEntry] {
        if shouldThrowError {
            throw errorToThrow
        }
        return historyEntries
            .filter { $0.medicineId == medicineId }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    public func addHistoryEntry(_ entry: HistoryEntry) async throws -> HistoryEntry {
        if shouldThrowError {
            throw errorToThrow
        }
        let newEntry = HistoryEntry(
            id: entry.id.isEmpty ? UUID().uuidString : entry.id,
            medicineId: entry.medicineId,
            userId: entry.userId,
            action: entry.action,
            details: entry.details,
            timestamp: entry.timestamp
        )
        historyEntries.append(newEntry)
        return newEntry
    }
    
    public func deleteHistoryEntry(id: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        historyEntries.removeAll { $0.id == id }
    }
    
    public func exportHistory(format: String, medicineId: String?) async throws -> Data {
        if shouldThrowError {
            throw errorToThrow
        }
        
        let entries = medicineId != nil ? 
            historyEntries.filter { $0.medicineId == medicineId } : 
            historyEntries
        
        switch format {
        case "json":
            return try JSONEncoder().encode(entries)
        case "csv":
            let csvContent = "ID,Medicine ID,User ID,Action,Details,Timestamp\n" +
                entries.map { "\($0.id),\($0.medicineId),\($0.userId),\($0.action),\($0.details),\($0.timestamp)" }
                    .joined(separator: "\n")
            return csvContent.data(using: .utf8) ?? Data()
        default:
            return Data()
        }
    }
    
    public func observeHistoryForMedicine(medicineId: String) -> AnyPublisher<[HistoryEntry], Error> {
        if shouldThrowError {
            return Fail(error: errorToThrow)
                .eraseToAnyPublisher()
        }
        let filtered = historyEntries.filter { $0.medicineId == medicineId }
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    public func getRecentHistory(limit: Int) async throws -> [HistoryEntry] {
        if shouldThrowError {
            throw errorToThrow
        }
        return Array(historyEntries.sorted { $0.timestamp > $1.timestamp }.prefix(limit))
    }
}

// MARK: - Mock Auth Repository

public class MockAuthRepository: AuthRepositoryProtocol {
    public var shouldThrowError = false
    public var shouldThrowOnSignOut = false
    public var _currentUser: User? = User(id: "mock-user", email: "test@example.com", displayName: "Mock User")
    public var errorToThrow: Error = AuthError.networkError
    
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    
    public init() {
        authStateSubject.value = _currentUser
    }
    
    public var currentUser: User? {
        get { _currentUser }
        set {
            _currentUser = newValue
            authStateSubject.send(newValue)
        }
    }
    
    public var authStateDidChange: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    public func signIn(email: String, password: String) async throws -> User {
        if shouldThrowError {
            throw errorToThrow
        }
        
        // If a user is already configured and matches the email, return it
        if let existingUser = currentUser, existingUser.email == email {
            return existingUser
        }
        
        // Otherwise create a new user
        let user = User(id: "mock-user", email: email, displayName: "Mock User")
        currentUser = user
        return user
    }
    
    public func signUp(email: String, password: String) async throws -> User {
        if shouldThrowError {
            throw errorToThrow
        }
        // Return the pre-configured currentUser if it exists and has matching email, otherwise create new
        if let existingUser = currentUser, existingUser.email == email {
            return existingUser
        }
        let user = User(id: "mock-user", email: email, displayName: "Mock User")
        currentUser = user
        return user
    }
    
    public func signOut() async throws {
        if shouldThrowError || shouldThrowOnSignOut {
            throw errorToThrow
        }
        currentUser = nil
    }
    
    public func resetPassword(email: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        // Mock implementation - do nothing
    }
    
    public func updateUserProfile(user: User) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        currentUser = user
    }
}