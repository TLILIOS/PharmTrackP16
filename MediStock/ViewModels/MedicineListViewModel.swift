import Foundation
import SwiftUI
import FirebaseFirestore
import Combine

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
    private let networkMonitor: NetworkMonitorProtocol

    // MARK: - Network State

    /// État de la connexion réseau
    @Published private(set) var networkStatus: NetworkStatus = .disconnected

    /// Indique si l'app est connectée au réseau
    var isConnected: Bool {
        networkStatus.isConnected
    }

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init with Dependency Injection

    init(
        medicineRepository: MedicineRepositoryProtocol,
        historyRepository: HistoryRepositoryProtocol,
        notificationService: NotificationService,
        networkMonitor: NetworkMonitorProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.historyRepository = historyRepository
        self.notificationService = notificationService
        self.networkMonitor = networkMonitor

        // Initialiser l'état réseau
        self.networkStatus = networkMonitor.status

        // Observer les changements d'état réseau
        setupNetworkObserver()
    }

    // MARK: - Network Observation

    private func setupNetworkObserver() {
        // Observer les changements du networkMonitor via objectWillChange
        networkMonitor.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.networkStatus = self.networkMonitor.status
                }
            }
            .store(in: &cancellables)
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

        return result.sorted { $0.name < $1.name }
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
        medicineRepository.startListeningToMedicines { [weak self] medicines in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

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

            // Mettre à jour la liste locale de manière thread-safe
            // Créer une nouvelle copie pour éviter les mutations concurrentes
            var updatedMedicines = medicines
            if let index = updatedMedicines.firstIndex(where: { $0.id == saved.id }) {
                updatedMedicines[index] = saved
            } else {
                updatedMedicines.insert(saved, at: 0) // Ajouter en tête
            }
            medicines = updatedMedicines

            // NOTE: L'historique est déjà enregistré par MedicineDataService.saveMedicine()
            // Pas besoin de créer une entrée dupliquée ici

            // Analytics
            let isNewMedicine = medicine.id?.isEmpty ?? true
            if isNewMedicine {
                FirebaseService.shared.logMedicineAdded(medicine: saved)
            } else {
                FirebaseService.shared.logMedicineUpdated(medicine: saved)
            }

        } catch {
            // Traduire l'erreur réseau en message utilisateur convivial
            if isNetworkError(error) {
                errorMessage = "Mode hors ligne : Cette opération nécessite une connexion Internet. Veuillez vous reconnecter pour effectuer cette action."
            } else {
                errorMessage = error.localizedDescription
            }

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

            // Retirer de la liste locale de manière thread-safe
            // Créer une nouvelle copie pour éviter les mutations concurrentes
            medicines = medicines.filter { $0.id != medicine.id }

            // NOTE: L'historique est déjà enregistré par MedicineDataService.deleteMedicine()
            // Pas besoin de créer une entrée dupliquée ici

            // Analytics
            FirebaseService.shared.logMedicineDeleted(medicineId: medicine.id ?? "")

        } catch {
            // Traduire l'erreur réseau en message utilisateur convivial
            if isNetworkError(error) {
                errorMessage = "Mode hors ligne : Cette opération nécessite une connexion Internet. Veuillez vous reconnecter pour effectuer cette action."
            } else {
                errorMessage = error.localizedDescription
            }

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

            // Mettre à jour localement de manière thread-safe
            // Créer une nouvelle copie pour éviter les mutations concurrentes
            var updatedMedicines = medicines
            if let index = updatedMedicines.firstIndex(where: { $0.id == updated.id }) {
                updatedMedicines[index] = updated
            }
            medicines = updatedMedicines

            // NOTE: L'historique est déjà enregistré par MedicineDataService.updateMedicineStock()
            // Pas besoin de créer une entrée dupliquée ici

            // Analytics
            FirebaseService.shared.logStockAdjusted(
                medicine: updated,
                adjustment: adjustment,
                reason: reason
            )

        } catch {
            // Traduire l'erreur réseau en message utilisateur convivial
            if isNetworkError(error) {
                errorMessage = "Mode hors ligne : Cette opération nécessite une connexion Internet. Veuillez vous reconnecter pour effectuer cette action."
            } else {
                errorMessage = error.localizedDescription
            }

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

    // MARK: - Error Handling Helpers

    /// Détecte si une erreur est liée au réseau
    private func isNetworkError(_ error: Error) -> Bool {
        let errorDescription = error.localizedDescription.lowercased()
        return errorDescription.contains("network") ||
               errorDescription.contains("internet") ||
               errorDescription.contains("offline") ||
               errorDescription.contains("resolving") ||
               errorDescription.contains("dns") ||
               errorDescription.contains("hostname lookup") ||
               errorDescription.contains("domain name not found") ||
               errorDescription.contains("connection") ||
               errorDescription.contains("firestore.googleapis.com")
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
            notificationService: container.notificationService,
            networkMonitor: container.networkMonitor
        )
    }

    /// Créer une instance pour les tests avec mocks
    #if DEBUG
    static func makeMock(
        medicines: [Medicine] = [],
        repository: MedicineRepositoryProtocol? = nil
    ) -> MedicineListViewModel {
        // Mini-mocks inline pour previews
        class PreviewNetworkMonitor: NetworkMonitorProtocol, ObservableObject {
            @Published var status: NetworkStatus = .connected(.wifi)
            @Published var isConnected: Bool = true

            func startMonitoring() {}
            func stopMonitoring() {}
        }

        class PreviewMedicineRepository: MedicineRepositoryProtocol {
            var medicines: [Medicine]
            init(_ medicines: [Medicine]) { self.medicines = medicines }
            func fetchMedicines() async throws -> [Medicine] { medicines }
            func fetchMedicinesPaginated(limit: Int, refresh: Bool) async throws -> [Medicine] { medicines }
            func saveMedicine(_ medicine: Medicine) async throws -> Medicine { medicine }
            func updateMedicineStock(id: String, newStock: Int) async throws -> Medicine { medicines.first! }
            func deleteMedicine(id: String) async throws {}
            func updateMultipleMedicines(_ medicines: [Medicine]) async throws {}
            func deleteMultipleMedicines(ids: [String]) async throws {}
            func startListeningToMedicines(completion: @escaping ([Medicine]) -> Void) {}
            func stopListening() {}
        }

        class PreviewHistoryRepository: HistoryRepositoryProtocol {
            func fetchHistory() async throws -> [HistoryEntry] { [] }
            func addHistoryEntry(_ entry: HistoryEntry) async throws {}
            func fetchHistoryForMedicine(_ medicineId: String) async throws -> [HistoryEntry] { [] }
        }

        let viewModel = MedicineListViewModel(
            medicineRepository: repository ?? PreviewMedicineRepository(medicines),
            historyRepository: PreviewHistoryRepository(),
            notificationService: NotificationService(),
            networkMonitor: PreviewNetworkMonitor()
        )

        viewModel.medicines = medicines
        return viewModel
    }
    #endif
}
