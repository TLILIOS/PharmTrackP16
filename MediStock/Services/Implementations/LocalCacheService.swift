import Foundation

class LocalCacheService: CacheServiceProtocol {
    private let fileManager = FileManager.default
    private let expirationTimeInterval: TimeInterval
    
    /// Initialise le service de cache local
    /// - Parameter expirationTimeInterval: Durée de validité du cache en secondes (par défaut 24 heures)
    init(expirationTimeInterval: TimeInterval = 24 * 60 * 60) {
        self.expirationTimeInterval = expirationTimeInterval
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - CacheServiceProtocol
    
    func save<T: Codable>(_ data: T, forKey key: String) throws {
        let cacheMetadata = CacheMetadata(creationDate: Date())
        let cacheItem = CacheItem(metadata: cacheMetadata, data: data)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(cacheItem)
        
        try data.write(to: fileURL(forKey: key))
    }
    
    func fetch<T: Codable>(forKey key: String) throws -> T? {
        let fileURL = self.fileURL(forKey: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let cacheItem = try decoder.decode(CacheItem<T>.self, from: data)
        
        // Vérifier si le cache est expiré
        if Date().timeIntervalSince(cacheItem.metadata.creationDate) > expirationTimeInterval {
            remove(forKey: key)
            return nil
        }
        
        return cacheItem.data
    }
    
    func remove(forKey key: String) {
        let fileURL = self.fileURL(forKey: key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func exists(forKey key: String) -> Bool {
        let fileURL = self.fileURL(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        // Vérifier si le fichier est expiré
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let creationDate = attributes[.creationDate] as? Date {
                return Date().timeIntervalSince(creationDate) <= expirationTimeInterval
            }
        } catch {
            return false
        }
        
        return false
    }
    
    func clearAll() {
        let cacheURL = cacheDirectory()
        try? fileManager.removeItem(at: cacheURL)
        createCacheDirectoryIfNeeded()
    }
    
    // MARK: - Private Methods
    
    private func cacheDirectory() -> URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDirectory = urls[0].appendingPathComponent("MediStockCache")
        return cacheDirectory
    }
    
    private func fileURL(forKey key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return cacheDirectory().appendingPathComponent(filename)
    }
    
    private func createCacheDirectoryIfNeeded() {
        let cacheURL = cacheDirectory()
        if !fileManager.fileExists(atPath: cacheURL.path) {
            try? fileManager.createDirectory(at: cacheURL, withIntermediateDirectories: true)
        }
    }
}

// MARK: - Structures de cache

private struct CacheMetadata: Codable {
    let creationDate: Date
}

private struct CacheItem<T: Codable>: Codable {
    let metadata: CacheMetadata
    let data: T
}
