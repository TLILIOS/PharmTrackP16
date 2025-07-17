import SwiftUI

// MARK: - Coordinateurs légers par onglet

class DashboardCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: DashboardDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

class MedicineCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: MedicineDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

class AisleCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: AisleDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

class HistoryCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: HistoryDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

class ProfileCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    func navigateTo(_ destination: ProfileDestination) {
        path.append(destination)
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

// MARK: - Vue principale avec coordinateurs

struct TabCoordinatorView: View {
    @StateObject private var dashboardCoordinator = DashboardCoordinator()
    @StateObject private var medicineCoordinator = MedicineCoordinator()
    @StateObject private var aisleCoordinator = AisleCoordinator()
    @StateObject private var historyCoordinator = HistoryCoordinator()
    @StateObject private var profileCoordinator = ProfileCoordinator()
    
    var body: some View {
        TabView {
            // Dashboard Tab
            NavigationStack(path: $dashboardCoordinator.path) {
                DashboardRootView()
                    .environmentObject(dashboardCoordinator)
                    .navigationDestination(for: DashboardDestination.self) { destination in
                        destination.view
                            .environmentObject(dashboardCoordinator)
                    }
            }
            .tabItem {
                Label("Accueil", systemImage: "house")
            }
            
            // Medicine Tab
            NavigationStack(path: $medicineCoordinator.path) {
                MedicineRootView()
                    .environmentObject(medicineCoordinator)
                    .navigationDestination(for: MedicineDestination.self) { destination in
                        destination.view
                            .environmentObject(medicineCoordinator)
                    }
            }
            .tabItem {
                Label("Médicaments", systemImage: "pills")
            }
            
            // Aisle Tab
            NavigationStack(path: $aisleCoordinator.path) {
                AisleRootView()
                    .environmentObject(aisleCoordinator)
                    .navigationDestination(for: AisleDestination.self) { destination in
                        destination.view
                            .environmentObject(aisleCoordinator)
                    }
            }
            .tabItem {
                Label("Rayons", systemImage: "tray.2")
            }
            
            // History Tab
            NavigationStack(path: $historyCoordinator.path) {
                HistoryRootView()
                    .environmentObject(historyCoordinator)
                    .navigationDestination(for: HistoryDestination.self) { destination in
                        destination.view
                            .environmentObject(historyCoordinator)
                    }
            }
            .tabItem {
                Label("Historique", systemImage: "clock")
            }
            
            // Profile Tab
            NavigationStack(path: $profileCoordinator.path) {
                ProfileRootView()
                    .environmentObject(profileCoordinator)
                    .navigationDestination(for: ProfileDestination.self) { destination in
                        destination.view
                            .environmentObject(profileCoordinator)
                    }
            }
            .tabItem {
                Label("Profil", systemImage: "person")
            }
        }
    }
}

// MARK: - Vues racines pour chaque onglet

struct DashboardRootView: View {
    @EnvironmentObject var coordinator: DashboardCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Stocks Critiques") {
                coordinator.navigateTo(.criticalStock)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Expirations Proches") {
                coordinator.navigateTo(.expiringMedicines)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Détail Médicament") {
                coordinator.navigateTo(.medicineDetail("sample-id"))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Accueil")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    coordinator.popToRoot()
                }
            }
        }
    }
}

struct MedicineRootView: View {
    @EnvironmentObject var coordinator: MedicineCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Médicaments")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Voir Détail") {
                coordinator.navigateTo(.medicineDetail("sample-id"))
            }
            .buttonStyle(.borderedProminent)
            
            Button("Ajouter Médicament") {
                coordinator.navigateTo(.medicineForm(nil))
            }
            .buttonStyle(.borderedProminent)
            
            Button("Ajuster Stock") {
                coordinator.navigateTo(.adjustStock("sample-id"))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Médicaments")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    coordinator.popToRoot()
                }
            }
        }
    }
}

struct AisleRootView: View {
    @EnvironmentObject var coordinator: AisleCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rayons")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Détail Rayon") {
                coordinator.navigateTo(.aisleDetail("sample-id"))
            }
            .buttonStyle(.borderedProminent)
            
            Button("Médicaments du Rayon") {
                coordinator.navigateTo(.medicinesByAisle("sample-id"))
            }
            .buttonStyle(.borderedProminent)
            
            Button("Ajouter Rayon") {
                coordinator.navigateTo(.aisleForm(nil))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Rayons")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    coordinator.popToRoot()
                }
            }
        }
    }
}

struct HistoryRootView: View {
    @EnvironmentObject var coordinator: HistoryCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Historique")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Détail Historique") {
                coordinator.navigateTo(.historyDetail("sample-id"))
            }
            .buttonStyle(.borderedProminent)
            
            Button("Médicament Lié") {
                coordinator.navigateTo(.medicineDetail("sample-id"))
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Historique")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    coordinator.popToRoot()
                }
            }
        }
    }
}

struct ProfileRootView: View {
    @EnvironmentObject var coordinator: ProfileCoordinator
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profil")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button("Paramètres") {
                coordinator.navigateTo(.settings)
            }
            .buttonStyle(.borderedProminent)
            
            Button("À propos") {
                coordinator.navigateTo(.about)
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Profil")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Reset") {
                    coordinator.popToRoot()
                }
            }
        }
    }
}

#Preview {
    TabCoordinatorView()
}