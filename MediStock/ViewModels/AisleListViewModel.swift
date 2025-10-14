import Foundation
import SwiftUI

// MARK: - AisleListViewModel (MVVM Strict)
// Responsabilité : Gestion de la liste des rayons

@MainActor
class AisleListViewModel: ObservableObject {

    // MARK: - Published State

    /// Liste complète des rayons
    @Published private(set) var aisles: [Aisle] = []

    /// État de chargement
    @Published private(set) var isLoading = false

    /// État de chargement pagination
    @Published private(set) var isLoadingMore = false

    /// Message d'erreur
    @Published var errorMessage: String?

    /// Texte de recherche
    @Published var searchText = ""

    /// Indicateur pagination
    @Published private(set) var hasMoreAisles = true

    // MARK: - Dependencies

    private let repository: AisleRepositoryProtocol

    // MARK: - Init

    init(repository: AisleRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Computed Properties

    /// Rayons filtrés par recherche
    var filteredAisles: [Aisle] {
        guard !searchText.isEmpty else { return aisles.sorted { $0.name < $1.name } }

        return aisles.filter { aisle in
            aisle.name.localizedCaseInsensitiveContains(searchText) ||
            (aisle.description?.localizedCaseInsensitiveContains(searchText) ?? false)
        }.sorted { $0.name < $1.name }
    }

    /// Nombre de rayons filtrés
    var filteredCount: Int {
        filteredAisles.count
    }

    /// Indicateur si la liste est vide
    var isEmpty: Bool {
        aisles.isEmpty
    }

    // MARK: - Actions

    /// Charger les rayons (première page)
    func loadAisles() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            aisles = try await repository.fetchAislesPaginated(
                limit: AppConstants.Pagination.defaultLimit,
                refresh: true
            )
            hasMoreAisles = aisles.count >= AppConstants.Pagination.defaultLimit

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "loadAisles",
                "viewModel": "AisleListViewModel"
            ])
        }

        isLoading = false
    }

    /// Charger plus de rayons (pagination)
    func loadMoreAisles() async {
        guard !isLoadingMore && hasMoreAisles else { return }

        isLoadingMore = true

        do {
            let newAisles = try await repository.fetchAislesPaginated(
                limit: AppConstants.Pagination.defaultLimit,
                refresh: false
            )
            aisles.append(contentsOf: newAisles)
            hasMoreAisles = newAisles.count >= AppConstants.Pagination.defaultLimit

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "loadMoreAisles"
            ])
        }

        isLoadingMore = false
    }

    /// Sauvegarder un rayon (création ou modification)
    func saveAisle(_ aisle: Aisle) async {
        do {
            let saved = try await repository.saveAisle(aisle)

            // Mettre à jour la liste locale
            if let index = aisles.firstIndex(where: { $0.id == saved.id }) {
                aisles[index] = saved
            } else {
                aisles.insert(saved, at: 0) // Ajouter en tête
            }

            // Analytics
            FirebaseService.shared.logEvent(AnalyticsEvent(
                name: aisle.id.isEmpty ? "aisle_created" : "aisle_updated",
                parameters: [
                    "aisle_id": saved.id,
                    "aisle_name": saved.name
                ]
            ))

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "saveAisle",
                "aisleId": aisle.id
            ])
        }
    }

    /// Supprimer un rayon
    func deleteAisle(_ aisle: Aisle) async {
        do {
            try await repository.deleteAisle(id: aisle.id)

            // Retirer de la liste locale
            aisles.removeAll { $0.id == aisle.id }

            // Analytics
            FirebaseService.shared.logEvent(AnalyticsEvent(
                name: "aisle_deleted",
                parameters: [
                    "aisle_id": aisle.id
                ]
            ))

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "deleteAisle",
                "aisleId": aisle.id
            ])
        }
    }

    /// Effacer l'erreur
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Factory

extension AisleListViewModel {
    /// Créer une instance avec dépendances par défaut
    static func makeDefault() -> AisleListViewModel {
        let container = DependencyContainer.shared
        return AisleListViewModel(repository: container.aisleRepository)
    }

    /// Créer une instance pour les tests avec mocks
    static func makeMock(
        aisles: [Aisle] = [],
        repository: AisleRepositoryProtocol? = nil
    ) -> AisleListViewModel {
        let mockRepo = repository ?? MockAisleRepository()
        let viewModel = AisleListViewModel(repository: mockRepo)
        viewModel.aisles = aisles
        return viewModel
    }
}
