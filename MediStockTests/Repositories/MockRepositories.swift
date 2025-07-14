////
////  MockRepositories.swift
////  MediStockTests
////
////  Created by TLiLi Hamdi on 14/06/2025.
////
//
//import Foundation
//import Combine
//@testable import MediStock
//
//// MARK: - Mock Medicine Repository
//@MainActor
//public class MockMedicineRepository: MedicineRepositoryProtocol {
//    public var shouldThrowError = false
//    public var medicines: [Medicine] = []
//    public var returnMedicines: [Medicine] = []
//    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
//    public var delayNanoseconds: UInt64 = 0
//    
//    // Call tracking
//    public var getMedicinesCallCount = 0
//    public var saveMedicineCallCount = 0
//    public var deleteMedicineCallCount = 0
//    public var updateMedicineStockCallCount = 0
//    public var callCount: Int { getMedicinesCallCount }
//    
//    // Last call parameters
//    public var lastSavedMedicine: Medicine?
//    public var deletedMedicineIds: [String] = []
//    public var lastUpdatedMedicineId: String?
//    public var lastNewStock: Int?
//    public var lastUpdateMedicineStockCall: (id: String, newStock: Int)?
//    
//    // Additional test properties
//    public var savedMedicine: Medicine?
//    public var savedMedicines: [Medicine] = []
//    public var returnSavedMedicine: Medicine?
//    public var updatedMedicine: Medicine?
//    public var returnUpdatedMedicine: Medicine?
//    public var addedMedicines: [Medicine] = []
//    
//    public init() {}
//    
//    public func getMedicines() async throws -> [Medicine] {
//        getMedicinesCallCount += 1
//        
//        if delayNanoseconds > 0 {
//            try await Task.sleep(nanoseconds: delayNanoseconds)
//        }
//        
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        return returnMedicines.isEmpty ? medicines : returnMedicines
//    }
//    
//    public func getMedicine(id: String) async throws -> Medicine? {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        return medicines.first { $0.id == id }
//    }
//    
//    public func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
//        saveMedicineCallCount += 1
//        lastSavedMedicine = medicine
//        savedMedicines.append(medicine)
//        
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        if let returnMedicine = returnSavedMedicine {
//            return returnMedicine
//        }
//        
//        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
//            medicines[index] = medicine
//        } else {
//            let newMedicine = Medicine(
//                id: medicine.id.isEmpty ? UUID().uuidString : medicine.id,
//                name: medicine.name,
//                description: medicine.description,
//                dosage: medicine.dosage,
//                form: medicine.form,
//                reference: medicine.reference,
//                unit: medicine.unit,
//                currentQuantity: medicine.currentQuantity,
//                maxQuantity: medicine.maxQuantity,
//                warningThreshold: medicine.warningThreshold,
//                criticalThreshold: medicine.criticalThreshold,
//                expiryDate: medicine.expiryDate,
//                aisleId: medicine.aisleId,
//                createdAt: Date(),
//                updatedAt: Date()
//            )
//            medicines.append(newMedicine)
//            addedMedicines.append(newMedicine)
//            if let saved = savedMedicine {
//                return saved
//            }
//            return newMedicine
//        }
//        return savedMedicine ?? medicine
//    }
//    
//    public func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
//        updateMedicineStockCallCount += 1
//        lastUpdatedMedicineId = id
//        lastNewStock = newStock
//        lastUpdateMedicineStockCall = (id: id, newStock: newStock)
//        
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        if let configured = returnUpdatedMedicine ?? updatedMedicine {
//            return configured
//        }
//        
//        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
//            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
//        }
//        
//        let medicine = medicines[index]
//        let updatedMed = Medicine(
//            id: medicine.id,
//            name: medicine.name,
//            description: medicine.description,
//            dosage: medicine.dosage,
//            form: medicine.form,
//            reference: medicine.reference,
//            unit: medicine.unit,
//            currentQuantity: newStock,
//            maxQuantity: medicine.maxQuantity,
//            warningThreshold: medicine.warningThreshold,
//            criticalThreshold: medicine.criticalThreshold,
//            expiryDate: medicine.expiryDate,
//            aisleId: medicine.aisleId,
//            createdAt: medicine.createdAt,
//            updatedAt: Date()
//        )
//        
//        medicines[index] = updatedMed
//        return updatedMed
//    }
//    
//    public func deleteMedicine(id: String) async throws {
//        deleteMedicineCallCount += 1
//        
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        deletedMedicineIds.append(id)
//        medicines.removeAll { $0.id == id }
//    }
//    
//    nonisolated public func observeMedicines() -> AnyPublisher<[Medicine], Error> {
//        return Future { promise in
//            Task { @MainActor in
//                if self.shouldThrowError {
//                    promise(.failure(self.errorToThrow))
//                } else {
//                    promise(.success(self.medicines))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    nonisolated public func observeMedicine(id: String) -> AnyPublisher<Medicine?, Error> {
//        return Future { promise in
//            Task { @MainActor in
//                if self.shouldThrowError {
//                    promise(.failure(self.errorToThrow))
//                } else {
//                    let medicine = self.medicines.first { $0.id == id }
//                    promise(.success(medicine))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    // Observer simulation methods
//    public func simulateMedicinesUpdate(_ medicines: [Medicine]) {
//        self.medicines = medicines
//    }
//    
//    public func simulateError(_ error: Error) {
//        self.errorToThrow = error
//        self.shouldThrowError = true
//    }
//    
//    public func searchMedicines(query: String) async throws -> [Medicine] {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // If query is empty, return all medicines
//        if trimmedQuery.isEmpty {
//            return medicines
//        }
//        
//        // Filter medicines based on name, description, dosage, form, unit containing the query (case insensitive)
//        return medicines.filter { medicine in
//            medicine.name.localizedCaseInsensitiveContains(trimmedQuery) ||
//            (medicine.description?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) ||
//            (medicine.dosage?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) ||
//            (medicine.form?.localizedCaseInsensitiveContains(trimmedQuery) ?? false) ||
//            medicine.unit.localizedCaseInsensitiveContains(trimmedQuery)
//        }
//    }
//}
//
//// MARK: - Mock Aisle Repository
//
//public class MockAisleRepository: AisleRepositoryProtocol {
//    public var shouldThrowError = false
//    public var aisles: [Aisle] = []
//    public var returnAisles: [Aisle] = []
//    public var medicineCount = 5
//    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
//    public var delayNanoseconds: UInt64 = 0
//    public var callCount = 0
//    
//    public init() {}
//    
//    public func getAisles() async throws -> [Aisle] {
//        callCount += 1
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        return returnAisles.isEmpty ? aisles : returnAisles
//    }
//    
//    public func getAisle(id: String) async throws -> Aisle? {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        return aisles.first { $0.id == id }
//    }
//    
//    public func saveAisle(_ aisle: Aisle) async throws -> Aisle {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        if let index = aisles.firstIndex(where: { $0.id == aisle.id }) {
//            aisles[index] = aisle
//        } else {
//            let newAisle = Aisle(
//                id: aisle.id.isEmpty ? UUID().uuidString : aisle.id,
//                name: aisle.name,
//                description: aisle.description,
//                colorHex: aisle.colorHex,
//                icon: aisle.icon
//            )
//            aisles.append(newAisle)
//            return newAisle
//        }
//        return aisle
//    }
//    
//    public func deleteAisle(id: String) async throws {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        aisles.removeAll { $0.id == id }
//    }
//    
//    public func getMedicineCountByAisle(aisleId: String) async throws -> Int {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        // Mock implementation - return configured count
//        return medicineCount
//    }
//    
//    public func observeAisles() -> AnyPublisher<[Aisle], Error> {
//        if shouldThrowError {
//            return Fail(error: errorToThrow)
//                .eraseToAnyPublisher()
//        }
//        return Just(aisles)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    public func observeAisle(id: String) -> AnyPublisher<Aisle?, Error> {
//        if shouldThrowError {
//            return Fail(error: errorToThrow)
//                .eraseToAnyPublisher()
//        }
//        let aisle = aisles.first { $0.id == id }
//        return Just(aisle)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//    
//    // Observer simulation methods
//    public func simulateAislesUpdate(_ aisles: [Aisle]) {
//        self.aisles = aisles
//    }
//    
//    public func simulateAislesError(_ error: Error) {
//        // Simulate error in observer
//    }
//    
//    public func searchAisles(query: String) async throws -> [Aisle] {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
//        
//        // If query is empty, return all aisles
//        if trimmedQuery.isEmpty {
//            return aisles
//        }
//        
//        // Filter aisles based on name, description containing the query (case insensitive)
//        return aisles.filter { aisle in
//            aisle.name.localizedCaseInsensitiveContains(trimmedQuery) ||
//            (aisle.description?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
//        }
//    }
//}
//
//// MARK: - Mock History Repository
//
//public class MockHistoryRepository: HistoryRepositoryProtocol {
//    public var shouldThrowError = false
//    public var historyEntries: [HistoryEntry] = []
//    public var historyForMedicine: [HistoryEntry] = []
//    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
//    
//    // Call tracking
//    public var addHistoryEntryCallCount = 0
//    public var getHistoryForMedicineCallCount = 0
//    public var lastAddedHistoryEntry: HistoryEntry?
//    public var lastMedicineId: String?
//    public var lastMedicineIdForHistory: String?
//    public var addedEntries: [HistoryEntry] = []
//    
//    public init() {}
//    
//    public func getAllHistory() async throws -> [HistoryEntry] {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        return historyEntries.sorted { $0.timestamp > $1.timestamp }
//    }
//    
//    public func getRecentHistory(limit: Int) async throws -> [HistoryEntry] {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        let safeLimit = max(0, limit)
//        return Array(historyEntries.sorted { $0.timestamp > $1.timestamp }.prefix(safeLimit))
//    }
//    
//    public func getHistoryForMedicine(medicineId: String) async throws -> [HistoryEntry] {
//        getHistoryForMedicineCallCount += 1
//        lastMedicineId = medicineId
//        lastMedicineIdForHistory = medicineId
//        
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        if !historyForMedicine.isEmpty {
//            return historyForMedicine.sorted { $0.timestamp > $1.timestamp }
//        }
//        
//        return historyEntries
//            .filter { $0.medicineId == medicineId }
//            .sorted { $0.timestamp > $1.timestamp }
//    }
//    
//    public func addHistoryEntry(_ entry: HistoryEntry) async throws -> HistoryEntry {
//        addHistoryEntryCallCount += 1
//        lastAddedHistoryEntry = entry
//        
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        let newEntry = HistoryEntry(
//            id: entry.id.isEmpty ? UUID().uuidString : entry.id,
//            medicineId: entry.medicineId,
//            userId: entry.userId,
//            action: entry.action,
//            details: entry.details,
//            timestamp: entry.timestamp
//        )
//        historyEntries.append(newEntry)
//        addedEntries.append(newEntry)
//        return newEntry
//    }
//    
//    public func deleteHistoryEntry(id: String) async throws {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        historyEntries.removeAll { $0.id == id }
//    }
//    
//    public func exportHistory(format: String, medicineId: String?) async throws -> Data {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        let entries = medicineId != nil ?
//            historyEntries.filter { $0.medicineId == medicineId } :
//            historyEntries
//        
//        switch format {
//        case "json":
//            return try JSONEncoder().encode(entries)
//        case "csv":
//            let csvContent = "ID,Medicine ID,User ID,Action,Details,Timestamp\n" +
//                entries.map { "\($0.id),\($0.medicineId),\($0.userId),\($0.action),\($0.details),\($0.timestamp)" }
//                    .joined(separator: "\n")
//            return csvContent.data(using: .utf8) ?? Data()
//        default:
//            return Data()
//        }
//    }
//    
//    public func observeHistoryForMedicine(medicineId: String) -> AnyPublisher<[HistoryEntry], Error> {
//        if shouldThrowError {
//            return Fail(error: errorToThrow)
//                .eraseToAnyPublisher()
//        }
//        let filtered = historyEntries.filter { $0.medicineId == medicineId }
//        return Just(filtered)
//            .setFailureType(to: Error.self)
//            .eraseToAnyPublisher()
//    }
//}
//
//// MARK: - Mock Auth Repository
//
//public class MockAuthRepository: AuthRepositoryProtocol {
//    public var shouldThrowError = false
//    public var shouldThrowOnSignOut = false
//    public var shouldThrowOnSignIn = false
//    public var shouldThrowOnSignUp = false
//    public var shouldThrowOnUpdateProfile = false
//    public var _currentUser: User? = User(id: "mock-user", email: "test@example.com", displayName: "Mock User")
//    public var errorToThrow: Error = AuthError.networkError
//    
//    // Call tracking
//    public var signOutCallCount = 0
//    public var resetPasswordCallCount = 0
//    public var lastResetEmail: String?
//    
//    // Additional aliases for test compatibility
//    public var shouldThrowErrorOnSignOut: Bool {
//        get { shouldThrowOnSignOut }
//        set { shouldThrowOnSignOut = newValue }
//    }
//    public var shouldThrowErrorOnResetPassword: Bool {
//        get { shouldThrowError }
//        set { shouldThrowError = newValue }
//    }
//    public var signOutError: Error {
//        get { errorToThrow }
//        set { errorToThrow = newValue }
//    }
//    public var resetPasswordError: Error {
//        get { errorToThrow }
//        set { errorToThrow = newValue }
//    }
//    
//    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
//    
//    public init() {
//        authStateSubject.value = _currentUser
//    }
//    
//    public var currentUser: User? {
//        get { _currentUser }
//        set {
//            _currentUser = newValue
//            authStateSubject.send(newValue)
//        }
//    }
//    
//    public var authStateDidChange: AnyPublisher<User?, Never> {
//        authStateSubject.eraseToAnyPublisher()
//    }
//    
//    public func signIn(email: String, password: String) async throws -> User {
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        
//        // If a user is already configured and matches the email, return it
//        if let existingUser = currentUser, existingUser.email == email {
//            return existingUser
//        }
//        
//        // Otherwise create a new user
//        let user = User(id: "mock-user", email: email, displayName: "Mock User")
//        currentUser = user
//        return user
//    }
//    
//    public func signUp(email: String, password: String) async throws -> User {
//        if shouldThrowError || shouldThrowOnSignUp {
//            throw errorToThrow
//        }
//        // Return the pre-configured currentUser if it exists and has matching email, otherwise create new
//        if let existingUser = currentUser, existingUser.email == email {
//            return existingUser
//        }
//        let user = User(id: "mock-user", email: email, displayName: "Mock User")
//        currentUser = user
//        return user
//    }
//    
//    public func signUp(email: String, password: String, name: String) async throws -> User {
//        if shouldThrowError || shouldThrowOnSignUp {
//            throw errorToThrow
//        }
//        // Mock always returns "Mock User" as displayName regardless of input name
//        let user = User(id: "mock-user", email: email, displayName: "Mock User")
//        currentUser = user
//        return user
//    }
//    
//    public func signOut() async throws {
//        signOutCallCount += 1
//        if shouldThrowError || shouldThrowOnSignOut {
//            throw errorToThrow
//        }
//        currentUser = nil
//    }
//    
//    public func resetPassword(email: String) async throws {
//        resetPasswordCallCount += 1
//        lastResetEmail = email
//        if shouldThrowError {
//            throw errorToThrow
//        }
//        // Mock implementation - do nothing
//    }
//    
//    public func updateUserProfile(user: User) async throws {
//        if shouldThrowError || shouldThrowOnUpdateProfile {
//            throw errorToThrow
//        }
//        currentUser = user
//    }
//    
//    public func updateProfile(user: User) async throws {
//        try await updateUserProfile(user: user)
//    }
//    
//    public func simulateAuthStateChange(user: User?) {
//        currentUser = user
//    }
//}
