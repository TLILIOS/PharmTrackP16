import Foundation
import Combine

// MARK: - Repository Protocols

protocol MedicineRepositoryProtocol {
    func fetchMedicines() async throws -> [Medicine]
    func fetchMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine]
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine
    func deleteMedicine(id: String) async throws
    func updateMultipleMedicines(_ medicines: [Medicine]) async throws
    func deleteMultipleMedicines(ids: [String]) async throws
}

protocol AisleRepositoryProtocol {
    func fetchAisles() async throws -> [Aisle]
    func fetchAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle]
    func saveAisle(_ aisle: Aisle) async throws -> Aisle
    func deleteAisle(id: String) async throws
}

protocol HistoryRepositoryProtocol {
    func fetchHistory() async throws -> [HistoryEntry]
    func addHistoryEntry(_ entry: HistoryEntry) async throws
    func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry]
}

@MainActor
protocol AuthRepositoryProtocol {
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, displayName: String) async throws
    func signOut() async throws
    func getCurrentUser() -> User?
    var currentUserPublisher: Published<User?>.Publisher { get }
}
