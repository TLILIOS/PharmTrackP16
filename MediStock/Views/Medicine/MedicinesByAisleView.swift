import SwiftUI

struct MedicinesByAisleView: View {
    let aisleId: String
    @Environment(\.medicineRepository) private var medicineRepository
    @Environment(\.aisleRepository) private var aisleRepository
    @Environment(\.historyRepository) private var historyRepository
    @Environment(\.viewModelCreator) private var viewModelCreator
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: MedicineStockViewModel
    @State private var aisle: Aisle?
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var sortOption: SortOption = .nameAscending
    @State private var selectedStockFilter: StockFilter = .all
    @State private var showingAddMedicine = false
    
    // Animation properties
    @State private var headerOpacity = 0.0
    @State private var contentOffset = CGFloat(30)
    @State private var contentOpacity = 0.0
    
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "Nom A-Z"
        case nameDescending = "Nom Z-A"
        case quantityAscending = "Quantité croissante"
        case quantityDescending = "Quantité décroissante"
        case expiryDate = "Date d'expiration"
        
        var id: String { self.rawValue }
    }
    
    enum StockFilter: String, CaseIterable, Identifiable {
        case all = "Tous"
        case critical = "Critique"
        case warning = "Alerte"
        case adequate = "Adéquat"
        
        var id: String { self.rawValue }
    }
    
    init(aisleId: String) {
        self.aisleId = aisleId
        self._viewModel = StateObject(wrappedValue: MedicineStockViewModel(
            medicineRepository: FirebaseMedicineRepository(),
            aisleRepository: FirebaseAisleRepository(),
            historyRepository: FirebaseHistoryRepository()
        ))
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            if isLoading {
                ProgressView("Chargement...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let aisle = aisle {
                VStack(spacing: 0) {
                    // Header du rayon
                    aisleHeaderView(aisle: aisle)
                        .opacity(headerOpacity)
                    
                    // Filtres et recherche
                    filtersSection
                        .offset(y: contentOffset)
                        .opacity(contentOpacity)
                    
                    // Liste des médicaments
                    medicinesList
                        .offset(y: contentOffset)
                        .opacity(contentOpacity)
                }
            } else {
                ContentUnavailableView("Rayon non trouvé", systemImage: "folder.badge.questionmark")
            }
        }
        .navigationTitle(aisle?.name ?? "Rayon")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMedicine = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMedicine) {
            MedicineFormView(
                medicineId: nil,
                viewModel: viewModelCreator.createMedicineFormViewModel(medicineId: nil)
            )
        }
        .task {
            await loadData()
        }
        .onAppear {
            startAnimations()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted"))) { _ in
            Task {
                await loadMedicines()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated"))) { _ in
            Task {
                await loadMedicines()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineAdded"))) { _ in
            Task {
                await loadMedicines()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MedicineDeleted"))) { _ in
            Task {
                await loadMedicines()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AisleUpdated"))) { _ in
            Task {
                await loadAisle()
                await loadMedicines()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AisleDeleted"))) { notification in
            // Si le rayon actuel est supprimé, retourner en arrière
            if let deletedId = notification.object as? String, deletedId == aisleId {
                dismiss()
            }
        }
    }
    
    // MARK: - View Components
    
    private func aisleHeaderView(aisle: Aisle) -> some View {
        VStack(spacing: 15) {
            // Icône du rayon
            ZStack {
                Circle()
                    .fill(aisle.color)
                    .frame(width: 80, height: 80)
                
                if !aisle.icon.isEmpty {
                    Image(systemName: aisle.icon)
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }
            }
            
            VStack(spacing: 5) {
                Text(aisle.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let description = aisle.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Statistiques du rayon
                HStack(spacing: 20) {
                    StatisticView(
                        title: "Total",
                        value: "\(filteredMedicines.count)",
                        color: .blue
                    )
                    
                    StatisticView(
                        title: "Critique",
                        value: "\(criticalMedicines.count)",
                        color: .red
                    )
                    
                    StatisticView(
                        title: "Alerte",
                        value: "\(warningMedicines.count)",
                        color: .orange
                    )
                }
                .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var filtersSection: some View {
        VStack(spacing: 15) {
            // Barre de recherche
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Rechercher un médicament...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Effacer") {
                        searchText = ""
                    }
                    .foregroundColor(.accentApp)
                }
            }
            .padding(.horizontal)
            
            // Filtres
            HStack {
                // Filtre par stock
                Picker("Stock", selection: $selectedStockFilter) {
                    ForEach(StockFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(maxWidth: .infinity)
                
                // Tri
                Menu {
                    ForEach(SortOption.allCases) { option in
                        Button(option.rawValue) {
                            sortOption = option
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Trier")
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentApp)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private var medicinesList: some View {
        VStack {
            if filteredMedicines.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 15) {
                        ForEach(sortedMedicines) { medicine in
                            NavigationLink(destination: MedicineDetailView(
                                medicineId: medicine.id,
                                viewModel: viewModelCreator.createMedicineDetailViewModel(medicineId: medicine.id)
                            )) {
                                MedicineCard(medicine: medicine)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadMedicines()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if let aisle = aisle {
                Circle()
                    .fill(aisle.color.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay {
                        if !aisle.icon.isEmpty {
                            Image(systemName: aisle.icon)
                                .font(.system(size: 35))
                                .foregroundColor(aisle.color)
                        }
                    }
                
                Text(searchText.isEmpty ? "Aucun médicament dans ce rayon" : "Aucun résultat")
                    .font(.headline)
                
                Text(searchText.isEmpty 
                     ? "Commencez par ajouter des médicaments au rayon \"\(aisle.name)\""
                     : "Essayez de modifier votre recherche")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                if searchText.isEmpty {
                    PrimaryButton(
                        title: "Ajouter un médicament",
                        icon: "plus"
                    ) {
                        showingAddMedicine = true
                    }
                    .frame(maxWidth: 250)
                    .padding(.top, 10)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Views
    
    private struct StatisticView: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private struct MedicineCard: View {
        let medicine: Medicine
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(medicine.name)
                            .font(.headline)
                            .lineLimit(2)
                        
                        if let form = medicine.form {
                            Text(form)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Indicateur de stock
                    Circle()
                        .fill(stockColor)
                        .frame(width: 12, height: 12)
                }
                
                // Informations de stock
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Stock:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(medicine.currentQuantity) \(medicine.unit)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    // Barre de progression du stock
                    ProgressView(
                        value: Double(max(0, min(medicine.currentQuantity, medicine.maxQuantity))), 
                        total: Double(max(1, medicine.maxQuantity))
                    )
                    .progressViewStyle(LinearProgressViewStyle(tint: stockColor))
                    .scaleEffect(x: 1, y: 0.8)
                }
                
                // Date d'expiration si disponible
                if let expiryDate = medicine.expiryDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(expiryDate))
                            .font(.caption)
                            .foregroundColor(isExpiringSoon(expiryDate) ? .red : .secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        
        private var stockColor: Color {
            if medicine.currentQuantity <= medicine.criticalThreshold {
                return .red
            } else if medicine.currentQuantity <= medicine.warningThreshold {
                return .orange
            } else {
                return .green
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
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
    
    // MARK: - Computed Properties
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
    
    private var medicinesInAisle: [Medicine] {
        viewModel.medicines.filter { $0.aisleId == aisleId }
    }
    
    private var filteredMedicines: [Medicine] {
        var medicines = medicinesInAisle
        
        // Filtre par recherche
        if !searchText.isEmpty {
            medicines = medicines.filter { medicine in
                medicine.name.localizedCaseInsensitiveContains(searchText) ||
                medicine.description?.localizedCaseInsensitiveContains(searchText) == true ||
                medicine.reference?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Filtre par stock
        switch selectedStockFilter {
        case .all:
            break
        case .critical:
            medicines = medicines.filter { $0.currentQuantity <= $0.criticalThreshold }
        case .warning:
            medicines = medicines.filter { $0.currentQuantity <= $0.warningThreshold && $0.currentQuantity > $0.criticalThreshold }
        case .adequate:
            medicines = medicines.filter { $0.currentQuantity > $0.warningThreshold }
        }
        
        return medicines
    }
    
    private var sortedMedicines: [Medicine] {
        filteredMedicines.sorted { medicine1, medicine2 in
            switch sortOption {
            case .nameAscending:
                return medicine1.name < medicine2.name
            case .nameDescending:
                return medicine1.name > medicine2.name
            case .quantityAscending:
                return medicine1.currentQuantity < medicine2.currentQuantity
            case .quantityDescending:
                return medicine1.currentQuantity > medicine2.currentQuantity
            case .expiryDate:
                let date1 = medicine1.expiryDate ?? Date.distantFuture
                let date2 = medicine2.expiryDate ?? Date.distantFuture
                return date1 < date2
            }
        }
    }
    
    private var criticalMedicines: [Medicine] {
        medicinesInAisle.filter { $0.currentQuantity <= $0.criticalThreshold }
    }
    
    private var warningMedicines: [Medicine] {
        medicinesInAisle.filter { $0.currentQuantity <= $0.warningThreshold && $0.currentQuantity > $0.criticalThreshold }
    }
    
    // MARK: - Methods
    
    private func loadData() async {
        await loadAisle()
        await loadMedicines()
    }
    
    private func loadAisle() async {
        do {
            let aisles = try await RealGetAislesUseCase(aisleRepository: aisleRepository).execute()
            aisle = aisles.first { $0.id == aisleId }
        } catch {
            print("Erreur lors du chargement du rayon: \(error)")
        }
        isLoading = false
    }
    
    private func loadMedicines() async {
        await viewModel.fetchMedicines()
    }
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            headerOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            contentOffset = 0
            contentOpacity = 1.0
        }
    }
}

#Preview {
    NavigationView {
        MedicinesByAisleView(aisleId: "aisle-1")
            .withRepositories()
    }
}