import Foundation

// MARK: - Aisle Repository

class AisleRepository: AisleRepositoryProtocol {
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = FirebaseDataService()) {
        self.dataService = dataService
    }
    
    func fetchAisles() async throws -> [Aisle] {
        return try await dataService.getAisles()
    }
    
    func fetchAislesPaginated(limit: Int = 20, refresh: Bool = false) async throws -> [Aisle] {
        return try await dataService.getAislesPaginated(limit: limit, refresh: refresh)
    }
    
    func saveAisle(_ aisle: Aisle) async throws -> Aisle {
        return try await dataService.saveAisle(aisle)
    }
    
    func deleteAisle(id: String) async throws {
        try await dataService.deleteAisle(id: id)
    }
}