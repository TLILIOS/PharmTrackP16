import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class MedicineListViewModel: ObservableObject {

    // MARK: - Published State (UI)

    /// Liste complète des médicaments chargés
    @Published private(set) var medicines: [Medicine] = []

    /// État de chargement initial
    @Published private(set) var isLoading = false

    /// État de chargement pagination
    @Published private(set) var isLoadingMore = false

    /// Message d'erreur spécifique à cette vue
    @Published var errorMessage: String?

    /// Texte de recherche (binding depuis la vue)
    @Published var searchText = ""

    /// Filtre par rayon sélectionné (chaîne vide = tous les rayons)
    @Published var selectedAisleId: String = ""

    /// Indicateur pagination
    @Published private(set) var hasMoreMedicines = true

    // MARK: - Dependencies (Injected)

    private let medicineRepository: MedicineRepositoryProtocol
    private let historyRepository: HistoryRepositoryProtocol
    private let notificationService: NotificationService

    // MARK: - Init with Dependency Injection

    init(
        medicineRepository: MedicineRepositoryProtocol,
        historyRepository: HistoryRepositoryProtocol,
        notificationService: NotificationService
    ) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
        self.notificationService = notificationService
    }

    // MARK: - Computed Properties (Presentation Logic)

    /// Médicaments filtrés selon recherche et rayon
    var filteredMedicines: [Medicine] {
        var result = medicines

        // Filtre par recherche
        if !searchText.isEmpty {
            result = result.filter { medicine in
                medicine.name.localizedCaseInsensitiveContains(searchText) ||
                (medicine.reference?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filtre par rayon (si non vide)
        if !selectedAisleId.isEmpty {
            result = result.filter { $0.aisleId == selectedAisleId }
        }

        let sorted = result.sorted { $0.name < $1.name }

        // DEBUG: Logs pour identifier le problème
        print("🔍 [MedicineListViewModel] filteredMedicines:")
        print("  - Total medicines: \(medicines.count)")
        print("  - Filtered count: \(sorted.count)")
        print("  - Search text: '\(searchText)'")
        print("  - Selected aisle: '\(selectedAisleId)'")
        print("  - Filtered IDs: \(sorted.compactMap { $0.id }.joined(separator: ", "))")

        // Vérifier les IDs nil
        let nilIdCount = sorted.filter { $0.id == nil }.count
        if nilIdCount > 0 {
            print("  ⚠️ WARNING: \(nilIdCount) medicine(s) with nil ID")
        }

        // Vérifier les IDs dupliqués
        let ids = sorted.compactMap { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            print("  ⚠️ WARNING: Duplicate IDs detected! \(ids.count) items but only \(uniqueIds.count) unique IDs")
        }

        return sorted
    }

    /// Médicaments avec stock critique
    var criticalMedicines: [Medicine] {
        medicines.filter { $0.stockStatus == .critical }
    }

    /// Médicaments expirant bientôt
    var expiringMedicines: [Medicine] {
        medicines.filter { $0.isExpiringSoon && !$0.isExpired }
    }

    /// Nombre de résultats filtrés
    var filteredCount: Int {
        filteredMedicines.count
    }

    /// Indicateur si la liste est vide
    var isEmpty: Bool {
        medicines.isEmpty
    }

    // MARK: - Actions (Business Logic)

    /// Démarrer l'écoute en temps réel des médicaments
    func startListening() {
        print("🎧 [MedicineListViewModel] Démarrage du listener temps réel...")

        medicineRepository.startListeningToMedicines { [weak self] medicines in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                print("🔄 [MedicineListViewModel] Listener reçu \(medicines.count) médicament(s)")
                self.medicines = medicines
                self.isLoading = false

                // Vérifier les expirations pour notifications
                await self.notificationService.checkExpirations(medicines: medicines)
            }
        }
    }

    /// Arrêter l'écoute en temps réel
    func stopListening() {
        medicineRepository.stopListening()
        print("🛑 [MedicineListViewModel] Listener temps réel arrêté")
    }

    /// Charger les médicaments (première page) - Méthode de fallback
    func loadMedicines() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            medicines = try await medicineRepository.fetchMedicinesPaginated(
                limit: AppConstants.Pagination.defaultLimit,
                refresh: true
            )
            hasMoreMedicines = medicines.count >= AppConstants.Pagination.defaultLimit

            // Vérifier les expirations pour notifications
            await notificationService.checkExpirations(medicines: medicines)

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "loadMedicines",
                "viewModel": "MedicineListViewModel"
            ])
        }

        isLoading = false
    }

    /// Charger plus de médicaments (pagination)
    func loadMoreMedicines() async {
        guard !isLoadingMore && hasMoreMedicines else { return }

        isLoadingMore = true

        do {
            let newMedicines = try await medicineRepository.fetchMedicinesPaginated(
                limit: AppConstants.Pagination.defaultLimit,
                refresh: false
            )
            medicines.append(contentsOf: newMedicines)
            hasMoreMedicines = newMedicines.count >= AppConstants.Pagination.defaultLimit

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "loadMoreMedicines"
            ])
        }

        isLoadingMore = false
    }

    /// Sauvegarder un médicament (création ou modification)
    func saveMedicine(_ medicine: Medicine) async {
        do {
            let saved = try await medicineRepository.saveMedicine(medicine)

            // Mettre à jour la liste locale
            if let index = medicines.firstIndex(where: { $0.id == saved.id }) {
                medicines[index] = saved
            } else {
                medicines.insert(saved, at: 0) // Ajouter en tête
            }

            // NOTE: L'historique est déjà enregistré par FirebaseDataService.saveMedicine()
            // Pas besoin de créer une entrée dupliquée ici

            // Analytics
            let isNewMedicine = medicine.id?.isEmpty ?? true
            if isNewMedicine {
                FirebaseService.shared.logMedicineAdded(medicine: saved)
            } else {
                FirebaseService.shared.logMedicineUpdated(medicine: saved)
            }

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "saveMedicine",
                "medicineId": medicine.id ?? ""
            ])
        }
    }

    /// Supprimer un médicament
    func deleteMedicine(_ medicine: Medicine) async {
        do {
            try await medicineRepository.deleteMedicine(id: medicine.id ?? "")

            // Retirer de la liste locale
            medicines.removeAll { $0.id == medicine.id }

            // NOTE: L'historique est déjà enregistré par FirebaseDataService.deleteMedicine()
            // Pas besoin de créer une entrée dupliquée ici

            // Analytics
            FirebaseService.shared.logMedicineDeleted(medicineId: medicine.id ?? "")

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "deleteMedicine",
                "medicineId": medicine.id ?? ""
            ])
        }
    }

    /// Ajuster le stock d'un médicament
    func adjustStock(medicine: Medicine, adjustment: Int, reason: String) async {
        let newQuantity = max(0, medicine.currentQuantity + adjustment)

        do {
            let updated = try await medicineRepository.updateMedicineStock(
                id: medicine.id ?? "",
                newStock: newQuantity
            )

            // Mettre à jour localement
            if let index = medicines.firstIndex(where: { $0.id == updated.id }) {
                medicines[index] = updated
            }

            // NOTE: L'historique est déjà enregistré par FirebaseDataService.updateMedicineStock()
            // Pas besoin de créer une entrée dupliquée ici

            // Analytics
            FirebaseService.shared.logStockAdjusted(
                medicine: updated,
                adjustment: adjustment,
                reason: reason
            )

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "adjustStock",
                "medicineId": medicine.id ?? "",
                "adjustment": adjustment
            ])
        }
    }

    /// Réinitialiser les filtres
    func resetFilters() {
        searchText = ""
        selectedAisleId = ""
    }

    /// Effacer l'erreur
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Factory pour Dependency Injection

extension MedicineListViewModel {
    /// Créer une instance avec dépendances par défaut
    static func makeDefault() -> MedicineListViewModel {
        let container = DependencyContainer.shared
        return MedicineListViewModel(
            medicineRepository: container.medicineRepository,
            historyRepository: container.historyRepository,
            notificationService: container.notificationService
        )
    }

    /// Créer une instance pour les tests avec mocks
    static func makeMock(
        medicines: [Medicine] = [],
        repository: MedicineRepositoryProtocol? = nil
    ) -> MedicineListViewModel {
        let mockRepo = repository ?? MockMedicineRepository()
        let mockHistory = MockHistoryRepository()
        let mockNotif = NotificationService()

        let viewModel = MedicineListViewModel(
            medicineRepository: mockRepo,
            historyRepository: mockHistory,
            notificationService: mockNotif
        )

        viewModel.medicines = medicines
        return viewModel
    }
}
