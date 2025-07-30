import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutAlert = false
    @State private var showingExportOptions = false
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
            
            // Actions
            Section("Gestion des données") {
                Button(action: { showingExportOptions = true }) {
                    Label("Exporter les données", systemImage: "square.and.arrow.up")
                }
                
                Button(action: importData) {
                    Label("Importer des données", systemImage: "square.and.arrow.down")
                }
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
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
    }
    
    func importData() {
        // TODO: Implémenter l'import de données
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
                InfoRow(label: "Développeur", value: "Votre nom")
                InfoRow(label: "Licence", value: "MIT")
                InfoRow(label: "Support", value: "support@medistock.com")
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

struct ExportOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                Section("Format d'export") {
                    Button(action: { exportData(format: .csv) }) {
                        Label("Exporter en CSV", systemImage: "doc.text")
                    }
                    
                    Button(action: { exportData(format: .json) }) {
                        Label("Exporter en JSON", systemImage: "doc.richtext")
                    }
                    
                    Button(action: { exportData(format: .pdf) }) {
                        Label("Exporter en PDF", systemImage: "doc.fill")
                    }
                }
                
                Section {
                    Text("Les données exportées incluront tous vos médicaments, rayons et historique.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Exporter les données")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
    
    enum ExportFormat {
        case csv, json, pdf
    }
    
    func exportData(format: ExportFormat) {
        // TODO: Implémenter l'export selon le format
        dismiss()
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