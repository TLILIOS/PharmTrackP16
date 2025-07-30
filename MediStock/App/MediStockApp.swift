import SwiftUI
import Firebase

@main
struct MediStockApp: App {
    // État global de l'application
    @StateObject private var appState = AppState()
    
    // ViewModels (temporairement conservés pour compatibilité)
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var medicineListViewModel: MedicineListViewModel
    @StateObject private var aisleListViewModel: AisleListViewModel
    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var historyViewModel: HistoryViewModel
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        // Configuration Firebase avec Analytics et Crashlytics
        FirebaseService.shared.configure()
        
        // Initialisation des ViewModels via DependencyContainer
        let container = DependencyContainer.shared
        _authViewModel = StateObject(wrappedValue: container.makeAuthViewModel())
        _medicineListViewModel = StateObject(wrappedValue: container.makeMedicineListViewModel())
        _aisleListViewModel = StateObject(wrappedValue: container.makeAisleListViewModel())
        _dashboardViewModel = StateObject(wrappedValue: container.makeDashboardViewModel())
        _historyViewModel = StateObject(wrappedValue: container.makeHistoryViewModel())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authViewModel)
                .environmentObject(medicineListViewModel)
                .environmentObject(aisleListViewModel)
                .environmentObject(dashboardViewModel)
                .environmentObject(historyViewModel)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .task {
                    // Demander les permissions de notification au lancement
                    _ = await DependencyContainer.shared.notificationService.requestPermission()
                    
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