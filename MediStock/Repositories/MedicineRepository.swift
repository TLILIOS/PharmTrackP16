import Foundation
import FirebaseFirestore

// MARK: - Medicine Repository

class MedicineRepository: MedicineRepositoryProtocol {
    private let medicineService: MedicineDataService
    private var listener: ListenerRegistration?

    init(medicineService: MedicineDataService = MedicineDataService()) {
        self.medicineService = medicineService
    }

    func fetchMedicines() async throws -> [Medicine] {
        return try await medicineService.getAllMedicines()
    }

    func fetchMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        return try await medicineService.getMedicinesPaginated(limit: limit, refresh: refresh)
    }

    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        return try await medicineService.saveMedicine(medicine)
    }

    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        return try await medicineService.updateMedicineStock(id: id, newStock: newStock)
    }

    func deleteMedicine(id: String) async throws {
        // Récupérer le médicament puis le supprimer
        guard let medicine = try await medicineService.getMedicine(by: id) else {
            throw NSError(
                domain: "MedicineRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Médicament non trouvé"]
            )
        }
        try await medicineService.deleteMedicine(medicine)
    }

    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        try await medicineService.updateMultipleMedicines(medicines)
    }

    func deleteMultipleMedicines(ids: [String]) async throws {
        // Supprimer chaque médicament individuellement
        for id in ids {
            try await deleteMedicine(id: id)
        }
    }

    // MARK: - Real-time Listeners

    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        listener = medicineService.createMedicinesListener(completion: completion)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}