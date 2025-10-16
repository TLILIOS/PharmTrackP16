import Foundation
import SwiftUI

// MARK: - DashboardViewModel Refactorisé (MVVM Strict)
// Responsabilité : Gestion du tableau de bord et statistiques

@MainActor
class DashboardViewModel: ObservableObject {

    // MARK: - Published State

    /// Médicaments pour les statistiques
    @Published private(set) var medicines: [Medicine] = []

    /// Rayons pour les statistiques
    @Published private(set) var aisles: [Aisle] = []

    /// État de chargement
    @Published private(set) var isLoading = false

    /// Message d'erreur
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let medicineRepository: MedicineRepositoryProtocol
    private let aisleRepository: AisleRepositoryProtocol
    private let notificationService: NotificationService

    // MARK: - Init

    init(
        medicineRepository: MedicineRepositoryProtocol,
        aisleRepository: AisleRepositoryProtocol,
        notificationService: NotificationService
    ) {
        self.medicineRepository = medicineRepository
        self.aisleRepository = aisleRepository
        self.notificationService = notificationService
    }

    // MARK: - Computed Properties (Statistiques)

    /// Statistiques du dashboard
    var statistics: DashboardStatistics {
        DashboardStatistics(
            totalMedicines: medicines.count,
            totalAisles: aisles.count,
            criticalStockCount: criticalMedicines.count,
            expiringMedicinesCount: expiringMedicines.count,
            lowStockPercentage: calculateLowStockPercentage()
        )
    }

    /// Médicaments en stock critique
    var criticalMedicines: [Medicine] {
        medicines.filter { $0.stockStatus == .critical }
    }

    /// Médicaments expirant bientôt
    var expiringMedicines: [Medicine] {
        medicines.filter { $0.isExpiringSoon && !$0.isExpired }
    }

    /// Médicaments expirés
    var expiredMedicines: [Medicine] {
        medicines.filter { $0.isExpired }
    }

    /// Distribution des médicaments par rayon
    var medicinesByAisle: [AisleDistribution] {
        aisles.compactMap { aisle in
            guard let aisleId = aisle.id else { return nil }
            let medicinesInAisle = medicines.filter { $0.aisleId == aisleId }
            return AisleDistribution(
                aisle: aisle,
                medicineCount: medicinesInAisle.count,
                criticalCount: medicinesInAisle.filter { $0.stockStatus == .critical }.count,
                warningCount: medicinesInAisle.filter { $0.stockStatus == .warning }.count
            )
        }.sorted { $0.medicineCount > $1.medicineCount }
    }

    /// Top 5 médicaments les plus critiques
    var topCriticalMedicines: [Medicine] {
        Array(criticalMedicines.prefix(5))
    }

    /// Top 5 médicaments expirant le plus tôt
    var topExpiringMedicines: [Medicine] {
        Array(expiringMedicines
            .sorted { ($0.expiryDate ?? .distantFuture) < ($1.expiryDate ?? .distantFuture) }
            .prefix(5))
    }

    // MARK: - Actions

    /// Charger les données du dashboard
    func loadData() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Charger en parallèle
            async let medicinesTask = medicineRepository.fetchMedicinesPaginated(
                limit: AppConstants.Pagination.maxLimit,
                refresh: true
            )
            async let aislesTask = aisleRepository.fetchAislesPaginated(
                limit: AppConstants.Pagination.maxLimit,
                refresh: true
            )

            let (loadedMedicines, loadedAisles) = try await (medicinesTask, aislesTask)

            medicines = loadedMedicines
            aisles = loadedAisles

            // Vérifier notifications
            await notificationService.checkExpirations(medicines: medicines)

            // Analytics
            FirebaseService.shared.logScreenView(screenName: "Dashboard")

        } catch {
            errorMessage = error.localizedDescription
            FirebaseService.shared.logError(error, userInfo: [
                "action": "loadDashboardData"
            ])
        }

        isLoading = false
    }

    /// Rafraîchir les données
    func refresh() async {
        await loadData()
    }

    /// Effacer l'erreur
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Helpers

    private func calculateLowStockPercentage() -> Double {
        guard !medicines.isEmpty else { return 0.0 }

        let lowStockCount = medicines.filter {
            $0.stockStatus == .critical || $0.stockStatus == .warning
        }.count

        return Double(lowStockCount) / Double(medicines.count) * 100
    }
}

// MARK: - Models de Support

struct DashboardStatistics {
    let totalMedicines: Int
    let totalAisles: Int
    let criticalStockCount: Int
    let expiringMedicinesCount: Int
    let lowStockPercentage: Double

    var hasAlerts: Bool {
        criticalStockCount > 0 || expiringMedicinesCount > 0
    }

    var statusColor: Color {
        if criticalStockCount > 0 { return .red }
        if expiringMedicinesCount > 0 { return .orange }
        return .green
    }
}

struct AisleDistribution: Identifiable {
    let aisle: Aisle
    let medicineCount: Int
    let criticalCount: Int
    let warningCount: Int

    var id: String { aisle.id ?? "" }

    var hasIssues: Bool {
        criticalCount > 0 || warningCount > 0
    }

    var statusDescription: String {
        if criticalCount > 0 {
            return "\(criticalCount) critique(s)"
        } else if warningCount > 0 {
            return "\(warningCount) en alerte"
        } else {
            return "Normal"
        }
    }
}

// MARK: - Factory

extension DashboardViewModel {
    static func makeDefault() -> DashboardViewModel {
        let container = DependencyContainer.shared
        return DashboardViewModel(
            medicineRepository: container.medicineRepository,
            aisleRepository: container.aisleRepository,
            notificationService: container.notificationService
        )
    }

    static func makeMock(
        medicines: [Medicine] = [],
        aisles: [Aisle] = []
    ) -> DashboardViewModel {
        let mockMedicineRepo = MockMedicineRepository()
        let mockAisleRepo = MockAisleRepository()
        let mockNotif = NotificationService()

        let viewModel = DashboardViewModel(
            medicineRepository: mockMedicineRepo,
            aisleRepository: mockAisleRepo,
            notificationService: mockNotif
        )

        viewModel.medicines = medicines
        viewModel.aisles = aisles

        return viewModel
    }
}
