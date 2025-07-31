import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingExportSheet = false
    @State private var pdfURL: URL?
    
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
                        color: Color.blue
                    )
                    
                    StatCard(
                        title: "Rayons",
                        value: "\(appState.aisles.count)",
                        icon: "square.grid.2x2",
                        color: Color.green
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
                            NavigationLink("Voir tout", value: DashboardDestination.criticalStock)
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
                            NavigationLink("Voir tout", value: DashboardDestination.expiringMedicines)
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
            case .expiringMedicines:
                ExpiringMedicinesListView()
                    .environmentObject(appState)
            }
        }
        .refreshable {
            await appState.loadData()
        }
        .sheet(isPresented: $showingExportSheet) {
            if let pdfURL = pdfURL {
                ShareSheet(activityItems: [pdfURL])
            }
        }
    }
    
    private func exportToPDF() {
        Task {
            do {
                let pdfData = await generatePDFReport()
                let fileName = "MediStock_Export_\(Date().formatted(date: .abbreviated, time: .omitted)).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                try pdfData.write(to: tempURL)
                
                await MainActor.run {
                    self.pdfURL = tempURL
                    self.showingExportSheet = true
                }
            } catch {
                print("Erreur lors de l'export PDF: \(error)")
            }
        }
    }
    
    @MainActor
    private func generatePDFReport() async -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "MediStock",
            kCGPDFContextAuthor: authViewModel.currentUser?.displayName ?? "Utilisateur",
            kCGPDFContextTitle: "Rapport d'inventaire MediStock"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            let leftMargin: CGFloat = 50
            let rightMargin: CGFloat = 50
            let contentWidth = pageWidth - leftMargin - rightMargin
            
            // Titre principal
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "Rapport d'inventaire MediStock"
            title.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Date du rapport
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            let dateString = "Généré le \(Date().formatted(date: .complete, time: .shortened))"
            dateString.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: dateAttributes)
            yPosition += 30
            
            // Informations utilisateur
            let userInfo = "Utilisateur: \(authViewModel.currentUser?.displayName ?? authViewModel.currentUser?.email ?? "Non identifié")"
            userInfo.draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: dateAttributes)
            yPosition += 40
            
            // Section: Résumé
            yPosition = drawSection(context: context, title: "Résumé", yPosition: yPosition, pageRect: pageRect) { y in
                var currentY = y
                let summaryAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.black
                ]
                
                let summaryItems = [
                    "Nombre total de médicaments: \(appState.medicines.count)",
                    "Nombre de rayons: \(appState.aisles.count)",
                    "Médicaments en stock critique: \(appState.criticalMedicines.count)",
                    "Médicaments expirant bientôt: \(appState.expiringMedicines.count)"
                ]
                
                for item in summaryItems {
                    item.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: summaryAttributes)
                    currentY += 20
                }
                
                return currentY
            }
            
            // Section: Inventaire par rayon
            yPosition = drawSection(context: context, title: "Inventaire par rayon", yPosition: yPosition, pageRect: pageRect) { y in
                var currentY = y
                let itemAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.black
                ]
                
                for aisle in appState.aisles.sorted(by: { $0.name < $1.name }) {
                    // Vérifier si on a besoin d'une nouvelle page
                    if currentY > pageHeight - 100 {
                        context.beginPage()
                        currentY = 50
                    }
                    
                    // Nom du rayon
                    let aisleTitle = "• \(aisle.name)"
                    let aisleTitleAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 13),
                        .foregroundColor: UIColor.black
                    ]
                    aisleTitle.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: aisleTitleAttributes)
                    currentY += 20
                    
                    // Médicaments du rayon
                    let medicinesInAisle = appState.medicines.filter { $0.aisleId == aisle.id }
                    if medicinesInAisle.isEmpty {
                        "  Aucun médicament".draw(at: CGPoint(x: leftMargin + 40, y: currentY), withAttributes: itemAttributes)
                        currentY += 20
                    } else {
                        for medicine in medicinesInAisle.sorted(by: { $0.name < $1.name }) {
                            let medicineInfo = "  - \(medicine.name): \(medicine.currentQuantity)/\(medicine.maxQuantity) \(medicine.unit)"
                            medicineInfo.draw(at: CGPoint(x: leftMargin + 40, y: currentY), withAttributes: itemAttributes)
                            currentY += 18
                        }
                    }
                    currentY += 10
                }
                
                return currentY
            }
            
            // Section: Stocks critiques
            if !appState.criticalMedicines.isEmpty {
                yPosition = drawSection(context: context, title: "Stocks critiques", yPosition: yPosition, pageRect: pageRect) { y in
                    var currentY = y
                    let criticalAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.red
                    ]
                    
                    for medicine in appState.criticalMedicines.sorted(by: { $0.name < $1.name }) {
                        let info = "• \(medicine.name): \(medicine.currentQuantity)/\(medicine.maxQuantity) \(medicine.unit) (Seuil critique: \(medicine.criticalThreshold))"
                        info.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: criticalAttributes)
                        currentY += 20
                    }
                    
                    return currentY
                }
            }
            
            // Section: Expirations proches
            if !appState.expiringMedicines.isEmpty {
                yPosition = drawSection(context: context, title: "Expirations proches", yPosition: yPosition, pageRect: pageRect) { y in
                    var currentY = y
                    let expiryAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 11),
                        .foregroundColor: UIColor.orange
                    ]
                    
                    for medicine in appState.expiringMedicines.sorted(by: { $0.expiryDate ?? Date() < $1.expiryDate ?? Date() }) {
                        if let expiryDate = medicine.expiryDate {
                            let status = medicine.isExpired ? "EXPIRÉ" : "Expire"
                            let info = "• \(medicine.name): \(status) le \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
                            let attributes = medicine.isExpired ? [
                                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 11),
                                .foregroundColor: UIColor.red
                            ] : expiryAttributes
                            info.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: attributes)
                            currentY += 20
                        }
                    }
                    
                    return currentY
                }
            }
            
            // Section: Historique récent
            yPosition = drawSection(context: context, title: "Historique récent", yPosition: yPosition, pageRect: pageRect) { y in
                var currentY = y
                let historyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.darkGray
                ]
                
                let recentHistory = appState.history.prefix(20)
                for entry in recentHistory {
                    let info = "• \(entry.timestamp.formatted(date: .abbreviated, time: .shortened)) - \(entry.action): \(entry.details)"
                    info.draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: historyAttributes)
                    currentY += 18
                }
                
                if recentHistory.isEmpty {
                    "Aucune activité récente".draw(at: CGPoint(x: leftMargin + 20, y: currentY), withAttributes: historyAttributes)
                }
                
                return currentY
            }
        }
        
        return data
    }
    
    private func drawSection(context: UIGraphicsPDFRendererContext, title: String, yPosition: CGFloat, pageRect: CGRect, drawContent: (CGFloat) -> CGFloat) -> CGFloat {
        var currentY = yPosition
        
        // Vérifier si on a besoin d'une nouvelle page
        if currentY > pageRect.height - 150 {
            context.beginPage()
            currentY = 50
        }
        
        // Titre de section
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        title.draw(at: CGPoint(x: 50, y: currentY), withAttributes: sectionTitleAttributes)
        currentY += 25
        
        // Ligne de séparation
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: 50, y: currentY))
        linePath.addLine(to: CGPoint(x: pageRect.width - 50, y: currentY))
        UIColor.lightGray.setStroke()
        linePath.lineWidth = 0.5
        linePath.stroke()
        currentY += 15
        
        // Contenu de la section
        currentY = drawContent(currentY)
        currentY += 30
        
        return currentY
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
        .navigationDestination(for: MedicineDestination.self) { destination in
            switch destination {
            case .add:
                MedicineFormView(medicine: nil)
                    .environmentObject(appState)
            case .detail(let medicine):
                MedicineDetailView(medicineId: medicine.id)
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
    
    var body: some View {
        List(appState.expiringMedicines) { medicine in
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
                MedicineDetailView(medicineId: medicine.id)
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