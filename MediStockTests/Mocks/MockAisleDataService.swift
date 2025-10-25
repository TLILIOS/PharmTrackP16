import Foundation
import FirebaseFirestore
@testable import MediStock

// MARK: - Mock Aisle Data Service pour les tests unitaires
/// Mock qui simule AisleDataService sans dépendre de Firebase

final class MockAisleDataService {
    // MARK: - In-Memory Storage

    var aisles: [Aisle] = []

    // MARK: - Test Configuration

    var shouldFailGetAisles = false
    var shouldFailSaveAisle = false
    var shouldFailDeleteAisle = false
    var shouldFailGetAisle = false
    var shouldFailCheckAisleExists = false

    var getAllAislesCallCount = 0
    var getAislesPaginatedCallCount = 0
    var getAisleCallCount = 0
    var checkAisleExistsCallCount = 0
    var saveAisleCallCount = 0
    var deleteAisleCallCount = 0
    var countMedicinesInAisleCallCount = 0

    var listenerCallback: (([Aisle]) -> Void)?
    var isListening = false
    var activeListener: MockListenerRegistration?

    // Pagination state
    private var currentPage = 0
    private var pageSize = 20

    // Mock HistoryService pour l'injection
    var mockHistoryService: MockHistoryDataService

    // For simulating medicine count
    var medicineCountByAisle: [String: Int] = [:]

    // MARK: - Errors

    enum MockDataError: LocalizedError {
        case operationFailed
        case aisleNotFound
        case validationFailed
        case networkError

        var errorDescription: String? {
            switch self {
            case .operationFailed: return "Mock operation failed"
            case .aisleNotFound: return "Aisle not found"
            case .validationFailed: return "Validation failed"
            case .networkError: return "Network error occurred"
            }
        }
    }

    // MARK: - Initialization

    init(historyService: MockHistoryDataService = MockHistoryDataService()) {
        self.mockHistoryService = historyService
    }

    // MARK: - Public Methods

    func getAllAisles() async throws -> [Aisle] {
        getAllAislesCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetAisles else {
            throw MockDataError.operationFailed
        }

        return aisles
    }

    func getAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        getAislesPaginatedCallCount += 1

        guard !shouldFailGetAisles else {
            throw MockDataError.operationFailed
        }

        if refresh {
            currentPage = 0
        }

        let startIndex = currentPage * limit
        let endIndex = min(startIndex + limit, aisles.count)

        guard startIndex < aisles.count else {
            return []
        }

