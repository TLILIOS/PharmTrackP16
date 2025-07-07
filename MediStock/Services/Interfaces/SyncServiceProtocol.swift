import Foundation
import Combine

protocol SyncServiceProtocol {
    /// État actuel de la synchronisation
    var syncState: AnyPublisher<SyncState, Never> { get }
    
    /// Vérifie si l'application est actuellement en ligne
    var isOnline: Bool { get }
    
    /// Synchronise les modifications locales avec le serveur
    /// - Returns: Un booléen indiquant si la synchronisation a réussi
    func syncPendingChanges() async -> Bool
    
    /// Force une synchronisation complète avec le serveur
    /// - Returns: Un booléen indiquant si la synchronisation a réussi
    func forceSyncAll() async -> Bool
    
    /// Enregistre une opération à synchroniser quand la connexion sera disponible
    /// - Parameters:
    ///   - operation: L'opération à synchroniser
    ///   - identifier: Un identifiant unique pour cette opération
    func enqueueSyncOperation(_ operation: SyncOperation, identifier: String) throws
    
    /// Vérifie l'état de la connexion internet
    func checkConnectivity()
}

/// État de synchronisation
enum SyncState: Equatable {
    case idle
    case syncing
    case success(Date)
    case error(String)
    case offline
}

/// Type d'opération à synchroniser
enum SyncOperationType: String, Codable {
    case createMedicine
    case updateMedicine
    case deleteMedicine
    case updateStock
    case createAisle
    case updateAisle
    case deleteAisle
    case addHistoryEntry
}

/// Structure représentant une opération à synchroniser
struct SyncOperation: Codable {
    let id: String
    let type: SyncOperationType
    let timestamp: Date
    let data: Data
    let entityId: String
}
