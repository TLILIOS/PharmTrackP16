import SwiftUI

struct NewMedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.viewModelCreator) private var viewModelCreator
    
    let medicineId: String
    
    @State private var viewModel: ObservableMedicineDetailViewModel?
    @State private var showingDeleteConfirmation = false
    @State private var isHistoryExpanded = false
    @State private var showingAdjustStock = false
    @State private var showingEditForm = false
    
    // Animation properties
    @State private var headerScale = 0.95
    @State private var contentOffset = 50.0
    @State private var contentOpacity = 0.0
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            if let viewModel = viewModel {
                if viewModel.isLoading {
                    ProgressView("Chargement...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let medicine = viewModel.medicine {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header avec informations principales
                            headerView(medicine: medicine)
                                .scaleEffect(headerScale)
                            
                            // Contenu détaillé
                            VStack(spacing: 20) {
                                stockSection(medicine: medicine)
                                
                                if !(medicine.description?.isEmpty ?? true) {
                                    descriptionSection(medicine: medicine)
                                }
                                
                                detailsSection(medicine: medicine)
                                
                                historySection(viewModel: viewModel)
                                
                                // Actions
                                actionButtonsSection(medicine: medicine)
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
                    .refreshable {
                        await viewModel.loadMedicine(id: medicineId)
                    }
                } else {
                    ContentUnavailableView("Médicament non trouvé", systemImage: "pills")
                }
            } else {
                ProgressView("Initialisation...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Overlay du message d'erreur
            if let viewModel = viewModel, let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    
                    MessageView(message: errorMessage, type: .error) {
                        viewModel.errorMessage = nil
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: viewModel.errorMessage)
                .zIndex(1)
            }
        }
        .navigationTitle("Détails")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Modifier") {
                    showingEditForm = true
                }
            }
        }
        .sheet(isPresented: $showingAdjustStock) {
            if let medicine = viewModel?.medicine {
                NewAdjustStockView(medicineId: medicine.id)
            }
        }
        .sheet(isPresented: $showingEditForm) {
            if let medicine = viewModel?.medicine {
                NewMedicineFormView(medicineId: medicine.id)
            }
        }
        .alert("Supprimer ce médicament ?", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                Task {
                    await viewModel?.deleteMedicine()
                    dismiss()
                }
            }
        } message: {
            Text("Cette action est irréversible. L'historique associé sera également supprimé.")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ObservableMedicineDetailViewModel(
                    medicineId: medicineId,
                    medicineRepository: viewModelCreator.medicineRepository,
                    aisleRepository: viewModelCreator.aisleRepository,
                    historyRepository: viewModelCreator.historyRepository
                )
            }
            
            Task {
                await viewModel?.fetchHistory()
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    headerScale = 1.0
                }
                
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    contentOffset = 0
                    contentOpacity = 1.0
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await viewModel?.loadMedicine(id: medicineId)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await viewModel?.loadMedicine(id: medicineId)
                await viewModel?.fetchHistory()
            }
        }
    }
    
    // MARK: - View Components
    
    private func headerView(medicine: Medicine) -> some View {
        VStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.accentApp.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(String(medicine.name.prefix(1)))
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.accentApp)
            }
            
            Text(medicine.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if let aisleName = viewModel?.aisleName {
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
    
    private func stockSection(medicine: Medicine) -> some View {
        VStack(spacing: 10) {
            Text("Niveau de stock")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                StockIndicator(
                    value: medicine.currentQuantity,
                    maxValue: medicine.maxQuantity,
                    warningThreshold: medicine.warningThreshold,
                    criticalThreshold: medicine.criticalThreshold
                )
                .frame(width: 100, height: 100)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Actuel:")
                            .foregroundColor(.secondary)
                        Text("\(medicine.currentQuantity) \(medicine.unit)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Maximum:")
                            .foregroundColor(.secondary)
                        Text("\(medicine.maxQuantity) \(medicine.unit)")
                    }
                    
                    HStack {
                        Text("Seuil d'alerte:")
                            .foregroundColor(.secondary)
                        Text("\(medicine.warningThreshold) \(medicine.unit)")
                    }
                    
                    HStack {
                        Text("Seuil critique:")
                            .foregroundColor(.secondary)
                        Text("\(medicine.criticalThreshold) \(medicine.unit)")
                    }
                }
                
                Spacer()
            }
            
            // Bouton d'ajustement rapide
            Button("Ajuster le stock") {
                showingAdjustStock = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
    
    private func descriptionSection(medicine: Medicine) -> some View {
        VStack(spacing: 10) {
            Text("Description")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(medicine.description ?? "")
                .font(.body)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func detailsSection(medicine: Medicine) -> some View {
        VStack(spacing: 10) {
            Text("Informations complémentaires")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                detailRow(label: "Référence", value: medicine.reference ?? "")
                
                if let expiryDate = medicine.expiryDate {
                    detailRow(
                        label: "Date d'expiration",
                        value: formatDate(expiryDate),
                        valueColor: isExpiringSoon(expiryDate) ? .red : nil
                    )
                }
                
                detailRow(label: "Dosage", value: medicine.dosage ?? "")
                detailRow(label: "Forme", value: medicine.form ?? "")
                detailRow(label: "Créé le", value: formatDate(medicine.createdAt))
                detailRow(label: "Modifié le", value: formatDate(medicine.updatedAt))
            }
        }
    }
    
    private func historySection(viewModel: ObservableMedicineDetailViewModel) -> some View {
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
                        NavigationLink(destination: HistoryView(
                            historyViewModel: HistoryViewModel(
                                medicineId: medicineId,
                                getHistoryUseCase: RealGetHistoryUseCase(
                                    historyRepository: viewModelCreator.historyRepository
                                ),
                                medicineRepository: viewModelCreator.medicineRepository,
                                historyRepository: viewModelCreator.historyRepository
                            )
                        )) {
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
    
    private func actionButtonsSection(medicine: Medicine) -> some View {
        VStack(spacing: 12) {
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

#Preview {
    NavigationStack {
        NewMedicineDetailView(medicineId: "preview-id")
            .withRepositories()
    }
}