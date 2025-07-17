import SwiftUI

struct MedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.viewModelCreator) private var viewModelCreator
    @StateObject private var viewModel: MedicineDetailViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isHistoryExpanded = false
    @State private var showingAdjustStock = false
    @State private var showingEditForm = false
    @State private var showingFullHistory = false
    @State private var showingExportOptions = false
    @State private var showingDeleteAlert = false
    
    // Animation properties
    @State private var headerScale = 0.95
    @State private var contentOffset = 50.0
    @State private var contentOpacity = 0.0
    
    let medicineId: String
    
    init(medicineId: String, viewModel: MedicineDetailViewModel) {
        self.medicineId = medicineId
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        mainContentView
            .navigationTitle("Détails")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        .sheet(isPresented: $showingAdjustStock) {
            NavigationStack {
                AdjustStockView(
                    medicineId: medicineId,
                    viewModel: viewModelCreator.createAdjustStockViewModel(
                        medicineId: medicineId,
                        medicine: viewModel.medicine
                    )
                )
            }
        }
        .sheet(isPresented: $showingEditForm) {
            NavigationStack {
                MedicineFormView(
                    medicineId: viewModel.medicine.id,
                    viewModel: MedicineFormViewModel(
                        getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                        getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                        addMedicineUseCase: RealAddMedicineUseCase(
                            medicineRepository: FirebaseMedicineRepository(),
                            historyRepository: FirebaseHistoryRepository()
                        ),
                        updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                        medicine: viewModel.medicine
                    )
                )
            }
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
                await viewModel.refreshMedicine()
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await viewModel.refreshMedicine()
                await viewModel.fetchHistory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await viewModel.refreshMedicine()
                await viewModel.fetchHistory()
            }
        }
    }
    
    // MARK: - View Components
    
    private var mainContentView: some View {
        ZStack {
            backgroundView
            
            if case .loading = viewModel.state {
                loadingView
            } else {
                scrollableContent
            }
            
            errorOverlay
        }
        .sheet(isPresented: $showingEditForm) {
            editFormSheet
        }
        .sheet(isPresented: $showingFullHistory) {
            fullHistorySheet
        }
        .sheet(isPresented: $showingExportOptions) {
            exportOptionsSheet
        }
        .alert("Supprimer ce médicament?", isPresented: $showingDeleteAlert) {
            deleteAlert
        } message: {
            Text("Cette action est irréversible. L'historique associé sera également supprimé.")
        }
        .onAppear {
            performOnAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await viewModel.refreshMedicine()
                await viewModel.fetchHistory()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await viewModel.refreshMedicine()
                await viewModel.fetchHistory()
            }
        }
    }
    
    private var backgroundView: some View {
        Color.backgroundApp.opacity(0.1).ignoresSafeArea()
    }
    
    private var loadingView: some View {
        ProgressView("Chargement...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var scrollableContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView(medicine: viewModel.medicine)
                    .scaleEffect(headerScale)
                
                contentStack
            }
            .padding(.bottom, 30)
        }
        .refreshable {
            await viewModel.refreshMedicine()
        }
    }
    
    private var contentStack: some View {
        VStack(spacing: 20) {
            stockSection(medicine: viewModel.medicine)
            
            if !(viewModel.medicine.description?.isEmpty ?? true) {
                descriptionSection(medicine: viewModel.medicine)
            }
            
            detailsSection(medicine: viewModel.medicine)
            historySection
            actionButtonsSection(medicine: viewModel.medicine)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .padding(.horizontal)
        .offset(y: contentOffset)
        .opacity(contentOpacity)
    }
    
    private var errorOverlay: some View {
        Group {
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
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Modifier") {
                showingEditForm = true
            }
        }
    }
    
    // MARK: - Sheets
    
    
    private var editFormSheet: some View {
        NavigationStack {
            MedicineFormView(
                medicineId: viewModel.medicine.id,
                viewModel: MedicineFormViewModel(
                    getMedicineUseCase: RealGetMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    getAislesUseCase: RealGetAislesUseCase(aisleRepository: FirebaseAisleRepository()),
                    addMedicineUseCase: RealAddMedicineUseCase(
                        medicineRepository: FirebaseMedicineRepository(),
                        historyRepository: FirebaseHistoryRepository()
                    ),
                    updateMedicineUseCase: RealUpdateMedicineUseCase(medicineRepository: FirebaseMedicineRepository()),
                    medicine: viewModel.medicine
                )
            )
        }
    }
    
    private var fullHistorySheet: some View {
        NavigationStack {
            MedicineHistoryView(medicineId: viewModel.medicine.id)
        }
    }
    
    private var exportOptionsSheet: some View {
        NavigationStack {
            VStack {
                Text("Options d'exportation")
                    .font(.headline)
                    .padding()
                
                Text("Fonctionnalité à implémenter")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Exporter les données")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var deleteAlert: some View {
        Button("Annuler", role: .cancel) { }
        Button("Supprimer", role: .destructive) {
            Task {
                await viewModel.deleteMedicine()
            }
        }
    }
    
    private func performOnAppear() {
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
                        NavigationLink(destination: MedicineHistoryView(medicineId: medicineId)) {
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
                
                Text("/\(maxValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Mock Export Use Case

// MARK: - MedicineHistoryView pour l'historique complet
struct MedicineHistoryView: View {
    let medicineId: String
    @StateObject private var viewModel: HistoryViewModel
    
    init(medicineId: String) {
        self.medicineId = medicineId
        self._viewModel = StateObject(wrappedValue: HistoryViewModel(
            getHistoryUseCase: RealGetHistoryUseCase(historyRepository: FirebaseHistoryRepository()),
            getMedicinesUseCase: RealGetMedicinesUseCase(medicineRepository: FirebaseMedicineRepository())
        ))
    }
    
    var body: some View {
        List(viewModel.history) { entry in
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
            .padding(.vertical, 4)
        }
        .navigationTitle("Historique")
        .onAppear {
            Task {
                await viewModel.loadHistoryForMedicine(medicineId: medicineId)
            }
        }
    }
    
    private func formatDate(_ date: Date, withTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = withTime ? "dd/MM/yyyy HH:mm" : "dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        MedicineDetailView(
            medicineId: "preview-id",
            viewModel: MedicineDetailViewModel(
                medicine: Medicine(
                    id: "1",
                    name: "Paracétamol",
                    description: "Antalgique et antipyrétique pour le traitement symptomatique des douleurs et de la fièvre",
                    dosage: "500mg",
                    form: "Comprimé",
                    reference: "PAR-500",
                    unit: "comprimés",
                    currentQuantity: 45,
                    maxQuantity: 100,
                    warningThreshold: 20,
                    criticalThreshold: 10,
                    expiryDate: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
                    aisleId: "aisle-1",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                getMedicineUseCase: MockGetMedicineUseCase(),
                updateMedicineStockUseCase: MockUpdateMedicineStockUseCase(),
                deleteMedicineUseCase: MockDeleteMedicineUseCase(),
                getHistoryUseCase: MockGetHistoryForMedicineUseCase()
            )
        )
    }
}