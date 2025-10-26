import Foundation
import SwiftUI
import Combine

// MARK: - SearchViewModel avec fonctionnalités avancées

@MainActor
class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var searchText = "" {
        didSet {
            if searchText != oldValue {
                searchTextSubject.send(searchText)
            }
        }
    }
    
    @Published var selectedFilters = SearchFilters()
    @Published var sortOption: SortOption = .nameAscending
    @Published var isSearching = false
    @Published var searchResults: [Medicine] = []
    @Published var recentSearches: [String] = []
    @Published var showingFilterSheet = false
    
    // MARK: - Private Properties

    private let medicineRepository: MedicineRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private let searchTextSubject = PassthroughSubject<String, Never>()
    private let userDefaults: UserDefaults

    // MARK: - Initialization

    init(
        medicineRepository: MedicineRepositoryProtocol = MedicineRepository(),
        userDefaults: UserDefaults = .standard
    ) {
        self.medicineRepository = medicineRepository
        self.userDefaults = userDefaults

        setupSearchDebounce()
        loadRecentSearches()
    }
    
    // MARK: - Search Methods
    
    private func setupSearchDebounce() {
        searchTextSubject
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task { [weak self] in
                    await self?.performSearch(searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    func performSearch(_ query: String) async {
        guard !query.isEmpty || hasActiveFilters else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        do {
            // Récupérer tous les médicaments
            let allMedicines = try await medicineRepository.fetchMedicines()
            
            // Appliquer les filtres
            var filteredMedicines = allMedicines
            
            // Filtre par texte
            if !query.isEmpty {
                filteredMedicines = filteredMedicines.filter { medicine in
                    medicine.name.localizedCaseInsensitiveContains(query) ||
                    (medicine.reference?.localizedCaseInsensitiveContains(query) ?? false) ||
                    (medicine.description?.localizedCaseInsensitiveContains(query) ?? false) ||
                    (medicine.dosage?.localizedCaseInsensitiveContains(query) ?? false)
                }
                
                // Sauvegarder la recherche
                addToRecentSearches(query)
            }
            
            // Filtre par rayon
            if let aisleId = selectedFilters.aisleId {
                filteredMedicines = filteredMedicines.filter { $0.aisleId == aisleId }
            }
            
            // Filtre par statut de stock
            if let stockStatus = selectedFilters.stockStatus {
                filteredMedicines = filteredMedicines.filter { $0.stockStatus == stockStatus }
            }
            
            // Filtre par expiration
            if selectedFilters.showExpiringOnly {
                filteredMedicines = filteredMedicines.filter { $0.isExpiringSoon }
            }
            
            if selectedFilters.showExpiredOnly {
                filteredMedicines = filteredMedicines.filter { $0.isExpired }
            }
            
            // Filtre par plage de quantité
            if let minQuantity = selectedFilters.minQuantity {
                filteredMedicines = filteredMedicines.filter { $0.currentQuantity >= minQuantity }
            }
            
            if let maxQuantity = selectedFilters.maxQuantity {
                filteredMedicines = filteredMedicines.filter { $0.currentQuantity <= maxQuantity }
            }
            
            // Appliquer le tri
            searchResults = sortMedicines(filteredMedicines)
            
            // Logger la recherche
            FirebaseService.shared.logSearch(
                searchTerm: query,
                resultCount: searchResults.count
            )
            
        } catch {
            print("Erreur lors de la recherche: \(error)")
            searchResults = []
        }
        
        isSearching = false
    }
    
    // MARK: - Sorting
    
    private func sortMedicines(_ medicines: [Medicine]) -> [Medicine] {
        switch sortOption {
        case .nameAscending:
            return medicines.sorted { $0.name < $1.name }
        case .nameDescending:
            return medicines.sorted { $0.name > $1.name }
        case .quantityAscending:
            return medicines.sorted { $0.currentQuantity < $1.currentQuantity }
        case .quantityDescending:
            return medicines.sorted { $0.currentQuantity > $1.currentQuantity }
        case .expiryDateAscending:
            return medicines.sorted { (m1, m2) in
                guard let d1 = m1.expiryDate, let d2 = m2.expiryDate else {
                    return m1.expiryDate != nil
                }
                return d1 < d2
            }
        case .stockStatus:
            return medicines.sorted { (m1, m2) in
                m1.stockStatus.priority < m2.stockStatus.priority
            }
        }
    }
    
    // MARK: - Filters
    
    func applyFilters() {
        Task {
            await performSearch(searchText)
        }
    }
    
    func clearFilters() {
        selectedFilters = SearchFilters()
        Task {
            await performSearch(searchText)
        }
    }
    
    var hasActiveFilters: Bool {
        selectedFilters.aisleId != nil ||
        selectedFilters.stockStatus != nil ||
        selectedFilters.showExpiringOnly ||
        selectedFilters.showExpiredOnly ||
        selectedFilters.minQuantity != nil ||
        selectedFilters.maxQuantity != nil
    }
    
    var activeFiltersCount: Int {
        var count = 0
        if selectedFilters.aisleId != nil { count += 1 }
        if selectedFilters.stockStatus != nil { count += 1 }
        if selectedFilters.showExpiringOnly { count += 1 }
        if selectedFilters.showExpiredOnly { count += 1 }
        if selectedFilters.minQuantity != nil { count += 1 }
        if selectedFilters.maxQuantity != nil { count += 1 }
        return count
    }
    
    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = userDefaults.stringArray(forKey: "recentSearches") ?? []
    }

    private func addToRecentSearches(_ query: String) {
        guard !query.isEmpty else { return }

        // Retirer si déjà présent
        recentSearches.removeAll { $0 == query }

        // Ajouter en tête
        recentSearches.insert(query, at: 0)

        // Limiter à 10 recherches
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }

        // Sauvegarder
        userDefaults.set(recentSearches, forKey: "recentSearches")
    }

    func clearRecentSearches() {
        recentSearches = []
        userDefaults.removeObject(forKey: "recentSearches")
    }
}

// MARK: - Search Filters Model

struct SearchFilters {
    var aisleId: String?
    var stockStatus: StockStatus?
    var showExpiringOnly = false
    var showExpiredOnly = false
    var minQuantity: Int?
    var maxQuantity: Int?
}

// MARK: - Sort Options

enum SortOption: String, CaseIterable {
    case nameAscending = "Nom (A-Z)"
    case nameDescending = "Nom (Z-A)"
    case quantityAscending = "Quantité ↑"
    case quantityDescending = "Quantité ↓"
    case expiryDateAscending = "Expiration proche"
    case stockStatus = "Statut de stock"
    
    var icon: String {
        switch self {
        case .nameAscending, .nameDescending:
            return "textformat"
        case .quantityAscending, .quantityDescending:
            return "number"
        case .expiryDateAscending:
            return "calendar"
        case .stockStatus:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Stock Status Extension

extension StockStatus {
    var priority: Int {
        switch self {
        case .critical: return 0
        case .warning: return 1
        case .normal: return 2
        }
    }
}