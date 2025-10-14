import SwiftUI
import Firebase

// MARK: - MediStockApp Refactorisé (MVVM Strict)
// Architecture : AppState (Coordinateur) + ViewModels Spécialisés

@main
struct MediStockApp: App {

    // MARK: - État Global (AppState = Coordinateur)

    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()

    // MARK: - ViewModels Spécialisés (Créés via DependencyContainer)

    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var medicineListViewModel: MedicineListViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var aisleListViewModel: AisleListViewModel
    @StateObject private var historyViewModel: HistoryViewModel

    // MARK: - Init

    init() {
        // Configuration Firebase (une seule fois)
        FirebaseService.shared.configure()

        // Initialiser les ViewModels avec DependencyContainer
        let container = DependencyContainer.shared

        _authViewModel = StateObject(wrappedValue: container.makeAuthViewModel())
        _medicineListViewModel = StateObject(wrappedValue: MedicineListViewModel.makeDefault())
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel.makeDefault())
        _aisleListViewModel = StateObject(wrappedValue: container.makeAisleListViewModel())
        _historyViewModel = StateObject(wrappedValue: container.makeHistoryViewModel())
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ✅ AppState = État global (auth, navigation)
                .environmentObject(appState)

                // ✅ ViewModels spécialisés
                .environmentObject(authViewModel)
                .environmentObject(medicineListViewModel)
                .environmentObject(dashboardViewModel)
                .environmentObject(aisleListViewModel)
                .environmentObject(historyViewModel)

                // ✅ Theme
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)

                .task {
                    // Demander permissions notifications au lancement
                    _ = await appState.notificationService.requestPermission()

                    // Logger le lancement de l'app
                    FirebaseService.shared.logEvent(AnalyticsEvent(
                        name: "app_launch",
                        parameters: [
                            "theme": themeManager.theme.rawValue,
                            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
                        ]
                    ))
                }
        }
    }
}

// MARK: - ContentView & MainView
// ✅ ContentView et MainView sont définis dans Views/ pour éviter la duplication
// ContentView : Views/ContentView.swift
// MainView : Views/MainView.swift

// MARK: - Notes d'Architecture

/*
 ✅ ARCHITECTURE MVVM STRICTE RESPECTÉE

 Séparation des Responsabilités :

 1. AppState (Coordinateur Global)
    - Authentification (currentUser)
    - Navigation globale (selectedTab)
    - Services partagés (repositories, notification service)
    - ❌ NE gère PAS les données métier

 2. ViewModels Spécialisés (Un par écran/fonctionnalité)
    - AuthViewModel : Authentification et gestion utilisateur
    - MedicineListViewModel : Liste des médicaments + filtres/recherche
    - DashboardViewModel : Statistiques et données du tableau de bord
    - AisleListViewModel : Gestion des rayons
    - HistoryViewModel : Historique des actions

    Chaque ViewModel :
    - Gère SES propres données (@Published)
    - Injecte les dépendances (repositories, services)
    - Contient la logique de présentation (computed properties)
    - Expose les actions métier (func)

 3. Views (UI Pure)
    - Utilisent @EnvironmentObject pour accéder aux ViewModels
    - Affichent les données (no business logic)
    - Déclenchent les actions du ViewModel
    - Binding pour les inputs utilisateur

 Avantages de cette Architecture :
 ✅ Responsabilité unique (SOLID)
 ✅ Testabilité parfaite (mocks faciles)
 ✅ Pas de duplication de code
 ✅ Performance optimale (ViewModels indépendants)
 ✅ Évolution facile (ajouter un ViewModel = indépendant)

 Communication entre ViewModels :
 - Via les repositories partagés (source de vérité = Firebase)
 - Ou via des Notifications (NotificationCenter)
 - Ou via AppState pour l'état vraiment global
 */
