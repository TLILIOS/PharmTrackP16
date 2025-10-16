import Foundation
@testable import MediStock

// MARK: - Mock Data Service pour les tests unitaires

final class MockDataService: DataServiceProtocol {
    // MARK: - In-Memory Storage

    var medicines: [Medicine] = []
    var aisles: [Aisle] = []
    var history: [HistoryEntry] = []

    // MARK: - Test Configuration

    var shouldFailGetMedicines = false
    var shouldFailSaveMedicine = false
    var shouldFailUpdateStock = false
    var shouldFailDeleteMedicine = false
    var shouldFailGetAisles = false
    var shouldFailSaveAisle = false
    var shouldFailDeleteAisle = false
    var shouldFailGetHistory = false
    var shouldFailAddHistory = false

    var getMedicinesCallCount = 0
    var saveMedicineCallCount = 0
    var updateStockCallCount = 0
    var deleteMedicineCallCount = 0
    var getAislesCallCount = 0
    var saveAisleCallCount = 0
    var deleteAisleCallCount = 0
    var getHistoryCallCount = 0
    var addHistoryCallCount = 0

    var listenerCallback: (([Medicine]) -> Void)?
    var isListening = false

    // MARK: - Errors

    enum MockDataError: LocalizedError {
        case operationFailed
        case itemNotFound
        case validationFailed
        case networkError

        var errorDescription: String? {
            switch self {
            case .operationFailed: return "Mock operation failed"
            case .itemNotFound: return "Item not found"
            case .validationFailed: return "Validation failed"
            case .networkError: return "Network error occurred"
            }
        }
    }

    // MARK: - Medicines

    func getMedicines() async throws -> [Medicine] {
        getMedicinesCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetMedicines else {
            throw MockDataError.operationFailed
        }

        return medicines
    }

