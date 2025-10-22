import Foundation
import FirebaseFirestore

// MARK: - Aisle Repository

class AisleRepository: AisleRepositoryProtocol {
    private let aisleService: AisleDataService
    private var listener: ListenerRegistration?

    init(aisleService: AisleDataService = AisleDataService()) {
        self.aisleService = aisleService
    }

    func fetchAisles() async throws -> [Aisle] {
        return try await aisleService.getAllAisles()
    }

    func fetchAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        return try await aisleService.getAislesPaginated(limit: limit, refresh: refresh)
    }

    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        return try await aisleService.saveAisle(aisle)
    }

    func deleteAisle(id: String) async throws {
        // Récupérer le rayon puis le supprimer
        guard let aisle = try await aisleService.getAisle(by: id) else {
            throw NSError(
                domain: "AisleRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Rayon non trouvé"]
            )
        }
        try await aisleService.deleteAisle(aisle)
    }

    // MARK: - Real-time Listeners

    func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {
        listener = aisleService.createAislesListener(completion: completion)
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}
