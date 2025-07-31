import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert = false
    @State private var showingNotificationSettings = false
    
    var body: some View {
        List {
            // Profil utilisateur
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authViewModel.currentUser?.displayName ?? "Utilisateur")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // Statistiques
            Section("Statistiques") {
                StatRow(label: "Médicaments", value: "\(appState.medicines.count)")
                StatRow(label: "Rayons", value: "\(appState.aisles.count)")
                StatRow(label: "Stocks critiques", value: "\(appState.criticalMedicines.count)")
                StatRow(label: "Expirations proches", value: "\(appState.expiringMedicines.count)")
            }
            
            // Paramètres
            Section("Paramètres") {
                Button(action: { showingNotificationSettings = true }) {
                    Label("Notifications", systemImage: "bell")
                }
                
                NavigationLink {
                    AboutView()
                } label: {
                    Label("À propos", systemImage: "info.circle")
                }
            }
            
            // Déconnexion
            Section {
                Button(role: .destructive, action: { showingSignOutAlert = true }) {
                    HStack {
                        Spacer()
                        Text("Se déconnecter")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .alert("Se déconnecter ?", isPresented: $showingSignOutAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Se déconnecter", role: .destructive) {
                Task {
                    await authViewModel.signOut()
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir vous déconnecter ?")
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

struct AboutView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(systemName: "pills.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                    
                    Text("MediStock")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section("Informations") {
                InfoRow(label: "Développeur", value: authViewModel.currentUser?.displayName ?? "Développeur")
                InfoRow(label: "Licence", value: "TliliOS")
                InfoRow(label: "Support", value: authViewModel.currentUser?.email ?? "contact@medistock.com")
            }
            
            Section("Technologies") {
                Text("Développé avec SwiftUI et Firebase")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notifyLowStock") private var notifyLowStock = true
    @AppStorage("notifyExpiry") private var notifyExpiry = true
    @AppStorage("expiryDays") private var expiryDays = 30
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Notifications de stock") {
                    Toggle("Stock faible", isOn: $notifyLowStock)
                    Toggle("Stock critique", isOn: .constant(true))
                        .disabled(true)
                }
                
                Section("Notifications d'expiration") {
                    Toggle("Médicaments expirant", isOn: $notifyExpiry)
                    
                    if notifyExpiry {
                        Stepper("Alerter \(expiryDays) jours avant", value: $expiryDays, in: 7...90, step: 7)
                    }
                }
                
                Section {
                    Text("Les notifications critiques ne peuvent pas être désactivées pour votre sécurité.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}