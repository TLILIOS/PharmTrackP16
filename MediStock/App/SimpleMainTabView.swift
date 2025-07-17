import SwiftUI

struct SimpleMainTabView: View {
    @State private var selectedTab = 0
    
    // Stacks de navigation complètement indépendants
    @State private var dashboardPath = NavigationPath()
    @State private var medicinesPath = NavigationPath()
    @State private var aislesPath = NavigationPath()
    @State private var historyPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // DASHBOARD TAB
            NavigationStack(path: $dashboardPath) {
                DashboardContentView()
                    .navigationDestination(for: DashboardDestination.self) { destination in
                        switch destination {
                        case .criticalStock:
                            Text("Stocks Critiques")
                        case .expiringMedicines:
                            Text("Médicaments Expirant")
                        case .medicineDetail(let id):
                            Text("Détail médicament: \(id)")
                        case .adjustStock(let id):
                            Text("Ajuster stock: \(id)")
                        case .medicineForm(let id):
                            Text("Formulaire médicament: \(id ?? "nouveau")")
                        }
                    }
            }
            .tabItem {
                Label("Accueil", systemImage: "house")
            }
            .tag(0)
            
            // MEDICINES TAB
            NavigationStack(path: $medicinesPath) {
                MedicinesContentView()
                    .navigationDestination(for: MedicineDestination.self) { destination in
                        switch destination {
                        case .medicineDetail(let id):
                            Text("Détail médicament: \(id)")
                        case .medicineForm(let id):
                            Text("Formulaire médicament: \(id ?? "nouveau")")
                        case .adjustStock(let id):
                            Text("Ajuster stock: \(id)")
                        }
                    }
            }
            .tabItem {
                Label("Médicaments", systemImage: "pills")
            }
            .tag(1)
            
            // AISLES TAB
            NavigationStack(path: $aislesPath) {
                AislesContentView()
                    .navigationDestination(for: AisleDestination.self) { destination in
                        switch destination {
                        case .aisleDetail(let id):
                            Text("Détail rayon: \(id)")
                        case .medicinesByAisle(let id):
                            Text("Médicaments du rayon: \(id)")
                        case .aisleForm(let id):
                            Text("Formulaire rayon: \(id ?? "nouveau")")
                        case .medicineDetail(let id):
                            Text("Détail médicament: \(id)")
                        }
                    }
            }
            .tabItem {
                Label("Rayons", systemImage: "tray.2")
            }
            .tag(2)
            
            // HISTORY TAB
            NavigationStack(path: $historyPath) {
                SimpleHistoryContentView()
                    .navigationDestination(for: HistoryDestination.self) { destination in
                        switch destination {
                        case .historyDetail(let id):
                            Text("Détail historique: \(id)")
                        case .medicineDetail(let id):
                            Text("Détail médicament: \(id)")
                        }
                    }
            }
            .tabItem {
                Label("Historique", systemImage: "clock")
            }
            .tag(3)
            
            // PROFILE TAB
            NavigationStack(path: $profilePath) {
                ProfileContentView()
                    .navigationDestination(for: ProfileDestination.self) { destination in
                        switch destination {
                        case .settings:
                            Text("Paramètres")
                        case .about:
                            Text("À propos")
                        }
                    }
            }
            .tabItem {
                Label("Profil", systemImage: "person")
            }
            .tag(4)
        }
    }
}


// MARK: - Content Views (vues principales de chaque onglet)

struct DashboardContentView: View {
    var body: some View {
        VStack {
            Text("Dashboard")
            
            NavigationLink("Voir stocks critiques", value: DashboardDestination.criticalStock)
            NavigationLink("Voir expirations", value: DashboardDestination.expiringMedicines)
            NavigationLink("Détail médicament", value: DashboardDestination.medicineDetail("test-id"))
        }
        .navigationTitle("Accueil")
    }
}

struct MedicinesContentView: View {
    var body: some View {
        VStack {
            Text("Liste des Médicaments")
            
            NavigationLink("Détail médicament", value: MedicineDestination.medicineDetail("test-id"))
            NavigationLink("Ajouter médicament", value: MedicineDestination.medicineForm(nil))
            NavigationLink("Ajuster stock", value: MedicineDestination.adjustStock("test-id"))
        }
        .navigationTitle("Médicaments")
    }
}

struct AislesContentView: View {
    var body: some View {
        VStack {
            Text("Liste des Rayons")
            
            NavigationLink("Détail rayon", value: AisleDestination.aisleDetail("test-id"))
            NavigationLink("Médicaments du rayon", value: AisleDestination.medicinesByAisle("test-id"))
            NavigationLink("Ajouter rayon", value: AisleDestination.aisleForm(nil))
        }
        .navigationTitle("Rayons")
    }
}

struct SimpleHistoryContentView: View {
    var body: some View {
        VStack {
            Text("Historique")
            
            NavigationLink("Détail historique", value: HistoryDestination.historyDetail("test-id"))
            NavigationLink("Médicament lié", value: HistoryDestination.medicineDetail("test-id"))
        }
        .navigationTitle("Historique")
    }
}

struct ProfileContentView: View {
    var body: some View {
        VStack {
            Text("Mon Profil")
            
            NavigationLink("Paramètres", value: ProfileDestination.settings)
            NavigationLink("À propos", value: ProfileDestination.about)
        }
        .navigationTitle("Profil")
    }
}



#Preview {
    SimpleMainTabView()
}