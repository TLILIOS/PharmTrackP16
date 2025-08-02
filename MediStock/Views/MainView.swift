import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var dashboardPath = NavigationPath()
    @State private var medicinesPath = NavigationPath()
    @State private var aislesPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $dashboardPath) {
                DashboardView()
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
                        case .detail(_):
                            HistoryDetailView()
                                .environmentObject(appState)
                        case .medicineHistory(_):
                            ModernHistoryView()
                                .environmentObject(appState)
                        }
                    }
            }
            .tabItem {
                Label("Historique", systemImage: "clock.arrow.circlepath")
            }
            .tag(3)
            
            NavigationStack(path: $profilePath) {
                ProfileView()
                    .navigationDestination(for: ProfileDestination.self) { destination in
                        switch destination {
                        case .settings:
                            ProfileView()
                                .environmentObject(appState)
                        case .appearance:
                            ProfileView()
                                .environmentObject(appState)
                        case .notifications:
                            ProfileView()
                                .environmentObject(appState)
                        case .about:
                            ProfileView()
                                .environmentObject(appState)
                        case .help:
                            ProfileView()
                                .environmentObject(appState)
                        }
                    }
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle.fill")
            }
            .tag(4)
        }
        .onChange(of: selectedTab) {
            // Réinitialiser les paths de navigation lors du changement de tab
            dashboardPath = NavigationPath()
            medicinesPath = NavigationPath()
            aislesPath = NavigationPath()
            historyPath = NavigationPath()
            profilePath = NavigationPath()
        }
        .task {
            // Charger les données si l'utilisateur est connecté
            if appState.currentUser != nil {
                await appState.loadData()
            }
        }
    }
}