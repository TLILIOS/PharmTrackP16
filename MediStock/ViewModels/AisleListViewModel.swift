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

    // MARK: - Private State (Protection anti-redondance)

    /// Indicateur si le listener temps réel est actif
    private var isListenerActive = false

    /// Timestamp du dernier chargement pour debouncing
    private var lastLoadTimestamp: Date?

    /// Tâche de chargement en cours (pour annulation)
    private var loadTask: Task<Void, Never>?

    /// Intervalle minimum entre deux chargements (en secondes)
    private let minimumLoadInterval: TimeInterval = 2.0

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

    /// Démarrer l'écoute en temps réel des rayons
    func startListening() {
        print("🎧 [AisleListViewModel] Démarrage du listener temps réel...")
        isListenerActive = true

        repository.startListeningToAisles { [weak self] aisles in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                print("🔄 [AisleListViewModel] Listener reçu \(aisles.count) rayon(s)")
                self.aisles = aisles
                self.isLoading = false

                // Mettre à jour le timestamp pour éviter les chargements redondants
                self.lastLoadTimestamp = Date()
            }
        }
    }

    /// Arrêter l'écoute en temps réel
    func stopListening() {
        repository.stopListening()
        isListenerActive = false
        print("🛑 [AisleListViewModel] Listener temps réel arrêté")
    }

    /// Charger les rayons (première page) - Méthode de fallback
    /// - Parameter forceRefresh: Force le rechargement même si le listener est actif
    func loadAisles(forceRefresh: Bool = false) async {
        print("🔄 [AisleListViewModel] loadAisles() appelé (forceRefresh: \(forceRefresh))")

        // 1. Protection : Si le listener est actif et ce n'est pas un refresh forcé, ignorer
        if isListenerActive && !forceRefresh {
            print("⚠️ [AisleListViewModel] Listener actif, chargement ignoré")
            return
        }

        // 2. Protection : Vérifier si un chargement est déjà en cours
        guard !isLoading else {
            print("⚠️ [AisleListViewModel] Chargement déjà en cours, annulation")
            return
        }

        // 3. Protection : Debouncing - vérifier le délai minimum depuis le dernier chargement
        if let lastLoad = lastLoadTimestamp,
           Date().timeIntervalSince(lastLoad) < minimumLoadInterval && !forceRefresh {
            print("⚠️ [AisleListViewModel] Debouncing - Dernier chargement il y a \(Date().timeIntervalSince(lastLoad))s, minimum: \(minimumLoadInterval)s")
            return
        }

        // 4. Annuler la tâche précédente si elle existe
        loadTask?.cancel()

        // 5. Créer et stocker la nouvelle tâche
        loadTask = Task { @MainActor [weak self]  in
            guard let self else {return}
            isLoading = true
            errorMessage = nil

            do {
                // Vérifier si la tâche a été annulée
                try Task.checkCancellation()

                print("📡 [AisleListViewModel] Requête Firestore en cours...")
                aisles = try await repository.fetchAislesPaginated(
                    limit: AppConstants.Pagination.defaultLimit,
                    refresh: true
                )

                // Vérifier à nouveau si la tâche a été annulée
                try Task.checkCancellation()

                print("✅ [AisleListViewModel] \(aisles.count) rayon(s) récupéré(s)")
                print("📝 [AisleListViewModel] Liste des rayons: \(aisles.map { $0.name })")
                hasMoreAisles = aisles.count >= AppConstants.Pagination.defaultLimit

                // Mettre à jour le timestamp
                lastLoadTimestamp = Date()

            } catch is CancellationError {
                print("⚠️ [AisleListViewModel] Chargement annulé")
            } catch {
                print("❌ [AisleListViewModel] Erreur lors du chargement: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                FirebaseService.shared.logError(error, userInfo: [
                    "action": "loadAisles",
                    "viewModel": "AisleListViewModel"
                ])
            }

            isLoading = false
            print("🏁 [AisleListViewModel] loadAisles() terminé, isLoading=\(isLoading)")
        }

        // Attendre la fin de la tâche
        await loadTask?.value
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
        print("💾 [AisleListViewModel] saveAisle() appelé pour '\(aisle.name)'")
        do {
            let saved = try await repository.saveAisle(aisle)

            // Recharger la liste seulement si le listener n'est pas actif
            // Si le listener est actif, il mettra à jour automatiquement
            if !isListenerActive {
                print("🔄 [AisleListViewModel] Rechargement de la liste après sauvegarde (listener inactif)...")
                await loadAisles()
            } else {
                print("✅ [AisleListViewModel] Listener actif, pas besoin de recharger manuellement")
            }

            // Analytics
            FirebaseService.shared.logEvent(AnalyticsEvent(
                name: (aisle.id?.isEmpty ?? true) ? "aisle_created" : "aisle_updated",
                parameters: [
                    "aisle_id": saved.id ?? "",
                    "aisle_name": saved.name
                ]
            ))

        } catch {
            print("❌ [AisleListViewModel] Erreur lors de la sauvegarde: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "saveAisle",
                "aisleId": aisle.id as Any
            ])
        }
    }

    /// Supprimer un rayon
    func deleteAisle(_ aisle: Aisle) async {
        guard let aisleId = aisle.id else {
            errorMessage = "Impossible de supprimer le rayon : ID manquant"
            return
        }

        do {
            try await repository.deleteAisle(id: aisleId)

            // Supprimer directement de la liste locale si le listener n'est pas actif
            // Si le listener est actif, il mettra à jour automatiquement
            if !isListenerActive {
                print("🔄 [AisleListViewModel] Mise à jour de la liste locale après suppression...")
                aisles.removeAll { $0.id == aisleId }
            } else {
                print("✅ [AisleListViewModel] Listener actif, pas besoin de mettre à jour manuellement")
            }

            // Analytics
            FirebaseService.shared.logEvent(AnalyticsEvent(
                name: "aisle_deleted",
                parameters: [
                    "aisle_id": aisleId
                ]
            ))

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "deleteAisle",
                "aisleId": aisleId
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
    #if DEBUG
    static func makeMock(
        aisles: [Aisle] = [],
        repository: AisleRepositoryProtocol? = nil
    ) -> AisleListViewModel {
        // Mini-mock inline pour previews
        class PreviewAisleRepository: AisleRepositoryProtocol {
            var aisles: [Aisle]
            init(_ aisles: [Aisle]) { self.aisles = aisles }
            func fetchAisles() async throws -> [Aisle] { aisles }
            func fetchAislesPaginated(limit: Int, refresh: Bool) async throws -> [Aisle] { aisles }
            func saveAisle(_ aisle: Aisle) async throws -> Aisle { aisle }
            func deleteAisle(id: String) async throws {}
            func startListeningToAisles(completion: @escaping ([Aisle]) -> Void) {}
            func stopListening() {}
        }

        let viewModel = AisleListViewModel(repository: repository ?? PreviewAisleRepository(aisles))
        viewModel.aisles = aisles
        return viewModel
    }
    #endif
}
