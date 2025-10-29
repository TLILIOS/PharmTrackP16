import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dashboardViewModel: DashboardViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    let pdfExportService: PDFExportServiceProtocol
    @State private var pdfExportItem: PDFExportItem?
    @State private var showingExportError = false
    @State private var exportErrorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Network Status Banner
                if !dashboardViewModel.networkStatus.isConnected {
                    NetworkStatusBanner(status: dashboardViewModel.networkStatus)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

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
                        value: "\(dashboardViewModel.statistics.totalMedicines)",
                        icon: "pills",
                        color: Color.blue
                    )

                    StatCard(
                        title: "Rayons",
                        value: "\(dashboardViewModel.statistics.totalAisles)",
                        icon: "square.grid.2x2",
                        color: Color.green
                    )
                }
                .padding(.horizontal)
                
                // Stocks critiques
                if !dashboardViewModel.criticalMedicines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Stocks critiques", systemImage: "exclamationmark.triangle.fill")
                                .font(.headline)
                                .foregroundColor(.red)
                            Spacer()
                            NavigationLink("Voir tout", value: DashboardDestination.criticalStock)
                            .font(.caption)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(dashboardViewModel.topCriticalMedicines) { medicine in
                                    MedicineCard(medicine: medicine)
                                        .frame(width: 250)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Médicaments expirant bientôt
                if !dashboardViewModel.expiringMedicines.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Expirations proches", systemImage: "calendar.badge.exclamationmark")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Spacer()
                            NavigationLink("Voir tout", value: DashboardDestination.expiringMedicines)
                            .font(.caption)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(dashboardViewModel.topExpiringMedicines) { medicine in
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
                    
                    HStack {
                        QuickActionButton(
                            title: "Exporter",
                            icon: "square.and.arrow.up",
                            color: .orange
                        ) {
                            exportToPDF()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Tableau de bord")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: DashboardDestination.self) { destination in
            switch destination {
            case .criticalStock:
                CriticalStockListView()
                    .environmentObject(appState)
                    .environmentObject(dashboardViewModel)
            case .expiringMedicines:
                ExpiringMedicinesListView()
                    .environmentObject(appState)
                    .environmentObject(dashboardViewModel)
            }
        }
        .refreshable {
            await dashboardViewModel.loadData()
        }
        .task {
            if dashboardViewModel.medicines.isEmpty {
                await dashboardViewModel.loadData()
            }
        }
        .sheet(item: $pdfExportItem) { item in
            if let url = item.url {
                ShareSheet(activityItems: [url])
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Génération du PDF en cours...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .alert("Erreur d'export", isPresented: $showingExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportErrorMessage ?? "Une erreur inconnue s'est produite lors de l'export du rapport.")
        }
    }
    
    private func exportToPDF() {
        Task { @MainActor in
            do {
                // Ouvrir la sheet avec indicateur de chargement
                self.pdfExportItem = PDFExportItem(url: nil)

                // Capture des données sur MainActor
                let authorName = authViewModel.currentUser?.displayName ??
                                authViewModel.currentUser?.email ??
                                "Utilisateur"
                let medicines = dashboardViewModel.medicines
                let aisles = dashboardViewModel.aisles

                // Génération PDF en arrière-plan (Priorité 3)
                let pdfData = try await Task.detached {
                    try await pdfExportService.generateInventoryReport(
                        medicines: medicines,
                        aisles: aisles,
                        authorName: authorName
                    )
                }.value

                let fileName = "MediStock_Export_\(Date().formatted(date: .abbreviated, time: .omitted)).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

                try pdfData.write(to: tempURL)

                // Mise à jour de l'UI sur MainActor avec le PDF généré
                self.pdfExportItem = PDFExportItem(url: tempURL)
            } catch {
                // Fermer la sheet et afficher l'erreur
                self.pdfExportItem = nil
                self.exportErrorMessage = "Impossible d'exporter le rapport : \(error.localizedDescription)"
                self.showingExportError = true
            }
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
    @EnvironmentObject var dashboardViewModel: DashboardViewModel

    var body: some View {
        List(dashboardViewModel.criticalMedicines) { medicine in
            NavigationLink(value: MedicineDestination.detail(medicine)) {
                MedicineRow(medicine: medicine)
            }
        }
        .navigationTitle("Stocks critiques")
        .navigationBarTitleDisplayMode(.large)
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
}

struct ExpiringMedicinesListView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dashboardViewModel: DashboardViewModel

    var body: some View {
        List(dashboardViewModel.expiringMedicines) { medicine in
            NavigationLink(value: MedicineDestination.detail(medicine)) {
                MedicineRow(medicine: medicine, showExpiry: true)
            }
        }
        .navigationTitle("Expirations proches")
        .navigationBarTitleDisplayMode(.large)
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
}

// MARK: - Navigation
// MedicineDestination is defined in NavigationDestinations.swift

// MARK: - PDF Export Item

/// Wrapper Identifiable pour gérer l'état de l'export PDF
/// Permet l'utilisation de .sheet(item:) pour afficher la sheet d'export
struct PDFExportItem: Identifiable {
    let id = UUID()
    let url: URL?
}