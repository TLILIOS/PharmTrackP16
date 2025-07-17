import SwiftUI
import Combine

struct NewMedicineListView: View {
    @Environment(\.viewModelCreator) private var viewModelCreator
    
    @State private var viewModel: ObservableMedicineListViewModel?
    @State private var searchText = ""
    @State private var selectedAisle: Aisle?
    @State private var sortOption: MedicineListView.SortOption = .nameAscending
    @State private var selectedStockFilter: MedicineListView.StockFilter = .all
    @State private var isRefreshing = false
    
    var body: some View {
        mainContent
            .onAppear(perform: setupViewModel)
            .task { await loadInitialData() }
            .onReceive(refreshNotificationPublisher) { _ in
                Task { await viewModel?.fetchMedicines() }
            }
    }
    
    // MARK: - Computed Properties
    private var filteredMedicines: [Medicine] {
        guard let viewModel = viewModel else { return [] }
        
        return MedicineListFilter.apply(
            to: viewModel.medicines,
            searchText: searchText,
            selectedAisle: selectedAisle,
            stockFilter: selectedStockFilter,
            sortOption: sortOption
        )
    }
    
    // MARK: - Methods
    private func loadInitialData() async {
        await viewModel?.fetchMedicines()
        await viewModel?.fetchAisles()
    }
    
    private func refreshData() async {
        isRefreshing = true
        await viewModel?.fetchMedicines()
        isRefreshing = false
    }
}

// MARK: - View Components
extension NewMedicineListView {
    private var mainContent: some View {
        ZStack {
            backgroundView
            contentView
        }
        .navigationTitle("Médicaments")
        .toolbar { toolbarContent }
    }
    
