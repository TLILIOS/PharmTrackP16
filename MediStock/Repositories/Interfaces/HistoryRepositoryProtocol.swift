import Foundation
import Combine

protocol HistoryRepositoryProtocol {
    /// Ajoute une entrée d'historique
    /// - Parameter entry: L'entrée d'historique à ajouter
    /// - Returns: L'entrée d'historique avec son identifiant attribué
    func addHistoryEntry(_ entry: HistoryEntry) async throws -> HistoryEntry
    
    /// Récupère l'historique pour un médicament spécifique
    /// - Parameter medicineId: Identifiant du médicament
    /// - Returns: Liste des entrées d'historique pour ce médicament
    func getHistoryForMedicine(medicineId: String) async throws -> [HistoryEntry]
    
    /// Récupère tout l'historique
    /// - Returns: Liste complète des entrées d'historique
    func getAllHistory() async throws -> [HistoryEntry]
    
    /// Observe l'historique pour un médicament spécifique
    /// - Parameter medicineId: Identifiant du médicament
    /// - Returns: Un publisher qui émet la liste mise à jour des entrées d'historique
    func observeHistoryForMedicine(medicineId: String) -> AnyPublisher<[HistoryEntry], Error>
    
    /// Exporte l'historique dans un format spécifié
    /// - Parameters:
    ///   - format: Format d'export (par exemple "csv", "json")
    ///   - medicineId: Identifiant du médicament (optionnel, nil pour tout l'historique)
    /// - Returns: Les données exportées
    func exportHistory(format: String, medicineId: String?) async throws -> Data
}