        currentPage += 1
        return Array(aisles[startIndex..<endIndex])
    }

    func getAisle(by id: String) async throws -> Aisle? {
        getAisleCallCount += 1

        guard !shouldFailGetAisle else {
            throw MockDataError.operationFailed
        }

        return aisles.first { $0.id == id }
    }

    func checkAisleExists(_ aisleId: String) async throws -> Bool {
        checkAisleExistsCallCount += 1

        guard !shouldFailCheckAisleExists else {
            throw MockDataError.operationFailed
        }

        return aisles.contains { $0.id == aisleId }
    }

    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        saveAisleCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailSaveAisle else {
            throw MockDataError.operationFailed
        }

        // Validation
        try aisle.validate()

        let isNew = aisle.id == nil || aisle.id?.isEmpty == true

        // Check for duplicate names (excluding current aisle if updating)
        let isDuplicate = aisles.contains { existingAisle in
            existingAisle.id != aisle.id &&
            existingAisle.name.lowercased() == aisle.name.lowercased()
        }

        guard !isDuplicate else {
            throw ValidationError.duplicateAisleName(name: aisle.name)
        }

        var savedAisle = aisle
        if let index = aisles.firstIndex(where: { $0.id == aisle.id && !isNew }) {
            // Update existing
            savedAisle.id = aisle.id
            aisles[index] = savedAisle
        } else {
            // Create new
            if savedAisle.id == nil || savedAisle.id?.isEmpty == true {
                savedAisle.id = UUID().uuidString
            }
            aisles.append(savedAisle)
        }

        // Record history
        let action = isNew ? "Création" : "Modification"
        let details = isNew
            ? "Création du rayon \(savedAisle.name)"
            : "Mise à jour du rayon \(savedAisle.name)"

        try await mockHistoryService.recordAisleAction(
            aisleId: savedAisle.id ?? "",
            aisleName: savedAisle.name,
            action: action,
            details: details
        )

        // Notify listeners
        listenerCallback?(aisles)

        return savedAisle
    }

    func deleteAisle(_ aisle: Aisle) async throws {
        deleteAisleCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailDeleteAisle else {
            throw MockDataError.operationFailed
        }

        guard let aisleId = aisle.id, !aisleId.isEmpty else {
            throw ValidationError.invalidId
        }

        // Check if aisle has medicines
        let medicineCount = medicineCountByAisle[aisleId] ?? 0
        guard medicineCount == 0 else {
            throw ValidationError.aisleContainsMedicines(count: medicineCount)
        }

        aisles.removeAll { $0.id == aisleId }

        // Record history
        try await mockHistoryService.recordDeletion(
            itemType: "aisle",
            itemId: aisleId,
            itemName: aisle.name,
            details: "Suppression du rayon \(aisle.name)"
        )

        // Notify listeners
        listenerCallback?(aisles)
    }

    func countMedicinesInAisle(_ aisleId: String) async throws -> Int {
        countMedicinesInAisleCallCount += 1

        guard !shouldFailGetAisles else {
            throw MockDataError.operationFailed
        }

        return medicineCountByAisle[aisleId] ?? 0
    }

    // MARK: - Listeners

    func createAislesListener(completion: @escaping ([Aisle]) -> Void) -> ListenerRegistration {
        isListening = true
        listenerCallback = completion

        let mockListener = MockListenerRegistration { [weak self] in
            self?.isListening = false
            self?.listenerCallback = nil
        }

        activeListener = mockListener

        // Notify immediately with current data
        completion(aisles)

        return mockListener
    }

    // MARK: - Test Helpers

    /// Réinitialise toutes les données et compteurs
    func reset() {
        aisles = []
        medicineCountByAisle = [:]
        shouldFailGetAisles = false
        shouldFailSaveAisle = false
        shouldFailDeleteAisle = false
        shouldFailGetAisle = false
        shouldFailCheckAisleExists = false
        getAllAislesCallCount = 0
        getAislesPaginatedCallCount = 0
        getAisleCallCount = 0
        checkAisleExistsCallCount = 0
        saveAisleCallCount = 0
        deleteAisleCallCount = 0
        countMedicinesInAisleCallCount = 0
        isListening = false
        listenerCallback = nil
        activeListener = nil
        currentPage = 0
        mockHistoryService.reset()
    }

    /// Ajoute des données de test
    func seedTestData() {
        var aisle1 = Aisle(name: "Pharmacie", description: "Rayons généraux", colorHex: "#4CAF50", icon: "pills")
        aisle1.id = "aisle-1"

        var aisle2 = Aisle(name: "Spécialités", description: "Médicaments spécialisés", colorHex: "#2196F3", icon: "cross.case")
        aisle2.id = "aisle-2"

        aisles = [aisle1, aisle2]
    }

    /// Configure les erreurs pour tester les cas d'échec
    func configureFailures(
        getAisles: Bool = false,
        saveAisle: Bool = false,
        deleteAisle: Bool = false,
        getAisle: Bool = false,
        checkAisleExists: Bool = false
    ) {
        shouldFailGetAisles = getAisles
        shouldFailSaveAisle = saveAisle
        shouldFailDeleteAisle = deleteAisle
        shouldFailGetAisle = getAisle
        shouldFailCheckAisleExists = checkAisleExists
    }

    /// Configure le nombre de médicaments dans un rayon (pour les tests de suppression)
    func setMedicineCount(for aisleId: String, count: Int) {
        medicineCountByAisle[aisleId] = count
    }
}