    private var backgroundView: some View {
        Color.backgroundApp.opacity(0.1).ignoresSafeArea()
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            searchAndFilterView
            medicineContentView
        }
    }
    
    private var searchAndFilterView: some View {
        MedicineSearchAndFilterView(
            searchText: $searchText,
            selectedAisle: $selectedAisle,
            sortOption: $sortOption,
            selectedStockFilter: $selectedStockFilter,
            aisles: viewModel?.aisles ?? []
        )
    }
    
    private var medicineContentView: some View {
        MedicineContentView(
            medicines: filteredMedicines,
            searchText: searchText,
            selectedAisle: selectedAisle,
            isRefreshing: isRefreshing,
            onRefresh: refreshData
        )
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: NewMedicineFormView(medicineId: nil)) {
                Image(systemName: "plus")
            }
        }
    }
    
    // MARK: - Publishers
    private var refreshNotificationPublisher: AnyPublisher<Notification, Never> {
        Publishers.MergeMany(
            NotificationCenter.default.publisher(for: Notification.Name("MedicineUpdated")),
            NotificationCenter.default.publisher(for: Notification.Name("StockAdjusted")),
            NotificationCenter.default.publisher(for: Notification.Name("MedicineAdded")),
            NotificationCenter.default.publisher(for: Notification.Name("MedicineDeleted"))
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Methods
    private func setupViewModel() {
        if viewModel == nil {
            viewModel = ObservableMedicineListViewModel(
                medicineRepository: viewModelCreator.medicineRepository,
                aisleRepository: viewModelCreator.aisleRepository
            )
        }
    }
}

// MARK: - Observable ViewModel
@Observable
final class ObservableMedicineListViewModel {
    // MARK: - Published Properties
    var medicines: [Medicine] = []
    var aisles: [Aisle] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Dependencies
    private let medicineRepository: any MedicineRepositoryProtocol
    private let aisleRepository: any AisleRepositoryProtocol
    
    // MARK: - Initializer
    init(
        medicineRepository: any MedicineRepositoryProtocol,
        aisleRepository: any AisleRepositoryProtocol
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
    }
    
    // MARK: - Methods
    @MainActor
    func fetchMedicines() async {
        isLoading = true
        errorMessage = nil
        
        do {
            medicines = try await medicineRepository.getMedicines()
        } catch {
            errorMessage = "Erreur lors du chargement des médicaments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchAisles() async {
        do {
            aisles = try await aisleRepository.getAisles()
        } catch {
            errorMessage = "Erreur lors du chargement des rayons: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func refreshData() async {
        await fetchMedicines()
        await fetchAisles()
    }
}


// MARK: - Updated Medicine Grid View
struct MedicineGridView: View {
    let medicines: [Medicine]
    let onRefresh: () async -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(medicines) { medicine in
                    NavigationLink(destination: NewMedicineDetailView(medicineId: medicine.id)) {
                        MedicineCard(medicine: medicine)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - Medicine Card (reuse existing)
struct MedicineCard: View {
    let medicine: Medicine
    
    private var stockColor: Color {
        if medicine.currentQuantity <= medicine.criticalThreshold {
            return .red
        } else if medicine.currentQuantity <= medicine.warningThreshold {
            return .orange
        } else {
            return .green
        }
    }
    
    private var stockPercentage: Double {
        guard medicine.maxQuantity > 0 else { return 0 }
        return min(1.0, Double(medicine.currentQuantity) / Double(medicine.maxQuantity))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(medicine.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let description = medicine.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(medicine.currentQuantity)")
                            .font(.caption.bold())
                            .foregroundColor(stockColor)
                        
                        Text("/")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(medicine.maxQuantity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(medicine.unit)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ProgressView(value: stockPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: stockColor))
                    .scaleEffect(y: 0.8)
            }
            
            if let expiryDate = medicine.expiryDate {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Exp: \(formatDate(expiryDate))")
                        .font(.caption)
                        .foregroundColor(isExpiringSoon(expiryDate) ? .red : .secondary)
                    
                    Spacer()
                    
                    if isExpiringSoon(expiryDate) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func isExpiringSoon(_ date: Date) -> Bool {
        let thirtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return date <= thirtyDaysFromNow
    }
}

// MARK: - Filter Logic (reuse existing)
struct MedicineListFilter {
    static func apply(
        to medicines: [Medicine],
        searchText: String,
        selectedAisle: Aisle?,
        stockFilter: MedicineListView.StockFilter,
        sortOption: MedicineListView.SortOption
    ) -> [Medicine] {
        var results = medicines
        
        // Filter by aisle
        if let selectedAisle = selectedAisle {
            results = results.filter { $0.aisleId == selectedAisle.id }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            results = results.filter { medicine in
                medicine.name.lowercased().contains(searchText.lowercased()) ||
                (medicine.description ?? "").lowercased().contains(searchText.lowercased())
            }
        }
        
        // Filter by stock status
        switch stockFilter {
        case .all:
            break
        case .inStock:
            results = results.filter { $0.currentQuantity > $0.warningThreshold }
        case .lowStock:
            results = results.filter { 
                $0.currentQuantity <= $0.warningThreshold && $0.currentQuantity > $0.criticalThreshold 
            }
        case .criticalStock:
            results = results.filter { $0.currentQuantity <= $0.criticalThreshold }
        }
        
        // Sort results
        switch sortOption {
        case .nameAscending:
            return results.sorted { $0.name < $1.name }
        case .nameDescending:
            return results.sorted { $0.name > $1.name }
        case .stockAscending:
            return results.sorted { $0.currentQuantity < $1.currentQuantity }
        case .stockDescending:
            return results.sorted { $0.currentQuantity > $1.currentQuantity }
        case .expiryDateAscending:
            return results.sorted { (lhs, rhs) in
                guard let lhsDate = lhs.expiryDate else { return false }
                guard let rhsDate = rhs.expiryDate else { return true }
                return lhsDate < rhsDate
            }
        case .expiryDateDescending:
            return results.sorted { (lhs, rhs) in
                guard let lhsDate = lhs.expiryDate else { return true }
                guard let rhsDate = rhs.expiryDate else { return false }
                return lhsDate > rhsDate
            }
        }
    }
}