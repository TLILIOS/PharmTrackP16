import Foundation
@testable import MediStock

// MARK: - Mock Medicine Use Cases
@MainActor
public class MockGetMedicinesUseCase: GetMedicinesUseCaseProtocol {
    public var shouldThrowError = false
    public var medicines: [Medicine] = []
    public var returnMedicines: [Medicine] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var callCount = 0
    
    public init() {}
    
    public func execute() async throws -> [Medicine] {
        callCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        return returnMedicines.isEmpty ? medicines : returnMedicines
    }
}

public class MockGetMedicineUseCase: GetMedicineUseCaseProtocol {
    public var shouldThrowError = false
    public var medicine: Medicine?
    public var returnMedicine: Medicine?
    public var requestedMedicineIds: [String] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var lastId: String?
    
    public init() {}
    
    public func execute(id: String) async throws -> Medicine {
        lastId = id
        requestedMedicineIds.append(id)
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let medicine = returnMedicine ?? medicine else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Medicine not found"])
        }
        
        return medicine
    }
}

public class MockAddMedicineUseCase: AddMedicineUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var addedMedicines: [Medicine] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(medicine: Medicine) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        addedMedicines.append(medicine)
    }
}

public class MockUpdateMedicineUseCase: UpdateMedicineUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var updatedMedicines: [Medicine] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(medicine: Medicine) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        updatedMedicines.append(medicine)
    }
}

public class MockDeleteMedicineUseCase: DeleteMedicineUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var deletedMedicineIds: [String] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(id: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        deletedMedicineIds.append(id)
    }
}

public class MockUpdateMedicineStockUseCase: UpdateMedicineStockUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var updatedMedicine: Medicine?
    public var lastUpdateCall: (medicineId: String, newQuantity: Int, comment: String)?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(medicineId: String, newQuantity: Int, comment: String) async throws -> Medicine {
        if shouldThrowError {
            throw errorToThrow
        }
        
        lastUpdateCall = (medicineId, newQuantity, comment)
        
        guard let medicine = updatedMedicine else {
            // Return a default medicine if none is set
            return Medicine(
                id: medicineId,
                name: "Mock Medicine",
                description: "Mock Description",
                dosage: "500mg",
                form: "Tablet",
                reference: "MOCK-001",
                unit: "tablet",
                currentQuantity: newQuantity,
                maxQuantity: 100,
                warningThreshold: 20,
                criticalThreshold: 10,
                expiryDate: Date(),
                aisleId: "mock-aisle",
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        
        return medicine
    }
}

public class MockSearchMedicineUseCase: SearchMedicineUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var searchResults: [Medicine] = []
    public var returnMedicines: [Medicine] = []
    public var lastSearchQuery: String?
    public var lastQuery: String?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var callCount = 0
    
    public func execute(query: String) async throws -> [Medicine] {
        callCount += 1
        lastSearchQuery = query
        lastQuery = query
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return returnMedicines.isEmpty ? searchResults : returnMedicines
    }
}

// MARK: - Mock Aisle Use Cases

public class MockGetAislesUseCase: GetAislesUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var aisles: [Aisle] = []
    public var returnAisles: [Aisle] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var callCount = 0
    
    public func execute() async throws -> [Aisle] {
        callCount += 1
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        return returnAisles.isEmpty ? aisles : returnAisles
    }
}

public class MockAddAisleUseCase: AddAisleUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var addedAisles: [Aisle] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(aisle: Aisle) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        addedAisles.append(aisle)
    }
}

public class MockUpdateAisleUseCase: UpdateAisleUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var updatedAisles: [Aisle] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(aisle: Aisle) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        updatedAisles.append(aisle)
    }
}

public class MockDeleteAisleUseCase: DeleteAisleUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var deletedAisleIds: [String] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(id: String) async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        deletedAisleIds.append(id)
    }
}

public class MockSearchAisleUseCase: SearchAisleUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var searchResults: [Aisle] = []
    public var returnAisles: [Aisle] = []
    public var lastSearchQuery: String?
    public var lastQuery: String?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var callCount = 0
    
    public func execute(query: String) async throws -> [Aisle] {
        callCount += 1
        lastSearchQuery = query
        lastQuery = query
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return returnAisles.isEmpty ? searchResults : returnAisles
    }
}

