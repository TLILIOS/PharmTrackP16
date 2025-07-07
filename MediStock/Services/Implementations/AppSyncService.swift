import Foundation
import Combine
import Network

class AppSyncService: SyncServiceProtocol {
    // MARK: - Properties
    
    private let cacheService: CacheServiceProtocol
    private let syncQueueKey = "pending_sync_operations"
    private let networkMonitor = NWPathMonitor()
    private var cancellables = Set<AnyCancellable>()
    private let syncSubject = CurrentValueSubject<SyncState, Never>(.idle)
    
    private(set) var isOnline: Bool = false {
        didSet {
            if isOnline && oldValue == false {
                // Connexion retrouvée, essayer de synchroniser
                Task {
                    await syncPendingChanges()
                }
            }
        }
    }
    
    var syncState: AnyPublisher<SyncState, Never> {
        return syncSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    
    init(cacheService: CacheServiceProtocol) {
        self.cacheService = cacheService
        setupNetworkMonitoring()
    }
    
    // MARK: - SyncServiceProtocol
    
    func syncPendingChanges() async -> Bool {
        guard isOnline else {
            syncSubject.send(.offline)
            return false
        }
        
        syncSubject.send(.syncing)
        
        do {
            let operations: [SyncOperation] = (try cacheService.fetch(forKey: syncQueueKey)) ?? []
            
            if operations.isEmpty {
                syncSubject.send(.success(Date()))
                return true
            }
            
            var success = true
            
            for operation in operations {
                if !(await processOperation(operation)) {
                    success = false
                    break
                }
            }
            
            if success {
                // Toutes les opérations ont été traitées avec succès, effacer la file d'attente
                try cacheService.save([SyncOperation](), forKey: syncQueueKey)
                syncSubject.send(.success(Date()))
                return true
            } else {
                syncSubject.send(.error("Échec de synchronisation de certaines opérations"))
                return false
            }
        } catch {
            syncSubject.send(.error(error.localizedDescription))
            return false
        }
    }
    
    func forceSyncAll() async -> Bool {
        guard isOnline else {
            syncSubject.send(.offline)
            return false
        }
        
        syncSubject.send(.syncing)
        
        // Implémentation de la synchronisation complète
        // Cette fonction forcerait une récupération de toutes les données depuis le serveur
        // et les sauvegarderait dans le cache local
        
        // Pour cette implémentation simplifiée, nous retournons simplement true
        syncSubject.send(.success(Date()))
        return true
    }
    
    func enqueueSyncOperation(_ operation: SyncOperation, identifier: String) throws {
        var operations: [SyncOperation] = (try? cacheService.fetch(forKey: syncQueueKey)) ?? []
        
        // Vérifier si une opération avec le même identifiant existe déjà
        if let index = operations.firstIndex(where: { $0.id == identifier }) {
            operations[index] = operation
        } else {
            operations.append(operation)
        }
        
        try cacheService.save(operations, forKey: syncQueueKey)
        
        // Si nous sommes en ligne, essayer de synchroniser immédiatement
        if isOnline {
            Task {
                await syncPendingChanges()
            }
        }
    }
    
    func checkConnectivity() {
        // La connectivité est déjà surveillée en continu par networkMonitor
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            let isConnected = path.status == .satisfied
            
            // Exécuter sur le thread principal car cela peut affecter l'UI
            DispatchQueue.main.async {
                self.isOnline = isConnected
                
                if !isConnected {
                    self.syncSubject.send(.offline)
                }
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func processOperation(_ operation: SyncOperation) async -> Bool {
        // Cette fonction traiterait une opération en attente en fonction de son type
        // Pour l'instant, c'est une implémentation simplifiée
        
        // Simuler un délai de traitement
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Retourner true pour indiquer que l'opération a été traitée avec succès
        return true
    }
    
    deinit {
        networkMonitor.cancel()
    }
}
