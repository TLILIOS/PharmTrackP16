import Foundation
import FirebaseFirestore
@testable import MediStock

// MARK: - Mock Medicine Data Service pour les tests unitaires
/// Mock qui simule MedicineDataService sans dépendre de Firebase

final class MockMedicineDataService {
    // MARK: - In-Memory Storage

    var medicines: [Medicine] = []

    // MARK: - Test Configuration

    var shouldFailGetMedicines = false
    var shouldFailSaveMedicine = false
    var shouldFailUpdateStock = false
    var shouldFailDeleteMedicine = false
    var shouldFailAdjustStock = false
    var shouldFailGetMedicine = false

    var getAllMedicinesCallCount = 0
    var getMedicinesPaginatedCallCount = 0
    var getMedicineCallCount = 0
    var saveMedicineCallCount = 0
    var updateStockCallCount = 0
    var deleteMedicineCallCount = 0
    var updateMultipleMedicinesCallCount = 0
    var adjustStockCallCount = 0

    var listenerCallback: (([Medicine]) -> Void)?
    var isListening = false
    var activeListener: MockListenerRegistration?

    // Pagination state
    private var currentPage = 0
    private var pageSize = 20

    // Mock HistoryService pour l'injection
    var mockHistoryService: MockHistoryDataService

    // MARK: - Errors

    enum MockDataError: LocalizedError {
        case operationFailed
        case medicineNotFound
        case validationFailed
        case networkError

        var errorDescription: String? {
            switch self {
            case .operationFailed: return "Mock operation failed"
            case .medicineNotFound: return "Medicine not found"
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

    func getAllMedicines() async throws -> [Medicine] {
        getAllMedicinesCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        guard !shouldFailGetMedicines else {
            throw MockDataError.operationFailed
        }

        return medicines
    }

    func getMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        getMedicinesPaginatedCallCount += 1

        guard !shouldFailGetMedicines else {
            throw MockDataError.operationFailed
        }

        if refresh {
            currentPage = 0
        }

        let startIndex = currentPage * limit
        let endIndex = min(startIndex + limit, medicines.count)

        guard startIndex < medicines.count else {
            return []
        }

        currentPage += 1
        return Array(medicines[startIndex..<endIndex])
    }

    func getMedicine(by id: String) async throws -> Medicine? {
        getMedicineCallCount += 1

        guard !shouldFailGetMedicine else {
            throw MockDataError.operationFailed
        }

        return medicines.first { $0.id == id }
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

        let savedMedicine: Medicine
        let isNew = medicine.id?.isEmpty ?? true

        if let index = medicines.firstIndex(where: { $0.id == medicine.id && !isNew }) {
            // Update existing
            savedMedicine = medicine.copyWith(updatedAt: Date())
            medicines[index] = savedMedicine
        } else {
            // Create new
            savedMedicine = medicine.copyWith(
                id: medicine.id?.isEmpty ?? true ? UUID().uuidString : medicine.id,
                createdAt: Date(),
                updatedAt: Date()
            )
            medicines.append(savedMedicine)
        }

        // Record history
        let action = isNew ? "Création" : "Modification"
        let details = isNew
            ? "Ajout du médicament \(savedMedicine.name) avec un stock initial de \(savedMedicine.currentQuantity)"
            : "Mise à jour du médicament \(savedMedicine.name)"

        try await mockHistoryService.recordMedicineAction(
            medicineId: savedMedicine.id ?? "",
            medicineName: savedMedicine.name,
            action: action,
            details: details
        )

        // Notify listeners
        listenerCallback?(medicines)

        return savedMedicine
    }

    func deleteMedicine(_ medicine: Medicine) async throws {
        deleteMedicineCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailDeleteMedicine else {
            throw MockDataError.operationFailed
        }

        guard let medicineId = medicine.id, !medicineId.isEmpty else {
            throw ValidationError.invalidId
        }

        guard medicines.contains(where: { $0.id == medicineId }) else {
            throw MockDataError.medicineNotFound
        }

        medicines.removeAll { $0.id == medicineId }

        // Record history
        try await mockHistoryService.recordDeletion(
            itemType: "medicine",
            itemId: medicineId,
            itemName: medicine.name,
            details: "Suppression du médicament \(medicine.name)"
        )

        // Notify listeners
        listenerCallback?(medicines)
    }

    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        updateStockCallCount += 1

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        guard !shouldFailUpdateStock else {
            throw MockDataError.operationFailed
        }

        guard let index = medicines.firstIndex(where: { $0.id == id }) else {
            throw MockDataError.medicineNotFound
        }

        guard newStock >= 0 else {
            throw ValidationError.negativeQuantity(field: "stock")
        }

        let updatedMedicine = medicines[index].copyWith(
            currentQuantity: newStock,
            updatedAt: Date()
        )

        medicines[index] = updatedMedicine

        // Record history
        try await mockHistoryService.recordMedicineAction(
            medicineId: id,
            medicineName: updatedMedicine.name,
            action: "Ajout stock",
            details: "Stock mis à jour: \(newStock)"
        )

        // Notify listeners
        listenerCallback?(medicines)

        return updatedMedicine
    }

    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        updateMultipleMedicinesCallCount += 1

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

