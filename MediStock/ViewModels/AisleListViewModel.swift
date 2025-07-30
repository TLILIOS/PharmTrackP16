import Foundation
import SwiftUI

// MARK: - Aisle List ViewModel

@MainActor
class AisleListViewModel: ObservableObject {
    @Published var aisles: [Aisle] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasMoreAisles = true
    
    private let repository: AisleRepositoryProtocol
    
    init(repository: AisleRepositoryProtocol = AisleRepository()) {
        self.repository = repository
    }
    
    func loadAisles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            aisles = try await repository.fetchAislesPaginated(limit: 20, refresh: true)
            hasMoreAisles = aisles.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func loadMoreAisles() async {
        guard !isLoadingMore && hasMoreAisles else { return }
        
        isLoadingMore = true
        
        do {
            let newAisles = try await repository.fetchAislesPaginated(limit: 20, refresh: false)
            aisles.append(contentsOf: newAisles)
            hasMoreAisles = newAisles.count >= 20
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoadingMore = false
    }
    
    func saveAisle(_ aisle: Aisle) async {
        do {
            let saved = try await repository.saveAisle(aisle)
            
            if let index = aisles.firstIndex(where: { $0.id == saved.id }) {
                aisles[index] = saved
            } else {
                aisles.append(saved)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func deleteAisle(_ aisle: Aisle) async {
        do {
            try await repository.deleteAisle(id: aisle.id)
            aisles.removeAll { $0.id == aisle.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}