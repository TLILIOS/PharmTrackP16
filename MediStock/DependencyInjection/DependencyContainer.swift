import Foundation

// MARK: - Dependency Container

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // Services
    lazy var dataService = DataServiceAdapter()
    lazy var authService = AuthService()
    lazy var notificationService = NotificationService()
    lazy var pdfExportService: PDFExportServiceProtocol = PDFExportService()
    
    // Repositories
    lazy var medicineRepository: MedicineRepositoryProtocol = MedicineRepository(dataService: dataService)
    lazy var aisleRepository: AisleRepositoryProtocol = AisleRepository(dataService: dataService)
    lazy var historyRepository: HistoryRepositoryProtocol = HistoryRepository(dataService: dataService)
    
    lazy var authRepository: AuthRepositoryProtocol = AuthRepository(authService: authService)
    
    // ViewModels
    @MainActor
    func makeMedicineListViewModel() -> MedicineListViewModel {
        MedicineListViewModel(
            medicineRepository: medicineRepository,
            historyRepository: historyRepository,
            notificationService: notificationService
        )
    }
    
    @MainActor
    func makeAisleListViewModel() -> AisleListViewModel {
        AisleListViewModel(repository: aisleRepository)
    }
    
    @MainActor
    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(repository: authRepository)
    }
    
    @MainActor
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            medicineRepository: medicineRepository,
            aisleRepository: aisleRepository,
            notificationService: notificationService
        )
    }
    
    @MainActor
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(repository: historyRepository)
    }
}
