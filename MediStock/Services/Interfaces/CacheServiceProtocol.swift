import Foundation

protocol CacheServiceProtocol {
    /// Sauvegarde des données dans le cache
    /// - Parameters:
    ///   - data: Données à mettre en cache (doit être Codable)
    ///   - key: Clé unique pour identifier ces données
    func save<T: Codable>(_ data: T, forKey key: String) throws
    
    /// Récupère des données du cache
    /// - Parameter key: Clé unique pour identifier les données
    /// - Returns: Les données décodées ou nil si non trouvées ou expirées
    func fetch<T: Codable>(forKey key: String) throws -> T?
    
    /// Supprime des données spécifiques du cache
    /// - Parameter key: Clé unique des données à supprimer
    func remove(forKey key: String)
    
    /// Vérifie si des données existent dans le cache et sont valides
    /// - Parameter key: Clé unique à vérifier
    /// - Returns: true si les données existent et sont valides
    func exists(forKey key: String) -> Bool
    
    /// Supprime toutes les données du cache
    func clearAll()
}
