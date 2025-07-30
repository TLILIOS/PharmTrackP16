import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête
                HStack {
                    VStack(alignment: .leading) {
                        Text("Bonjour,")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text(authViewModel.currentUser?.displayName ?? "Utilisateur")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Statistiques
                HStack(spacing: 15) {
                    StatCard(
                        title: "Médicaments",
                        value: "\(appState.medicines.count)",
                        icon: "pills",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Rayons",
                        value: "\(appState.aisles.count)",
                        icon: "square.grid.2x2",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Stocks critiques
                if !appState.criticalMedicines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Stocks critiques", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                            Spacer()
                            NavigationLink("Voir tout") {
                                CriticalStockListView()
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(appState.criticalMedicines.prefix(5)) { medicine in
                                    MedicineCard(medicine: medicine)
                                        .frame(width: 250)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Médicaments expirant bientôt
                if !appState.expiringMedicines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Expirations proches", systemImage: "calendar.badge.exclamationmark")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                            NavigationLink("Voir tout") {
                                ExpiringMedicinesListView()
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(appState.expiringMedicines.prefix(5)) { medicine in
                                    MedicineCard(medicine: medicine, showExpiry: true)
                                        .frame(width: 250)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Actions rapides
                VStack(alignment: .leading, spacing: 10) {
                    Text("Actions rapides")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        QuickActionButton(
                            title: "Ajouter",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            // Navigation will be handled by MainView
                        }
                        
                        QuickActionButton(
                            title: "Scanner",
                            icon: "barcode.viewfinder",
                            color: .green
                        ) {
                            // TODO: Implémenter le scanner
                        }
                        
                        QuickActionButton(
                            title: "Exporter",
                            icon: "square.and.arrow.up",
                            color: .orange
                        ) {
                            // TODO: Implémenter l'export
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Tableau de bord")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await appState.loadData()
        }
    }
}

// MARK: - Composants du Dashboard

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// MARK: - Vues de listes spécialisées

struct CriticalStockListView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(appState.criticalMedicines) { medicine in
            NavigationLink(value: MedicineDestination.detail(medicine)) {
                MedicineRow(medicine: medicine)
            }
        }
        .navigationTitle("Stocks critiques")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ExpiringMedicinesListView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(appState.expiringMedicines) { medicine in
            NavigationLink(value: MedicineDestination.detail(medicine)) {
                MedicineRow(medicine: medicine, showExpiry: true)
            }
        }
        .navigationTitle("Expirations proches")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Navigation
// MedicineDestination is defined in NavigationDestinations.swift