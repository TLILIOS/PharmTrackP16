import Foundation
import Combine

protocol MedicineRepositoryProtocol {
    /// Récupère la liste de tous les médicaments
    /// - Returns: Liste des médicaments
    func getMedicines() async throws -> [Medicine]
    
    /// Récupère un médicament par son identifiant
    /// - Parameter id: Identifiant du médicament
    /// - Returns: Le médicament s'il existe, nil sinon
    func getMedicine(id: String) async throws -> Medicine?
    
    /// Crée ou met à jour un médicament
    /// - Parameter medicine: Le médicament à sauvegarder
    /// - Returns: Le médicament avec son identifiant attribué
    func saveMedicine(_ medicine: Medicine) async throws -> Medicine
    
    /// Met à jour le stock d'un médicament
    /// - Parameters:
    ///   - id: Identifiant du médicament
    ///   - newStock: Nouvelle valeur du stock
    /// - Returns: Le médicament mis à jour
    func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine
    
    /// Supprime un médicament
    /// - Parameter id: Identifiant du médicament à supprimer
    func deleteMedicine(id: String) async throws
    
    /// Observer les changements dans la collection de médicaments
    /// - Returns: Un publisher qui émet la liste mise à jour des médicaments
    func observeMedicines() -> AnyPublisher<[Medicine], Error>
    
    /// Observer les changements pour un médicament spécifique
    /// - Parameter id: Identifiant du médicament
    /// - Returns: Un publisher qui émet le médicament mis à jour
    func observeMedicine(id: String) -> AnyPublisher<Medicine?, Error>
}