    func adjustStock(medicineId: String, adjustment: Int) async throws -> Medicine {
        adjustStockCallCount += 1

        guard !shouldFailAdjustStock else {
            throw MockDataError.operationFailed
        }

        guard adjustment != 0 else {
            throw ValidationError.invalidStockAdjustment
        }

        guard let index = medicines.firstIndex(where: { $0.id == medicineId }) else {
            throw MockDataError.medicineNotFound
        }

        let newStock = max(0, medicines[index].currentQuantity + adjustment)
        let updatedMedicine = medicines[index].copyWith(
            currentQuantity: newStock,
            updatedAt: Date()
        )

        medicines[index] = updatedMedicine

        // Record history
        let action = adjustment > 0 ? "Ajout" : "Retrait"
        let details = "\(action) de \(abs(adjustment)) unité(s). Nouveau stock: \(newStock)"

        try await mockHistoryService.recordStockAdjustment(
            medicineId: medicineId,
            medicineName: updatedMedicine.name,
            adjustment: adjustment,
            newStock: newStock,
            details: details
        )

        // Notify listeners
        listenerCallback?(medicines)

        return updatedMedicine
    }

    // MARK: - Listeners

    func createMedicinesListener(completion: @escaping ([Medicine]) -> Void) -> ListenerRegistration {
        isListening = true
        listenerCallback = completion

        let mockListener = MockListenerRegistration { [weak self] in
            self?.isListening = false
            self?.listenerCallback = nil
        }

        activeListener = mockListener

        // Notify immediately with current data
        completion(medicines)

        return mockListener
    }

    // MARK: - Test Helpers

    /// Réinitialise toutes les données et compteurs
    func reset() {
        medicines = []
        shouldFailGetMedicines = false
        shouldFailSaveMedicine = false
        shouldFailUpdateStock = false
        shouldFailDeleteMedicine = false
        shouldFailAdjustStock = false
        shouldFailGetMedicine = false
        getAllMedicinesCallCount = 0
        getMedicinesPaginatedCallCount = 0
        getMedicineCallCount = 0
        saveMedicineCallCount = 0
        updateStockCallCount = 0
        deleteMedicineCallCount = 0
        updateMultipleMedicinesCallCount = 0
        adjustStockCallCount = 0
        isListening = false
        listenerCallback = nil
        activeListener = nil
        currentPage = 0
        mockHistoryService.reset()
    }

    /// Ajoute des données de test
    func seedTestData(aisleId: String = "aisle-1") {
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
                aisleId: aisleId,
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
        adjustStock: Bool = false,
        getMedicine: Bool = false
    ) {
        shouldFailGetMedicines = getMedicines
        shouldFailSaveMedicine = saveMedicine
        shouldFailUpdateStock = updateStock
        shouldFailDeleteMedicine = deleteMedicine
        shouldFailAdjustStock = adjustStock
        shouldFailGetMedicine = getMedicine
    }
}

// MARK: - Mock Listener Registration

class MockListenerRegistration: NSObject, ListenerRegistration {
    private let removeHandler: () -> Void

    init(removeHandler: @escaping () -> Void) {
        self.removeHandler = removeHandler
        super.init()
    }

    func remove() {
        removeHandler()
    }
}
