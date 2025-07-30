import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $navigationPath) {
                DashboardView()
            }
            .tabItem {
                Label("Tableau de bord", systemImage: "chart.pie.fill")
            }
            .tag(0)
            
            NavigationStack(path: $navigationPath) {
                MedicineListView()
            }
            .tabItem {
                Label("Médicaments", systemImage: "pills.fill")
            }
            .tag(1)
            
            NavigationStack {
                AisleListView()
            }
            .tabItem {
                Label("Rayons", systemImage: "square.grid.2x2.fill")
            }
            .tag(2)
            
            NavigationStack {
                HistoryView()
            }
            .tabItem {
                Label("Historique", systemImage: "clock.arrow.circlepath")
            }
            .tag(3)
            
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle.fill")
            }
            .tag(4)
        }
        .task {
            // Charger les données si l'utilisateur est connecté
            if appState.currentUser != nil {
                await appState.loadData()
            }
        }
    }
}