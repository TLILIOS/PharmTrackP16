import Foundation

// MARK: - Medicine Repository

class MedicineRepository: MedicineRepositoryProtocol {
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = FirebaseDataService()) {
        self.dataService = dataService
    }

    func fetchMedicines() async throws -> [Medicine] {
        return try await dataService.getMedicines()
    }

    func fetchMedicinesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Medicine] {
        return try await dataService.getMedicinesPaginated(limit: limit, refresh: refresh)
    }

    func saveMedicine(_ medicine: Medicine) async throws -> Medicine {
        return try await dataService.saveMedicine(medicine)
    }

    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine {
        return try await dataService.updateMedicineStock(id: id, newStock: newStock)
    }

    func deleteMedicine(id: String) async throws {
        try await dataService.deleteMedicine(id: id)
    }

    func updateMultipleMedicines(_ medicines: [Medicine]) async throws {
        try await dataService.updateMultipleMedicines(medicines)
    }

    func deleteMultipleMedicines(ids: [String]) async throws {
        try await dataService.deleteMultipleMedicines(ids: ids)
    }

    // MARK: - Real-time Listeners

    func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {
        dataService.startListeningToMedicines(completion: completion)
    }

    func stopListening() {
        dataService.stopListening()
    }
}