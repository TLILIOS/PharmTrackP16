import Foundation
import Combine

protocol AisleRepositoryProtocol {
    /// Récupère la liste de tous les rayons
    /// - Returns: Liste des rayons
    func getAisles() async throws -> [Aisle]
    
    /// Récupère un rayon par son identifiant
    /// - Parameter id: Identifiant du rayon
    /// - Returns: Le rayon s'il existe, nil sinon
    func getAisle(id: String) async throws -> Aisle?
    
    /// Crée ou met à jour un rayon
    /// - Parameter aisle: Le rayon à sauvegarder
    /// - Returns: Le rayon avec son identifiant attribué
    func saveAisle(_ aisle: Aisle) async throws -> Aisle
    
    /// Supprime un rayon
    /// - Parameter id: Identifiant du rayon à supprimer
    func deleteAisle(id: String) async throws
    
    /// Compte le nombre de médicaments dans un rayon
    /// - Parameter aisleId: Identifiant du rayon
    /// - Returns: Nombre de médicaments
    func getMedicineCountByAisle(aisleId: String) async throws -> Int
    
    /// Observer les changements dans la collection de rayons
    /// - Returns: Un publisher qui émet la liste mise à jour des rayons
    func observeAisles() -> AnyPublisher<[Aisle], Error>
    
    /// Observer les changements pour un rayon spécifique
    /// - Parameter id: Identifiant du rayon
    /// - Returns: Un publisher qui émet le rayon mis à jour
    func observeAisle(id: String) -> AnyPublisher<Aisle?, Error>
}