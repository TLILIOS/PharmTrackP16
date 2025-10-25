import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var medicineListViewModel: MedicineListViewModel
    @EnvironmentObject var aisleListViewModel: AisleListViewModel
    @EnvironmentObject var historyViewModel: HistoryViewModel
    @State private var dashboardPath = NavigationPath()
    @State private var medicinesPath = NavigationPath()
    @State private var aislesPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack(path: $dashboardPath) {
                DashboardView(pdfExportService: DependencyContainer.shared.pdfExportService)
                    .navigationDestination(for: MedicineDestination.self) { destination in
                        switch destination {
                        case .add:
                            MedicineFormView(medicine: nil)
                                .environmentObject(appState)
                        case .detail(let medicine):
                            MedicineDetailView(medicine: medicine)
                                .environmentObject(appState)
                        case .edit(let medicine):
                            MedicineFormView(medicine: medicine)
                                .environmentObject(appState)
                        case .adjustStock(let medicine):
                            StockAdjustmentView(medicine: medicine)
                                .environmentObject(appState)
                        }
                    }
            }
            .tabItem {
                Label("Tableau de bord", systemImage: "chart.pie.fill")
            }
            .tag(0)
            
            NavigationStack(path: $medicinesPath) {
                MedicineListView()
                    .navigationDestination(for: MedicineDestination.self) { destination in
                        switch destination {
                        case .add:
                            MedicineFormView(medicine: nil)
                                .environmentObject(appState)
                        case .detail(let medicine):
                            MedicineDetailView(medicine: medicine)
                                .environmentObject(appState)
                        case .edit(let medicine):
                            MedicineFormView(medicine: medicine)
                                .environmentObject(appState)
                        case .adjustStock(let medicine):
                            StockAdjustmentView(medicine: medicine)
                                .environmentObject(appState)
                        }
                    }
            }
            .tabItem {
                Label("Médicaments", systemImage: "pills.fill")
            }
            .tag(1)
            
            NavigationStack(path: $aislesPath) {
                AisleListView()
            }
            .tabItem {
                Label("Rayons", systemImage: "square.grid.2x2.fill")
            }
            .tag(2)
            
            NavigationStack(path: $historyPath) {
                ModernHistoryView()
                    .navigationDestination(for: HistoryDestination.self) { destination in
                        switch destination {
                        case .detail:
                            HistoryDetailView()
                                .environmentObject(appState)
                        case .medicineHistory(let medicine):
                            MedicineHistoryView(medicine: medicine)
                                .environmentObject(appState)
                        }
                    }
            }
            .tabItem {
                Label("Historique", systemImage: "clock.arrow.circlepath")
            }
            .tag(3)
            
            NavigationStack(path: $profilePath) {
                ModernProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle.fill")
            }
            .tag(4)
        }
        .onChange(of: appState.selectedTab) {
            // Réinitialiser les paths de navigation lors du changement de tab
            dashboardPath = NavigationPath()
            medicinesPath = NavigationPath()
            aislesPath = NavigationPath()
            historyPath = NavigationPath()
            profilePath = NavigationPath()
        }
        .task {
            // Démarrer les listeners en temps réel pour une synchronisation automatique
            // au démarrage de MainView (après authentification)
            startAllListeners()
        }
        .onDisappear {
            // Arrêter les listeners quand MainView disparaît pour économiser les ressources
            stopAllListeners()
        }
    }

    // MARK: - Helper Methods

    /// Démarre tous les listeners en temps réel pour synchronisation automatique
    private func startAllListeners() {
        print("🎧 [MainView] Démarrage de tous les listeners temps réel...")
        medicineListViewModel.startListening()
        aisleListViewModel.startListening()

        // Charger l'historique une seule fois (pas besoin de listener temps réel)
        Task {
            await historyViewModel.loadHistory()
        }
    }

    /// Arrête tous les listeners en temps réel
    private func stopAllListeners() {
        print("🛑 [MainView] Arrêt de tous les listeners temps réel...")
        medicineListViewModel.stopListening()
        aisleListViewModel.stopListening()
    }
}