    func getMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] {
        guard !shouldFailGetMedicines else {
            throw MockDataError.operationFailed
        }

        if refresh {
            return Array(medicines.prefix(limit))
        }

        return medicines
    }

    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        saveMedicineCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailSaveMedicine else {
            throw MockDataError.operationFailed
        }

        // Validation
        try medicine.validate()

        // Check if aisle exists
        guard aisles.contains(where: { $0.id == medicine.aisleId }) else {
            throw ValidationError.invalidAisleReference(aisleId: medicine.aisleId)
        }

        let savedMedicine: Medicine
        if let index = medicines.firstIndex(where: { $0.id == medicine.id }) {
            // Update existing
            savedMedicine = medicine.copyWith(updatedAt: Date())
            medicines[index] = savedMedicine
            addMockHistoryEntry(action: "Modification", medicineId: medicine.id)
        } else {
            // Create new
            savedMedicine = medicine.copyWith(
                id: medicine.id.isEmpty ? UUID().uuidString : medicine.id,
                createdAt: Date(),
                updatedAt: Date()
            )
            medicines.append(savedMedicine)
            addMockHistoryEntry(action: "Création", medicineId: savedMedicine.id)
        }

        // Notify listeners
        listenerCallback?(medicines)

        return savedMedicine
    }

    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        updateStockCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailUpdateStock else {
            throw MockDataError.operationFailed
        }

        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw MockDataError.itemNotFound
        }

        guard newStock >= 0 else {
            throw ValidationError.negativeQuantity(field: "stock")
        }

        let oldStock = medicines[index].currentQuantity
        let updatedMedicine = medicines[index].copyWith(
            currentQuantity: newStock,
            updatedAt: Date()
        )

        medicines[index] = updatedMedicine

        addMockHistoryEntry(
            action: "Ajout stock",
            medicineId: id,
            details: "Stock: \(oldStock) → \(newStock)"
        )

        // Notify listeners
        listenerCallback?(medicines)

        return updatedMedicine
    }

    func deleteMedicine(id: String) async throws {
        deleteMedicineCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailDeleteMedicine else {
            throw MockDataError.operationFailed
        }

        guard medicines.contains(where: { $0.id == id }) else {
            throw MockDataError.itemNotFound
        }

        medicines.removeAll { $0.id == id }
        addMockHistoryEntry(action: "Suppression", medicineId: id)

        // Notify listeners
        listenerCallback?(medicines)
    }

    // MARK: - Aisles

    func getAisles() async throws -> [Aisle] {
        getAislesCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetAisles else {
            throw MockDataError.operationFailed
        }

        return aisles
    }

    func getAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] {
        guard !shouldFailGetAisles else {
            throw MockDataError.operationFailed
        }

        if refresh {
            return Array(aisles.prefix(limit))
        }

        return aisles
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

        // Check for duplicate names
        let isDuplicate = aisles.contains { existingAisle in
            existingAisle.id != aisle.id &&
            existingAisle.name.lowercased() == aisle.name.lowercased()
        }

        guard !isDuplicate else {
            throw ValidationError.nameAlreadyExists(name: aisle.name)
        }

        let savedAisle: Aisle
        if let index = aisles.firstIndex(where: { $0.id == aisle.id }) {
            // Update existing
            savedAisle = aisle
            aisles[index] = savedAisle
        } else {
            // Create new
            if aisle.id == nil || aisle.id?.isEmpty == true {
                var newAisle = aisle
                newAisle.id = UUID().uuidString
                savedAisle = newAisle
            } else {
                savedAisle = aisle
            }
            aisles.append(savedAisle)
        }

        return savedAisle
    }

    func deleteAisle(id: String) async throws {
        deleteAisleCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailDeleteAisle else {
            throw MockDataError.operationFailed
        }

        // Check if aisle has medicines
        let hasMedicines = medicines.contains { $0.aisleId == id }
        guard !hasMedicines else {
            throw NSError(
                domain: "MockDataService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Impossible de supprimer un rayon contenant des médicaments"]
            )
        }

        aisles.removeAll { $0.id == id }
    }

    // MARK: - History

    func getHistory() async throws -> [HistoryEntry] {
        getHistoryCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetHistory else {
            throw MockDataError.operationFailed
        }

        return history.sorted { $0.timestamp > $1.timestamp }
    }

    func addHistoryEntry(_ entry: HistoryEntry) async throws {
        addHistoryCallCount += 1

        guard !shouldFailAddHistory else {
            throw MockDataError.operationFailed
        }

        history.append(entry)
    }

    // MARK: - Batch Operations

    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        guard !shouldFailUpdateStock else {
            throw MockDataError.operationFailed
        }

        for medicine in medicines {
            try medicine.validate()

            if let index = self.medicines.firstIndex(where: { $0.id == medicine.id }) {
                self.medicines[index] = medicine
            }
        }
    }

    func deleteMultipleMedicines(ids: [String]) async throws {
        guard !shouldFailDeleteMedicine else {
            throw MockDataError.operationFailed
        }

        medicines.removeAll { ids.contains($0.id) }
    }

    // MARK: - Listeners

    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        isListening = true
        listenerCallback = completion

        // Notify immediately with current data
        completion(medicines)
    }

    func stopListening() {
        isListening = false
        listenerCallback = nil
    }

    // MARK: - Test Helpers

    /// Réinitialise toutes les données et compteurs
    func reset() {
        medicines = []
        aisles = []
        history = []
        shouldFailGetMedicines = false
        shouldFailSaveMedicine = false
        shouldFailUpdateStock = false
        shouldFailDeleteMedicine = false
        shouldFailGetAisles = false
        shouldFailSaveAisle = false
        shouldFailDeleteAisle = false
        shouldFailGetHistory = false
        shouldFailAddHistory = false
        getMedicinesCallCount = 0
        saveMedicineCallCount = 0
        updateStockCallCount = 0
        deleteMedicineCallCount = 0
        getAislesCallCount = 0
        saveAisleCallCount = 0
        deleteAisleCallCount = 0
        getHistoryCallCount = 0
        addHistoryCallCount = 0
        isListening = false
        listenerCallback = nil
    }

    /// Ajoute des données de test
    func seedTestData() {
        // Ajouter des rayons de test
        var aisle1 = Aisle(name: "Pharmacie", description: "Rayons généraux", colorHex: "#4CAF50", icon: "pills")
        aisle1.id = "aisle-1"

        var aisle2 = Aisle(name: "Spécialités", description: "Médicaments spécialisés", colorHex: "#2196F3", icon: "cross.case")
        aisle2.id = "aisle-2"

        aisles = [aisle1, aisle2]

        // Ajouter des médicaments de test
        medicines = [
            Medicine(
                id: "med-1",
                name: "Doliprane 500mg",
                description: "Paracétamol",
                dosage: "500mg",
                form: "comprimé",
                reference: "DOL500",
                unit: "comprimés",
                currentQuantity: 100,
                maxQuantity: 500,
                warningThreshold: 50,
                criticalThreshold: 20,
                expiryDate: Date().addingTimeInterval(365 * 24 * 60 * 60),
                aisleId: "aisle-1",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }

    /// Configure les erreurs pour tester les cas d'échec
    func configureFailures(
        getMedicines: Bool = false,
        saveMedicine: Bool = false,
        updateStock: Bool = false,
        deleteMedicine: Bool = false,
        getAisles: Bool = false,
        saveAisle: Bool = false,
        deleteAisle: Bool = false,
        getHistory: Bool = false,
        addHistory: Bool = false
    ) {
        shouldFailGetMedicines = getMedicines
        shouldFailSaveMedicine = saveMedicine
        shouldFailUpdateStock = updateStock
        shouldFailDeleteMedicine = deleteMedicine
        shouldFailGetAisles = getAisles
        shouldFailSaveAisle = saveAisle
        shouldFailDeleteAisle = deleteAisle
        shouldFailGetHistory = getHistory
        shouldFailAddHistory = addHistory
    }

    // MARK: - Private Helpers

    private func addMockHistoryEntry(
        action: String,
        medicineId: String,
        details: String? = nil
    ) {
        let entry = HistoryEntry(
            id: UUID().uuidString,
            medicineId: medicineId,
            userId: "mock-user-id",
            action: action,
            details: details ?? "Action: \(action)",
            timestamp: Date()
        )
        history.append(entry)
    }
}
