import Foundation
import SwiftUI

// MARK: - Gestionnaire de Pagination Générique
// Élimine la duplication de la logique de pagination

@MainActor
class PaginationManager<T: Identifiable>: ObservableObject {
    @Published var items: [T] = []
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var errorMessage: String?
    
    // Configuration
    let pageSize: Int
    
    // État interne
    private var isFirstLoad = true
    
    init(pageSize: Int = 20) {
        self.pageSize = pageSize
    }
    
    /// Charge la première page (refresh)
    func loadFirstPage<S: PaginationService>(
        using service: S
    ) async where S.ItemType == T {
        isFirstLoad = true
        hasMore = true
        
        await loadPage(using: service, refresh: true)
    }
    
    /// Charge la page suivante
    func loadNextPage<S: PaginationService>(
        using service: S
    ) async where S.ItemType == T {
        guard !isLoadingMore && hasMore else { return }
        
        await loadPage(using: service, refresh: false)
    }
    
    /// Réinitialise la pagination
    func reset() {
        items.removeAll()
        isFirstLoad = true
        hasMore = true
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func loadPage<S: PaginationService>(
        using service: S,
        refresh: Bool
    ) async where S.ItemType == T {
        isLoadingMore = true
        errorMessage = nil
        defer { isLoadingMore = false }
        
        do {
            let newItems = try await service.fetchItems(
                limit: pageSize,
                refresh: refresh
            )
            
            if refresh {
                items = newItems
            } else {
                items.append(contentsOf: newItems)
            }
            
            hasMore = newItems.count == pageSize
            isFirstLoad = false
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Protocol pour les Services avec Pagination

protocol PaginationService {
    associatedtype ItemType: Identifiable
    
    func fetchItems(limit: Int, refresh: Bool) async throws -> [ItemType]
}

// MARK: - Extension pour ScrollView avec chargement automatique

struct PaginationLoader: View {
    let onAppear: () async -> Void
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: ViewOffsetKey.self,
                    value: geometry.frame(in: .global).minY
                )
        }
        .frame(height: 1)
        .onAppear {
            Task {
                await onAppear()
            }
        }
    }
}

private struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - ViewModifier pour faciliter l'intégration

struct PaginatedList<T: Identifiable>: ViewModifier {
    @ObservedObject var paginationManager: PaginationManager<T>
    let loadMore: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if paginationManager.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .overlay(alignment: .bottom) {
                if paginationManager.hasMore && !paginationManager.isLoadingMore {
                    PaginationLoader {
                        await loadMore()
                    }
                }
            }
    }
}

extension View {
    func paginated<T: Identifiable>(
        manager: PaginationManager<T>,
        loadMore: @escaping () async -> Void
    ) -> some View {
        modifier(PaginatedList(
            paginationManager: manager,
            loadMore: loadMore
        ))
    }
}

// MARK: - Exemple d'Utilisation

/*
 Migration d'un ViewModel avec pagination :
 
 AVANT:
 ```swift
 class AisleListViewModel: ObservableObject {
     @Published var aisles: [Aisle] = []
     @Published var isLoadingMore = false
     @Published var hasMoreItems = true
     
     func loadMoreAisles() async {
         guard !isLoadingMore && hasMoreItems else { return }
         
         isLoadingMore = true
         
         do {
             let newAisles = try await repository.fetchAislesPaginated(limit: 20, refresh: false)
             aisles.append(contentsOf: newAisles)
             hasMoreItems = newAisles.count >= 20
         } catch {
             errorMessage = error.localizedDescription
         }
         
         isLoadingMore = false
     }
 }
 ```
 
 APRÈS:
 ```swift
 class AisleListViewModel: ObservableObject {
     let paginationManager = PaginationManager<Aisle>()
     
     var aisles: [Aisle] {
         paginationManager.items
     }
     
     func loadMoreAisles() async {
         await paginationManager.loadNextPage(using: aisleService)
     }
 }
 ```
 
 Dans la View:
 ```swift
 List(viewModel.aisles) { aisle in
     AisleRow(aisle: aisle)
 }
 .paginated(manager: viewModel.paginationManager) {
     await viewModel.loadMoreAisles()
 }
 ```
 
 Réduction: ~15 lignes → 3 lignes dans le ViewModel
 */