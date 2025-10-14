import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel.makeDefault()
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
                StatRow(label: "Médicaments", value: "\(dashboardViewModel.statistics.totalMedicines)")
                StatRow(label: "Rayons", value: "\(dashboardViewModel.statistics.totalAisles)")
                StatRow(label: "Stocks critiques", value: "\(dashboardViewModel.statistics.criticalStockCount)")
                StatRow(label: "Expirations proches", value: "\(dashboardViewModel.statistics.expiringMedicinesCount)")
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
        .task {
            await dashboardViewModel.loadData()
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

// MARK: - AboutView
// ✅ AboutView est défini dans PlaceholderViews.swift pour éviter la duplication

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