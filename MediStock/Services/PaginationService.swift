import Foundation

// Service simple de pagination pour les listes
class PaginationService<T> {
    private var allItems: [T] = []
    private var currentPage = 0
    private let itemsPerPage: Int
    
    init(itemsPerPage: Int = 20) {
        self.itemsPerPage = itemsPerPage
    }
    
    // Charger tous les éléments
    func loadItems(_ items: [T]) {
        self.allItems = items
        self.currentPage = 0
    }
    
    // Récupérer la page courante
    func getCurrentPageItems() -> [T] {
        let startIndex = currentPage * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, allItems.count)
        
        guard startIndex < allItems.count else {
            return []
        }
        
        return Array(allItems[startIndex..<endIndex])
    }
    
    // Charger la page suivante
    func loadNextPage() -> [T] {
        guard hasNextPage else {
            return getCurrentPageItems()
        }
        
        currentPage += 1
        return getCurrentPageItems()
    }
    
    // Charger la page précédente
    func loadPreviousPage() -> [T] {
        guard hasPreviousPage else {
            return getCurrentPageItems()
        }
        
        currentPage -= 1
        return getCurrentPageItems()
    }
    
    // Aller à une page spécifique
    func goToPage(_ page: Int) -> [T] {
        let maxPage = totalPages - 1
        currentPage = max(0, min(page, maxPage))
        return getCurrentPageItems()
    }
    
    // Propriétés utiles
    var hasNextPage: Bool {
        (currentPage + 1) * itemsPerPage < allItems.count
    }
    
    var hasPreviousPage: Bool {
        currentPage > 0
    }
    
    var totalPages: Int {
        guard !allItems.isEmpty else { return 0 }
        return (allItems.count + itemsPerPage - 1) / itemsPerPage
    }
    
    var currentPageNumber: Int {
        currentPage + 1
    }
    
    var totalItems: Int {
        allItems.count
    }
    
    var currentPageItemsCount: Int {
        getCurrentPageItems().count
    }
    
    // Reset pagination
    func reset() {
        currentPage = 0
    }
    
    // Informations de pagination
    func getPaginationInfo() -> PaginationInfo {
        return PaginationInfo(
            currentPage: currentPageNumber,
            totalPages: totalPages,
            itemsPerPage: itemsPerPage,
            totalItems: totalItems,
            currentPageItems: currentPageItemsCount,
            hasNextPage: hasNextPage,
            hasPreviousPage: hasPreviousPage
        )
    }
}

// Informations de pagination
struct PaginationInfo {
    let currentPage: Int
    let totalPages: Int
    let itemsPerPage: Int
    let totalItems: Int
    let currentPageItems: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
    
    var displayText: String {
        guard totalItems > 0 else {
            return "Aucun élément"
        }
        
        let startItem = (currentPage - 1) * itemsPerPage + 1
        let endItem = min(currentPage * itemsPerPage, totalItems)
        
        return "\(startItem)-\(endItem) sur \(totalItems)"
    }
}

// ViewModel simple pour pagination
@MainActor
class PaginatedListViewModel<T>: ObservableObject {
    @Published var currentItems: [T] = []
    @Published var paginationInfo = PaginationInfo(
        currentPage: 1,
        totalPages: 0,
        itemsPerPage: 20,
        totalItems: 0,
        currentPageItems: 0,
        hasNextPage: false,
        hasPreviousPage: false
    )
    @Published var isLoading = false
    
    private let paginationService: PaginationService<T>
    
    init(itemsPerPage: Int = 20) {
        self.paginationService = PaginationService(itemsPerPage: itemsPerPage)
    }
    
    func loadData(_ items: [T]) {
        isLoading = true
        
        paginationService.loadItems(items)
        currentItems = paginationService.getCurrentPageItems()
        paginationInfo = paginationService.getPaginationInfo()
        
        isLoading = false
    }
    
    func nextPage() {
        guard paginationInfo.hasNextPage else { return }
        
        isLoading = true
        currentItems = paginationService.loadNextPage()
        paginationInfo = paginationService.getPaginationInfo()
        isLoading = false
    }
    
    func previousPage() {
        guard paginationInfo.hasPreviousPage else { return }
        
        isLoading = true
        currentItems = paginationService.loadPreviousPage()
        paginationInfo = paginationService.getPaginationInfo()
        isLoading = false
    }
    
    func goToPage(_ page: Int) {
        isLoading = true
        currentItems = paginationService.goToPage(page - 1)
        paginationInfo = paginationService.getPaginationInfo()
        isLoading = false
    }
    
    func reset() {
        paginationService.reset()
        currentItems = paginationService.getCurrentPageItems()
        paginationInfo = paginationService.getPaginationInfo()
    }
}