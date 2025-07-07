import SwiftUI

struct MedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MedicineDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingAdjustStockSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var isHistoryExpanded = false
    
    // Animation properties
    @State private var headerScale = 0.95
    @State private var contentOffset = 50.0
    @State private var contentOpacity = 0.0
    
    init(medicine: Medicine) {
        // Dans une application réelle, nous injecterions les dépendances nécessaires
        self._viewModel = StateObject(wrappedValue: MedicineDetailViewModel(
            medicine: medicine,
            getMedicineUseCase: MockGetMedicineUseCase(), // À remplacer par l'implémentation réelle
            updateMedicineStockUseCase: MockUpdateMedicineStockUseCase(), // À remplacer par l'implémentation réelle
            deleteMedicineUseCase: MockDeleteMedicineUseCase(), // À remplacer par l'implémentation réelle
            getHistoryUseCase: MockGetHistoryForMedicineUseCase() // À remplacer par l'implémentation réelle
        ))
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header avec informations principales
                    headerView
                        .scaleEffect(headerScale)
                    
                    // Contenu détaillé
                    VStack(spacing: 20) {
                        stockSection
                        
                        if !(viewModel.medicine.description?.isEmpty ?? true) {
                            descriptionSection
                        }
                        
                        detailsSection
                        
                        historySection
                        
                        // Boutons d'action
                        HStack(spacing: 15) {
                            Button(action: {
                                showingAdjustStockSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text("Ajuster stock")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentApp)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showingEditSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "pencil")
                                    Text("Modifier")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 10)
                        
                        // Bouton de suppression
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Supprimer")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                    .padding(.horizontal)
                    .offset(y: contentOffset)
                    .opacity(contentOpacity)
                }
                .padding(.bottom, 30)
            }
            
            // Overlay du message d'erreur
            if case .error(let message) = viewModel.state {
                VStack {
                    Spacer()
                    
                    MessageView(message: message, type: .error) {
                        viewModel.resetState()
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: viewModel.state)
                .zIndex(1)
            }
        }
        .navigationTitle("Détails du médicament")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            Text("Éditer médicament") // À remplacer par la vraie vue d'édition
        }
        .sheet(isPresented: $showingAdjustStockSheet) {
            Text("Ajuster stock") // À remplacer par la vraie vue d'ajustement
        }
        .alert("Supprimer ce médicament ?", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await viewModel.deleteMedicine()
                    if case .success = viewModel.state {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Cette action est irréversible. L'historique associé sera également supprimé.")
        }
        .onAppear {
            Task {
                await viewModel.fetchHistory()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    headerScale = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    contentOffset = 0
                    contentOpacity = 1.0
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.accentApp.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(String(viewModel.medicine.name.prefix(1)))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.accentApp)
            }
            
            Text(viewModel.medicine.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if let aisleName = viewModel.aisleName {
                HStack(spacing: 5) {
                    Image(systemName: "tag")
                        .font(.caption)
                    
                    Text(aisleName)
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
    }
    
    private var stockSection: some View {
        VStack(spacing: 10) {
            Text("Niveau de stock")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StockIndicator(
                    value: viewModel.medicine.currentQuantity,
                    maxValue: viewModel.medicine.maxQuantity,
                    warningThreshold: viewModel.medicine.warningThreshold,
                    criticalThreshold: viewModel.medicine.criticalThreshold
                )
                .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Actuel:")
                            .foregroundColor(.secondary)
                        Text("\(viewModel.medicine.currentQuantity) \(viewModel.medicine.unit)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Maximum:")
                            .foregroundColor(.secondary)
                        Text("\(viewModel.medicine.maxQuantity) \(viewModel.medicine.unit)")
                    }
                    
                    HStack {
                        Text("Seuil d'alerte:")
                            .foregroundColor(.secondary)
                        Text("\(viewModel.medicine.warningThreshold) \(viewModel.medicine.unit)")
                    }
                    
                    HStack {
                        Text("Seuil critique:")
                            .foregroundColor(.secondary)
                        Text("\(viewModel.medicine.criticalThreshold) \(viewModel.medicine.unit)")
                    }
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(spacing: 10) {
            Text("Description")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(viewModel.medicine.description ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var detailsSection: some View {
        VStack(spacing: 10) {
            Text("Informations complémentaires")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                detailRow(label: "Référence", value: viewModel.medicine.reference ?? "")
                
                if let expiryDate = viewModel.medicine.expiryDate {
                    detailRow(
                        label: "Date d'expiration",
                        value: formatDate(expiryDate),
                        valueColor: isExpiringSoon(expiryDate) ? .red : nil
                    )
                }
                
                detailRow(label: "Dosage", value: viewModel.medicine.dosage ?? "")
                detailRow(label: "Forme", value: viewModel.medicine.form ?? "")
            }
        }
    }
    
    private var historySection: some View {
        VStack(spacing: 10) {
            Button(action: {
                withAnimation {
                    isHistoryExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Historique")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: isHistoryExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isHistoryExpanded {
                if viewModel.isLoadingHistory {
                    ProgressView()
                        .padding()
                } else if viewModel.history.isEmpty {
                    Text("Aucun historique disponible")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.history.prefix(5)) { entry in
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    Text(entry.action)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text(formatDate(entry.timestamp, withTime: true))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(entry.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            
                            if entry.id != viewModel.history.prefix(5).last?.id {
                                Divider()
                            }
                        }
                    }
                    
                    if viewModel.history.count > 5 {
                        NavigationLink(destination: Text("Historique complet")) { // À remplacer par la vraie vue d'historique
                            Text("Voir tout l'historique")
                                .font(.caption)
                                .foregroundColor(.accentApp)
                                .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value.isEmpty ? "-" : value)
                .foregroundColor(valueColor ?? .primary)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date, withTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = withTime ? "dd/MM/yyyy HH:mm" : "dd/MM/yyyy"
        return formatter.string(from: date)
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expiryDate = calendar.startOfDay(for: date)
        let components = calendar.dateComponents([.day], from: today, to: expiryDate)
        return (components.day ?? Int.max) < 30
    }
}

struct StockIndicator: View {
    let value: Int
    let maxValue: Int
    let warningThreshold: Int
    let criticalThreshold: Int
    
    private var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return Double(value) / Double(maxValue)
    }
    
    private var color: Color {
        if value <= criticalThreshold {
            return .red
        } else if value <= warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 10)
            
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: percentage)
            
            VStack(spacing: 0) {
                Text("\(value)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                Text("\(maxValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        MedicineDetailView(medicine: Medicine(
            id: "1",
            name: "Doliprane",
            description: "Paracétamol pour traitement de la douleur et de la fièvre",
            dosage: "500 mg",
            form: "Comprimé",
            reference: "DOLI500",
            unit: "comprimés",
            currentQuantity: 15,
            maxQuantity: 30,
            warningThreshold: 10,
            criticalThreshold: 5,
            expiryDate: Date().addingTimeInterval(60*60*24*60), // 60 jours
            aisleId: "aisle1",
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
