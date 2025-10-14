import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var dashboardPath = NavigationPath()
    @State private var medicinesPath = NavigationPath()
    @State private var aislesPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var profilePath = NavigationPath()

    var body: some View {
        TabView(selection: $appState.selectedTab) {
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
                ProfileView()
                    .navigationDestination(for: ProfileDestination.self) { destination in
                        switch destination {
                        case .settings:
                            SettingsView()
                                .environmentObject(appState)
                        case .appearance:
                            AppearanceView()
                                .environmentObject(appState)
                        case .notifications:
                            NotificationsSettingsView()
                                .environmentObject(appState)
                        case .about:
                            AboutView()
                                .environmentObject(appState)
                        case .help:
                            HelpView()
                                .environmentObject(appState)
                        }
                    }
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
            // Les données seront chargées par les ViewModels individuels
        }
    }
}