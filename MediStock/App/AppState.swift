import SwiftUI
import Combine

// MARK: - AppState Refactorisé (Coordinateur Global MVVM)
// Responsabilités : Authentification + Navigation + Services partagés
// NE gère PAS les données métier (déléguées aux ViewModels)

@MainActor
class AppState: ObservableObject {

    // MARK: - État Global Minimal

    /// Utilisateur actuellement connecté
    @Published var currentUser: User?

    /// Tab sélectionné dans la TabView
    @Published var selectedTab = 0

    /// Message d'erreur global (auth, network)
    @Published var errorMessage: String?

    /// État de chargement global (utilisé pendant auth)
    @Published var isLoading = false

    // MARK: - Services Partagés (Dependency Injection)

    let authService: AuthService
    let medicineRepository: MedicineRepositoryProtocol
    let aisleRepository: AisleRepositoryProtocol
    let historyRepository: HistoryRepositoryProtocol
    let notificationService: NotificationService

    // MARK: - Initialisation

    init(
        authService: AuthService? = nil,
        medicineRepository: MedicineRepositoryProtocol? = nil,
        aisleRepository: AisleRepositoryProtocol? = nil,
        historyRepository: HistoryRepositoryProtocol? = nil,
        notificationService: NotificationService? = nil
    ) {
        self.authService = authService ?? AuthService()
        self.medicineRepository = medicineRepository ?? MedicineRepository()
        self.aisleRepository = aisleRepository ?? AisleRepository()
        self.historyRepository = historyRepository ?? HistoryRepository()
        self.notificationService = notificationService ?? NotificationService()

        // Observer l'état d'authentification
        self.authService.$currentUser
            .assign(to: &$currentUser)
    }

    // MARK: - Actions d'Authentification (Global)

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signIn(email: email, password: password)
            // ✅ Pas besoin de charger les données ici
            // Les ViewModels se chargeront individuellement
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.signUp(email: email, password: password, displayName: name)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func signOut() async {
        do {
            try await authService.signOut()
            // ✅ Les ViewModels se nettoieront eux-mêmes
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Computed Properties (État Global)

    var isAuthenticated: Bool {
        currentUser != nil
    }
}

// MARK: - Extension pour faciliter les tests

extension AppState {
    static func mock(
        user: User? = nil,
        medicineRepository: MedicineRepositoryProtocol? = nil
    ) -> AppState {
        let state = AppState(
            authService: nil,
            medicineRepository: medicineRepository,
            aisleRepository: nil,
            historyRepository: nil,
            notificationService: nil
        )
        state.currentUser = user
        return state
    }
}
