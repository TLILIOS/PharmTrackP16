import SwiftUI

// MARK: - SearchView avec filtres avancés

struct SearchView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @EnvironmentObject var aisleListViewModel: AisleListViewModel
    @EnvironmentObject var appState: AppState
    @State private var showingMedicineDetail: Medicine?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                SearchBarView(searchText: $searchViewModel.searchText)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Filtres et tri
                HStack {
                    // Bouton filtres
                    Button(action: { searchViewModel.showingFilterSheet = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filtres")
                            if searchViewModel.activeFiltersCount > 0 {
                                Text("(\(searchViewModel.activeFiltersCount))")
                                    .fontWeight(.semibold)
                            }
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    // Menu de tri
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                searchViewModel.sortOption = option
                                Task {
                                    await searchViewModel.performSearch(searchViewModel.searchText)
                                }
                            }) {
                                Label(option.rawValue, systemImage: option.icon)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Trier")
                        }
                        .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Contenu
                if searchViewModel.isSearching {
                    Spacer()
                    ProgressView("Recherche en cours...")
                        .padding()
                    Spacer()
                } else if searchViewModel.searchText.isEmpty && !searchViewModel.hasActiveFilters {
                    // Recherches récentes
                    RecentSearchesView(
                        recentSearches: searchViewModel.recentSearches,
                        onSelectSearch: { query in
                            searchViewModel.searchText = query
                        },
                        onClearSearches: {
                            searchViewModel.clearRecentSearches()
                        }
                    )
                } else if searchViewModel.searchResults.isEmpty {
                    // Aucun résultat
                    EmptySearchResultsView()
                } else {
                    // Résultats de recherche
                    SearchResultsListView(
                        medicines: searchViewModel.searchResults,
                        onSelectMedicine: { medicine in
                            showingMedicineDetail = medicine
                        }
                    )
                }
            }
            .navigationTitle("Recherche")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $searchViewModel.showingFilterSheet) {
                SearchFiltersView(
                    filters: $searchViewModel.selectedFilters,
                    aisles: aisleListViewModel.aisles,
                    onApply: {
                        searchViewModel.applyFilters()
                    }
                )
            }
            .sheet(item: $showingMedicineDetail) { medicine in
                NavigationStack {
                    MedicineDetailView(medicine: medicine)
                        .environmentObject(appState)
                }
            }
        }
        .trackScreen("Search")
    }
}

// MARK: - SearchBarView

struct SearchBarView: View {
    @Binding var searchText: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Rechercher un médicament...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .accessibilityIdentifier(AccessibilityIdentifiers.medicineSearchField)
            
            if !searchText.isEmpty {
                Button(action: { 
                    searchText = ""
                    isFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonAccessibility(
                    label: "Effacer la recherche",
                    hint: "Efface le texte de recherche"
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.inputBackground)
        .cornerRadius(10)
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - RecentSearchesView

struct RecentSearchesView: View {
    let recentSearches: [String]
    let onSelectSearch: (String) -> Void
    let onClearSearches: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !recentSearches.isEmpty {
                    HStack {
                        Text("Recherches récentes")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Effacer") {
                            onClearSearches()
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal)
                    
                    ForEach(recentSearches, id: \.self) { search in
                        Button(action: { onSelectSearch(search) }) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(search)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Commencez à rechercher")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Vos recherches récentes apparaîtront ici")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                }
            }
            .padding(.top)
        }
    }
}

// MARK: - EmptySearchResultsView

struct EmptySearchResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Aucun résultat")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Essayez avec d'autres mots-clés ou modifiez les filtres")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - SearchResultsListView

struct SearchResultsListView: View {
    let medicines: [Medicine]
    let onSelectMedicine: (Medicine) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(medicines) { medicine in
                    Button(action: { onSelectMedicine(medicine) }) {
                        MedicineRow(medicine: medicine, showExpiry: true)
                            .padding(.horizontal)
                    }
                    .buttonStyle(.plain)
                    
                    if medicine != medicines.last {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - SearchFiltersView

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    let aisles: [Aisle]
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var tempFilters: SearchFilters
    
    init(filters: Binding<SearchFilters>, aisles: [Aisle], onApply: @escaping () -> Void) {
        self._filters = filters
        self.aisles = aisles
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Filtre par rayon
                Section("Rayon") {
                    Picker("Sélectionner un rayon", selection: $tempFilters.aisleId) {
                        Text("Tous les rayons").tag(String?.none)
                        ForEach(aisles) { aisle in
                            Label(aisle.name, systemImage: aisle.icon)
                                .tag(String?.some(aisle.id))
                        }
                    }
                }
                
                // Filtre par statut de stock
                Section("Statut de stock") {
                    Picker("Statut", selection: $tempFilters.stockStatus) {
                        Text("Tous").tag(StockStatus?.none)
                        ForEach([StockStatus.critical, .warning, .normal], id: \.self) { status in
                            HStack {
                                Circle()
                                    .fill(status.statusColor)
                                    .frame(width: 10, height: 10)
                                Text(status.label)
                            }
                            .tag(StockStatus?.some(status))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Filtre par expiration
                Section("Expiration") {
                    Toggle("Médicaments expirant bientôt", isOn: $tempFilters.showExpiringOnly)
                    Toggle("Médicaments expirés uniquement", isOn: $tempFilters.showExpiredOnly)
                }
                
                // Filtre par quantité
                Section("Quantité") {
                    HStack {
                        Text("Min:")
                        TextField("0", value: $tempFilters.minQuantity, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Text("Max:")
                        TextField("9999", value: $tempFilters.maxQuantity, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Bouton réinitialiser
                Section {
                    Button(action: resetFilters) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Réinitialiser les filtres")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Appliquer") {
                        filters = tempFilters
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func resetFilters() {
        tempFilters = SearchFilters()
    }
}

// MARK: - Previews

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
            .environmentObject(AisleListViewModel())
    }
}