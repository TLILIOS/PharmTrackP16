import Foundation

// MARK: - Dependency Container

@MainActor
class DependencyContainer {
    static let shared = DependencyContainer()

    private init() {}

    // MARK: - Modular Data Services (New Architecture)

    /// Service dédié à la gestion de l'historique
    lazy var historyService = HistoryDataService()

    /// Service dédié à la gestion des médicaments
    lazy var medicineService = MedicineDataService(historyService: historyService)

    /// Service dédié à la gestion des rayons
    lazy var aisleService = AisleDataService(historyService: historyService)

    // MARK: - Other Services

    lazy var authService = AuthService()
    lazy var notificationService = NotificationService()
    lazy var pdfExportService: PDFExportServiceProtocol = PDFExportService()
    lazy var networkMonitor = NetworkMonitor()

    // MARK: - Repositories (Using Modular Services)

    lazy var medicineRepository: MedicineRepositoryProtocol = MedicineRepository(medicineService: medicineService)
    lazy var aisleRepository: AisleRepositoryProtocol = AisleRepository(aisleService: aisleService)
    lazy var historyRepository: HistoryRepositoryProtocol = HistoryRepository(historyService: historyService)

    lazy var authRepository: AuthRepositoryProtocol = AuthRepository(authService: authService)
    
    // ViewModels
    @MainActor
    func makeMedicineListViewModel() -> MedicineListViewModel {
        MedicineListViewModel(
            medicineRepository: medicineRepository,
            historyRepository: historyRepository,
            notificationService: notificationService,
            networkMonitor: networkMonitor
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
            notificationService: notificationService,
            networkMonitor: networkMonitor
        )
    }

    @MainActor
    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(repository: historyRepository)
    }
}
