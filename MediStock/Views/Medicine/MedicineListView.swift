import SwiftUI

struct MedicineListView: View {
    @StateObject private var viewModel: MedicineStockViewModel
    @State private var searchText = ""
    @State private var selectedAisle: Aisle?
    @State private var sortOption: SortOption = .nameAscending
    @State private var selectedStockFilter: StockFilter = .all
    @State private var isRefreshing = false
    
    init(medicineStockViewModel: MedicineStockViewModel) {
        self._viewModel = StateObject(wrappedValue: medicineStockViewModel)
    }
    
    var body: some View {
        ZStack {
            Color.backgroundApp.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 0) {
                MedicineSearchAndFilterView(
                    searchText: $searchText,
                    selectedAisle: $selectedAisle,
                    sortOption: $sortOption,
                    selectedStockFilter: $selectedStockFilter,
                    aisles: aisleObjects
                )
                
                MedicineContentView(
                    medicines: filteredMedicines,
                    searchText: searchText,
                    selectedAisle: selectedAisle,
                    isRefreshing: isRefreshing,
                    onRefresh: refreshData
                )
            }
            .navigationTitle("Médicaments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    MedicineToolbarButton()
                }
            }
        }
        .onAppear {
            Task {
                await loadInitialData()
            }
        }
    }
}

// MARK: - Computed Properties
extension MedicineListView {
    var filteredMedicines: [Medicine] {
        MedicineListFilter.apply(
            to: viewModel.medicines,
            searchText: searchText,
            selectedAisle: selectedAisle,
            stockFilter: selectedStockFilter,
            sortOption: sortOption
        )
    }
    
    var aisleObjects: [Aisle] {
        viewModel.aisleObjects
    }
    
    private func loadInitialData() async {
        await viewModel.fetchMedicines()
        await viewModel.fetchAisles()
    }
    
    private func refreshData() async {
        isRefreshing = true
        await viewModel.fetchMedicines()
        isRefreshing = false
    }
}

// MARK: - Enums
extension MedicineListView {
    enum SortOption: String, CaseIterable, Identifiable {
        case nameAscending = "Nom (A-Z)"
        case nameDescending = "Nom (Z-A)"
        case stockAscending = "Stock (croissant)"
        case stockDescending = "Stock (décroissant)"
        case expiryDateAscending = "Date d'exp. (proche)"
        case expiryDateDescending = "Date d'exp. (loin)"
        
        var id: String { self.rawValue }
    }
    
    enum StockFilter: String, CaseIterable, Identifiable {
        case all = "Tous"
        case inStock = "En stock"
        case lowStock = "Stock faible"
        case criticalStock = "Stock critique"
        
        var id: String { self.rawValue }
    }
}

// MARK: - Search and Filter View
struct MedicineSearchAndFilterView: View {
    @Binding var searchText: String
    @Binding var selectedAisle: Aisle?
    @Binding var sortOption: MedicineListView.SortOption
    @Binding var selectedStockFilter: MedicineListView.StockFilter
    let aisles: [Aisle]
    
    var body: some View {
        VStack(spacing: 10) {
            MedicineSearchBar(searchText: $searchText)
            MedicineFilterBar(
                selectedAisle: $selectedAisle,
                sortOption: $sortOption,
                selectedStockFilter: $selectedStockFilter,
                aisles: aisles
            )
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// MARK: - Search Bar
struct MedicineSearchBar: View {
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Rechercher un médicament...", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Filter Bar
struct MedicineFilterBar: View {
    @Binding var selectedAisle: Aisle?
    @Binding var sortOption: MedicineListView.SortOption
    @Binding var selectedStockFilter: MedicineListView.StockFilter
    let aisles: [Aisle]
    
    var body: some View {
        HStack {
            MedicineAisleFilter(
                selectedAisle: $selectedAisle,
                aisles: aisles
            )
            
            Spacer()
            
            HStack(spacing: 8) {
                MedicineStockFilter(
                    selectedStockFilter: $selectedStockFilter
                )
                
                MedicineSortMenu(
                    sortOption: $sortOption
                )
            }
        }
    }
}

// MARK: - Aisle Filter
struct MedicineAisleFilter: View {
    @Binding var selectedAisle: Aisle?
    let aisles: [Aisle]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                AisleFilterButton(
                    title: "Tous",
                    isSelected: selectedAisle == nil,
                    backgroundColor: selectedAisle == nil ? Color.accentApp : Color(.systemGray5),
                    foregroundColor: selectedAisle == nil ? .white : .primary
                ) {
                    withAnimation {
                        selectedAisle = nil
                    }
                }
                
                ForEach(aisles) { aisle in
                    AisleFilterButton(
                        title: aisle.name,
                        icon: aisle.icon,
                        isSelected: selectedAisle?.id == aisle.id,
                        backgroundColor: selectedAisle?.id == aisle.id ? aisle.color : Color(.systemGray5),
                        foregroundColor: .white
                    ) {
                        withAnimation {
                            selectedAisle = aisle
                        }
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }
}

struct AisleFilterButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let backgroundColor: Color
    let foregroundColor: Color
    let action: () -> Void
    
    init(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        backgroundColor: Color,
        foregroundColor: Color,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon = icon, !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(15)
        }
    }
}

// MARK: - Stock Filter
struct MedicineStockFilter: View {
    @Binding var selectedStockFilter: MedicineListView.StockFilter
    
    var body: some View {
        Menu {
            ForEach(MedicineListView.StockFilter.allCases) { filter in
                Button(action: {
                    selectedStockFilter = filter
                }) {
                    HStack {
                        Text(filter.rawValue)
                        if selectedStockFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.accentApp)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Sort Menu
struct MedicineSortMenu: View {
    @Binding var sortOption: MedicineListView.SortOption
    
    var body: some View {
        Menu {
            ForEach(MedicineListView.SortOption.allCases) { option in
                Button(action: {
                    sortOption = option
                }) {
                    HStack {
                        Text(option.rawValue)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(.accentApp)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Toolbar Button
struct MedicineToolbarButton: View {
    @EnvironmentObject var appCoordinator: AppCoordinator
    
    var body: some View {
        Button(action: {
            appCoordinator.navigateTo(.medicineForm(nil))
        }) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - Content View
struct MedicineContentView: View {
    let medicines: [Medicine]
    let searchText: String
    let selectedAisle: Aisle?
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    
    var body: some View {
        Group {
            if medicines.isEmpty {
                MedicineEmptyView(
                    hasFilters: hasActiveFilters,
                    searchText: searchText,
                    selectedAisle: selectedAisle
                )
            } else {
                MedicineGridView(
                    medicines: medicines,
                    onRefresh: onRefresh
                )
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedAisle != nil
    }
}

// MARK: - Empty View
struct MedicineEmptyView: View {
    let hasFilters: Bool
    let searchText: String
    let selectedAisle: Aisle?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.8))
            
            Text(hasFilters ? "Aucun médicament trouvé" : "Aucun médicament")
                .font(.headline)
            
            Text(hasFilters ? "Essayez de modifier vos critères de recherche" : "Commencez par ajouter des médicaments à votre stock")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Grid View
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
                    MedicineCard(medicine: medicine)
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

// MARK: - Medicine Card
struct MedicineCard: View {
    let medicine: Medicine
    @EnvironmentObject var appCoordinator: AppCoordinator
    
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
        .onTapGesture {
            appCoordinator.navigateTo(.medicineDetail(medicine.id))
        }
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

// MARK: - Filter Logic
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


#Preview {
    MedicineListView(medicineStockViewModel: AppCoordinator.preview.medicineListViewModel)
}
