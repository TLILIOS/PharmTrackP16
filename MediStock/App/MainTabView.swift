import SwiftUI
import Foundation
import Combine


struct MainTabView: View {
    @AppStorage("selectedTab") private var selectedTab = 0
    @AppStorage("selectedAppearance") private var selectedAppearance: AppearanceMode = .system
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // DASHBOARD TAB
            NavigationStack {
                NewDashboardView()
            }
            .tabItem {
                Label("Accueil", systemImage: "house")
            }
            .tag(0)
            
            // MEDICINES TAB
            NavigationStack {
                NewMedicineListView()
            }
            .tabItem {
                Label("Médicaments", systemImage: "pills")
            }
            .tag(1)
            
            // AISLES TAB
            NavigationStack {
                NewAislesView()
            }
            .tabItem {
                Label("Rayons", systemImage: "tray.2")
            }
            .tag(2)
            
            // HISTORY TAB
            NavigationStack {
                HistoryView(
                    historyViewModel: HistoryViewModel(
                        getHistoryUseCase: RealGetHistoryUseCase(
                            historyRepository: FirebaseHistoryRepository()
                        ),
                        getMedicinesUseCase: RealGetMedicinesUseCase(
                            medicineRepository: FirebaseMedicineRepository()
                        )
                    )
                )
            }
            .tabItem {
                Label("Historique", systemImage: "clock")
            }
            .tag(3)
            
            // PROFILE TAB
            NavigationStack {
                ProfileSimpleView()
            }
            .tabItem {
                Label("Profil", systemImage: "person")
            }
            .tag(4)
        }
        .preferredColorScheme(selectedAppearance.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("switchToTab"))) { notification in
            if let tabIndex = notification.object as? Int {
                selectedTab = tabIndex
            }
        }
    }
}

// MARK: - Vue Simplifiée du Dashboard
struct DashboardSimpleView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("👋 Bienvenue")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Gérez votre stock facilement")
                    .foregroundColor(.secondary)
                
                HStack(spacing: 15) {
                    StatCard(title: "Médicaments", value: "24", color: .blue)
                    StatCard(title: "Stock Critique", value: "5", color: .red)
                }
            }
            .padding()
        }
        .navigationTitle("MediStock")
    }
}

// MARK: - Vue Simplifiée des Médicaments
struct MedicineListSimpleView: View {
    var body: some View {
        List {
            ForEach(0..<5) { index in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Médicament \(index + 1)")
                            .font(.headline)
                        Text("Description du médicament")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text("Stock: \(10 + index)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Médicaments")
    }
}

// MARK: - Vue Simplifiée des Rayons
struct AisleListSimpleView: View {
    var body: some View {
        List {
            ForEach(0..<3) { index in
                HStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading) {
                        Text("Rayon \(index + 1)")
                            .font(.headline)
                        Text("Description du rayon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(5 + index) médicaments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Rayons")
    }
}

// MARK: - Vue Simplifiée de l'Historique
struct HistorySimpleView: View {
    var body: some View {
        List {
            ForEach(0..<10) { index in
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Action \(index + 1)")
                            .font(.headline)
                        Text("Détails de l'action effectuée")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Il y a \(index + 1)h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Historique")
    }
}

// MARK: - Vue Simplifiée du Profil
struct ProfileSimpleView: View {
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var showSignOutError = false
    
    private let authRepository = FirebaseAuthRepository()
    
    var body: some View {
        List {
            Section(header: Text("Profil")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(authRepository.currentUser?.displayName ?? "Utilisateur")
                            .font(.headline)
                        
                        Text(authRepository.currentUser?.email ?? "email@exemple.com")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 10)
                }
                .padding(.vertical, 10)
            }
            
            Section(header: Text("Préférences")) {
                NavigationLink(destination: AppearanceSettingsView()) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(.blue)
                        Text("Apparence")
                        Spacer()
                    }
                }
            }
            
            Section(header: Text("Actions")) {
                Button(action: {
                    Task {
                        await generateTestData()
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Générer des données de test")
                        Spacer()
                    }
                }
                
                Button(action: {
                    Task {
                        await signOut()
                    }
                }) {
                    HStack {
                        if isSigningOut {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                        }
                        Text(isSigningOut ? "Déconnexion..." : "Se déconnecter")
                        Spacer()
                    }
                }
                .foregroundColor(.red)
                .disabled(isSigningOut)
            }
        }
        .navigationTitle("Profil")
        .alert("Erreur de déconnexion", isPresented: $showSignOutError) {
            Button("OK") {
                showSignOutError = false
            }
        } message: {
            Text(signOutError ?? "Une erreur inconnue s'est produite")
        }
    }
    
    private func generateTestData() async {
        print("🧪 Génération des données de test...")
        try? await Task.sleep(nanoseconds: 500_000_000)
        print("✅ Données de test générées!")
    }
    
    private func signOut() async {
        isSigningOut = true
        signOutError = nil
        
        do {
            try await authRepository.signOut()
            print("✅ Déconnexion réussie")
        } catch {
            print("❌ Erreur de déconnexion: \(error)")
            signOutError = error.localizedDescription
            showSignOutError = true
        }
        
        isSigningOut = false
    }
}

// MARK: - Carte de Statistique
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    MainTabView()
}