public class MockGetMedicineCountByAisleUseCase: GetMedicineCountByAisleUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var medicineCount = 5
    public var countsPerAisle: [String: Int] = [:]
    public var callCount = 0
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(aisleId: String) async throws -> Int {
        callCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Return specific count for this aisle if set, otherwise default
        return countsPerAisle[aisleId] ?? medicineCount
    }
}

// MARK: - Mock Auth Use Cases

public class MockGetUserUseCase: GetUserUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var user: User? = User(id: "mock-user", email: "test@example.com", displayName: "Mock User")
    public var returnUser: User? = User(id: "mock-user", email: "test@example.com", displayName: "Mock User")
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var callCount = 0
    
    public func execute() async throws -> User {
        callCount += 1
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let user = returnUser ?? user else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        return user
    }
}

public class MockSignOutUseCase: SignOutUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var signOutCalled = false
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute() async throws {
        if shouldThrowError {
            throw errorToThrow
        }
        signOutCalled = true
    }
}

// MARK: - Mock History Use Cases

public class MockGetHistoryUseCase: GetHistoryUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var historyEntries: [HistoryEntry] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    
    public func execute() async throws -> [HistoryEntry] {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        return historyEntries
    }
}

public class MockGetRecentHistoryUseCase: GetRecentHistoryUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var historyEntries: [HistoryEntry] = []
    public var returnHistory: [HistoryEntry] = []
    public var lastLimit: Int?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var callCount = 0
    
    public func execute(limit: Int) async throws -> [HistoryEntry] {
        callCount += 1
        lastLimit = limit
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let sourceHistory = returnHistory.isEmpty ? historyEntries : returnHistory
        let safeLimit = max(0, limit)
        return Array(sourceHistory.prefix(safeLimit))
    }
}

public class MockExportHistoryUseCase: ExportHistoryUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var exportData = Data()
    public var lastFormat: ExportFormat?
    public var executeCallCount = 0
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    
    public func execute(format: ExportFormat) async throws -> Data {
        executeCallCount += 1
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        lastFormat = format
        return exportData
    }
}

public class MockGetHistoryForMedicineUseCase: GetHistoryForMedicineUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var historyEntries: [HistoryEntry] = []
    public var lastMedicineId: String?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var delayNanoseconds: UInt64 = 0
    public var callCount = 0
    
    public func execute(medicineId: String) async throws -> [HistoryEntry] {
        callCount += 1
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        lastMedicineId = medicineId
        return historyEntries.filter { $0.medicineId == medicineId }
    }
}

// MARK: - Mock Auth Use Cases - Additional

public class MockSignInUseCase: SignInUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var lastCredentials: (email: String, password: String)?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var callCount = 0
    public var delayNanoseconds: UInt64 = 0
    
    public func execute(email: String, password: String) async throws {
        callCount += 1
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        lastCredentials = (email, password)
    }
}

public class MockSignUpUseCase: SignUpUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var lastCredentials: (email: String, password: String, name: String)?
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    public var callCount = 0
    public var delayNanoseconds: UInt64 = 0
    
    public func execute(email: String, password: String, name: String) async throws {
        callCount += 1
        
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        lastCredentials = (email, password, name)
    }
}


// MARK: - Mock Other Use Cases

public class MockAdjustStockUseCase: AdjustStockUseCaseProtocol {
    public init() {}
    public var shouldThrowError = false
    public var lastAdjustment: (medicineId: String, adjustment: Int, reason: String)?
    public var adjustmentCalls: [(medicineId: String, adjustment: Int, reason: String)] = []
    public var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
    
    public func execute(medicineId: String, adjustment: Int, reason: String) async throws {
        lastAdjustment = (medicineId, adjustment, reason)
        adjustmentCalls.append((medicineId, adjustment, reason))
        if shouldThrowError {
            throw errorToThrow
        }
    }
}

// MARK: - Mock App Coordinator

@MainActor
public class MockAppCoordinator: AppCoordinator {
    public var navigationCallCount = 0
    public var lastDestination: NavigationDestination?
    
    public override func navigateFromDashboard(_ destination: NavigationDestination) {
        navigationCallCount += 1
        lastDestination = destination
        super.navigateFromDashboard(destination)
    }
}
