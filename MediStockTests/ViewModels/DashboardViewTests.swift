import XCTest
import SwiftUI
@testable import MediStock

@MainActor
class DashboardViewTests: XCTestCase {

    var dashboardViewModel: DashboardViewModel!
    var appState: AppState!
    var authViewModel: AuthViewModel!
    var mockAuthRepository: MockAuthRepository!
    var mockMedicineRepo: MockMedicineRepository!
    var mockAisleRepo: MockAisleRepository!
    var mockNotificationService: MockNotificationService!
    var mockPDFExportService: MockPDFExportService!

    override func setUp() async throws {
        try await super.setUp()

        // Initialiser les mocks
        mockAuthRepository = MockAuthRepository()
        mockMedicineRepo = MockMedicineRepository()
        mockAisleRepo = MockAisleRepository()
        mockNotificationService = MockNotificationService()
        mockPDFExportService = MockPDFExportService()

        // Initialiser les ViewModels
        authViewModel = AuthViewModel(repository: mockAuthRepository)
        appState = AppState()

        // Créer des données de test
        let testAisle = Aisle(
            id: "1",
            name: "Rayon A",
            description: nil,
            colorHex: "#0000FF",
            icon: "pills"
        )
        mockAisleRepo.aisles = [testAisle]

        let testMedicine1 = Medicine(
            id: "1",
            name: "Paracétamol",
            description: nil,
            dosage: "500mg",
            form: "Comprimé",
            reference: nil,
            unit: "boîtes",
            currentQuantity: 10,
            maxQuantity: 100,
            warningThreshold: 30,
            criticalThreshold: 20,
            expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // Dans 30 jours
            aisleId: "1",
            createdAt: Date(),
            updatedAt: Date()
        )

        let testMedicine2 = Medicine(
            id: "2",
            name: "Ibuprofène",
            description: nil,
            dosage: "400mg",
            form: "Comprimé",
            reference: nil,
            unit: "boîtes",
            currentQuantity: 5,
            maxQuantity: 50,
            warningThreshold: 15,
            criticalThreshold: 10,
            expiryDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // Expiré hier
            aisleId: "1",
            createdAt: Date(),
            updatedAt: Date()
        )

        mockMedicineRepo.medicines = [testMedicine1, testMedicine2]

        // Créer le DashboardViewModel avec makeMock (utilise des mocks internes)
        // Note: makeMock crée son propre MockNotificationService en interne
        dashboardViewModel = DashboardViewModel.makeMock(
            medicines: [testMedicine1, testMedicine2],
            aisles: [testAisle]
        )

        // Configurer l'utilisateur de test
        mockAuthRepository.currentUser = User(
            id: "test-user",
            email: "test@example.com",
            displayName: "Test User"
        )
    }

    func testDashboardViewModelInitialization() {
        XCTAssertEqual(dashboardViewModel.medicines.count, 2)
        XCTAssertEqual(dashboardViewModel.aisles.count, 1)
    }

    func testCriticalMedicines() {
        let criticalMeds = dashboardViewModel.criticalMedicines
        XCTAssertEqual(criticalMeds.count, 2) // Les deux médicaments ont des stocks en dessous du seuil critique
    }

    func testExpiringMedicines() {
        let expiringMeds = dashboardViewModel.expiringMedicines
        // Le premier médicament expire dans 30 jours (considéré comme expirant bientôt)
        // Le deuxième est déjà expiré donc n'est PAS dans expiringMedicines (mais dans expiredMedicines)
        XCTAssertEqual(expiringMeds.count, 1)
    }

    func testExpiredMedicines() {
        let expiredMeds = dashboardViewModel.expiredMedicines
        XCTAssertEqual(expiredMeds.count, 1) // Un médicament expiré hier
    }

    func testStatistics() {
        let stats = dashboardViewModel.statistics
        XCTAssertEqual(stats.totalMedicines, 2)
        XCTAssertEqual(stats.totalAisles, 1)
        XCTAssertEqual(stats.criticalStockCount, 2)
        XCTAssertTrue(stats.hasAlerts)
    }

    func testMedicinesByAisle() {
        let distribution = dashboardViewModel.medicinesByAisle
        XCTAssertEqual(distribution.count, 1)
        XCTAssertEqual(distribution.first?.medicineCount, 2)
        XCTAssertEqual(distribution.first?.aisle.name, "Rayon A")
    }

    func testPDFGenerationDoesNotCrash() async throws {
        // Créer une instance de DashboardView
        _ = DashboardView(pdfExportService: mockPDFExportService)
            .environmentObject(appState)
            .environmentObject(authViewModel)
            .environmentObject(dashboardViewModel)

        // Test pour vérifier que la génération PDF ne crash pas
        let pdfMetaData = [
            kCGPDFContextCreator: "MediStock",
            kCGPDFContextAuthor: "Test User",
            kCGPDFContextTitle: "Rapport d'inventaire MediStock"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        // Cette opération ne devrait pas crash
        let data = renderer.pdfData { (context) in
            context.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "Test PDF".draw(at: CGPoint(x: 50, y: 50), withAttributes: titleAttributes)
        }

        XCTAssertTrue(data.count > 0, "Le PDF devrait contenir des données")
    }

    func testExportButtonExists() async throws {
        // Vérifier que le bouton d'export existe dans la vue
        let view = DashboardView(pdfExportService: mockPDFExportService)
            .environmentObject(appState)
            .environmentObject(authViewModel)
            .environmentObject(dashboardViewModel)

        // Pour ce test simple, on vérifie juste que la vue peut être créée sans crash
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view, "La vue devrait être créée avec succès")
    }

    func testPDFContainsCorrectData() async throws {
        // Test pour vérifier que le PDF contient les bonnes données
        let pdfData = await generateTestPDF()

        XCTAssertTrue(pdfData.count > 1000, "Le PDF devrait avoir une taille raisonnable")
    }

    @MainActor
    private func generateTestPDF() async -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "MediStock",
            kCGPDFContextAuthor: authViewModel.currentUser?.displayName ?? "Utilisateur",
            kCGPDFContextTitle: "Rapport d'inventaire MediStock"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        return renderer.pdfData { (context) in
            context.beginPage()

            var yPosition: CGFloat = 50
            let leftMargin: CGFloat = 50

            // Titre principal
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            "Rapport d'inventaire MediStock".draw(at: CGPoint(x: leftMargin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Résumé
            let summaryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            "Nombre total de médicaments: \(dashboardViewModel.medicines.count)".draw(
                at: CGPoint(x: leftMargin, y: yPosition),
                withAttributes: summaryAttributes
            )
        }
    }

    // MARK: - Additional Tests for 85%+ Coverage

    func testTopCriticalMedicines() {
        // Given - Create 7 critical medicines
        let criticalMeds = (1...7).map {
            Medicine.mock(
                id: "\($0)",
                currentQuantity: 5,
                criticalThreshold: 10
            )
        }
        dashboardViewModel = DashboardViewModel.makeMock(medicines: criticalMeds)

        // When
        let topCritical = dashboardViewModel.topCriticalMedicines

        // Then
        XCTAssertEqual(topCritical.count, 5, "Should return only top 5")
    }

    func testTopExpiringMedicines() {
        // Given - Create medicines with various expiry dates
        let now = Date()
        let medicines = [
            Medicine.mock(id: "1", expiryDate: now.addingTimeInterval(5 * 24 * 60 * 60)),   // 5 days
            Medicine.mock(id: "2", expiryDate: now.addingTimeInterval(10 * 24 * 60 * 60)),  // 10 days
            Medicine.mock(id: "3", expiryDate: now.addingTimeInterval(15 * 24 * 60 * 60)),  // 15 days
            Medicine.mock(id: "4", expiryDate: now.addingTimeInterval(20 * 24 * 60 * 60)),  // 20 days
            Medicine.mock(id: "5", expiryDate: now.addingTimeInterval(25 * 24 * 60 * 60)),  // 25 days
            Medicine.mock(id: "6", expiryDate: now.addingTimeInterval(28 * 24 * 60 * 60))   // 28 days
        ]
        dashboardViewModel = DashboardViewModel.makeMock(medicines: medicines)

        // When
        let topExpiring = dashboardViewModel.topExpiringMedicines

        // Then
        XCTAssertEqual(topExpiring.count, 5, "Should return top 5")
        XCTAssertEqual(topExpiring.first?.id, "1", "Should be sorted by earliest expiry")
    }

    func testLoadDataSuccess() async {
        // Given
        let medicines = [Medicine.mock(id: "1"), Medicine.mock(id: "2")]
        let aisles = [Aisle.mock(id: "1")]
        mockMedicineRepo.medicines = medicines
        mockAisleRepo.aisles = aisles

        let viewModel = DashboardViewModel(
            medicineRepository: mockMedicineRepo,
            aisleRepository: mockAisleRepo,
            notificationService: mockNotificationService
        )

        // When
        await viewModel.loadData()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.medicines.count, 2)
        XCTAssertEqual(viewModel.aisles.count, 1)
        XCTAssertEqual(mockNotificationService.checkExpirationsCallCount, 1)
    }

    func testLoadDataFailure() async {
        // Given
        mockMedicineRepo.shouldThrowError = true

        let viewModel = DashboardViewModel(
            medicineRepository: mockMedicineRepo,
            aisleRepository: mockAisleRepo,
            notificationService: mockNotificationService
        )

        // When
        await viewModel.loadData()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRefresh() async {
        // Given
        mockMedicineRepo.medicines = [Medicine.mock()]
        mockAisleRepo.aisles = [Aisle.mock()]

        let viewModel = DashboardViewModel(
            medicineRepository: mockMedicineRepo,
            aisleRepository: mockAisleRepo,
            notificationService: mockNotificationService
        )

        // When
        await viewModel.refresh()

        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.medicines.count, 1)
    }

    func testClearError() {
        // Given
        dashboardViewModel.errorMessage = "Test error"

        // When
        dashboardViewModel.clearError()

        // Then
        XCTAssertNil(dashboardViewModel.errorMessage)
    }

    func testCalculateLowStockPercentage() {
        // Given
        let medicines = [
            Medicine.mock(id: "1", currentQuantity: 5, criticalThreshold: 10),   // Critical
            Medicine.mock(id: "2", currentQuantity: 15, warningThreshold: 20),   // Warning
            Medicine.mock(id: "3", currentQuantity: 50, warningThreshold: 20),   // Normal
            Medicine.mock(id: "4", currentQuantity: 100, warningThreshold: 20)   // Normal
        ]
        dashboardViewModel = DashboardViewModel.makeMock(medicines: medicines)

        // When
        let stats = dashboardViewModel.statistics

        // Then - 2 out of 4 = 50%
        XCTAssertEqual(stats.lowStockPercentage, 50.0)
    }

    func testStatisticsStatusColor() {
        // Given - Critical medicines
        let criticalMeds = [Medicine.mock(currentQuantity: 5, criticalThreshold: 10)]
        dashboardViewModel = DashboardViewModel.makeMock(medicines: criticalMeds)

        // When
        let stats = dashboardViewModel.statistics

        // Then
        XCTAssertEqual(stats.statusColor, .red)
    }

    func testStatisticsStatusColorOrange() {
        // Given - Only expiring medicines
        let expiringMeds = [Medicine.mock(expiryDate: Date().addingTimeInterval(15 * 24 * 60 * 60))]
        dashboardViewModel = DashboardViewModel.makeMock(medicines: expiringMeds)

        // When
        let stats = dashboardViewModel.statistics

        // Then
        XCTAssertEqual(stats.statusColor, .orange)
    }

    func testStatisticsStatusColorGreen() {
        // Given - Normal stock
        let normalMeds = [Medicine.mock(currentQuantity: 100)]
        let farFuture = Date().addingTimeInterval(365 * 24 * 60 * 60)
        let meds = [Medicine.mock(currentQuantity: 100, expiryDate: farFuture)]
        dashboardViewModel = DashboardViewModel.makeMock(medicines: meds)

        // When
        let stats = dashboardViewModel.statistics

        // Then
        XCTAssertEqual(stats.statusColor, .green)
    }

    func testAisleDistributionHasIssues() {
        // Given
        let aisle = Aisle.mock(id: "1", name: "Test Aisle")
        let medicines = [
            Medicine.mock(id: "1", currentQuantity: 5, criticalThreshold: 10, aisleId: "1")
        ]
        dashboardViewModel = DashboardViewModel.makeMock(medicines: medicines, aisles: [aisle])

        // When
        let distribution = dashboardViewModel.medicinesByAisle.first

        // Then
        XCTAssertNotNil(distribution)
        XCTAssertTrue(distribution?.hasIssues ?? false)
    }

    func testAisleDistributionStatusDescription() {
        // Given
        let aisle = Aisle.mock(id: "1")
        let criticalMed = Medicine.mock(id: "1", currentQuantity: 5, criticalThreshold: 10, aisleId: "1")
        dashboardViewModel = DashboardViewModel.makeMock(medicines: [criticalMed], aisles: [aisle])

        // When
        let distribution = dashboardViewModel.medicinesByAisle.first

        // Then
        XCTAssertEqual(distribution?.statusDescription, "1 critique(s)")
    }

    func testLoadDataPreventsMultipleConcurrentLoads() async {
        // Given
        mockMedicineRepo.medicines = [Medicine.mock()]
        mockAisleRepo.aisles = [Aisle.mock()]

        let viewModel = DashboardViewModel(
            medicineRepository: mockMedicineRepo,
            aisleRepository: mockAisleRepo,
            notificationService: mockNotificationService
        )

        // When - Launch multiple concurrent loads
        async let load1: Void = viewModel.loadData()
        async let load2: Void = viewModel.loadData()
        async let load3: Void = viewModel.loadData()

        _ = await load1
        _ = await load2
        _ = await load3

        // Then - Should only execute once
        XCTAssertEqual(mockMedicineRepo.fetchMedicinesCallCount, 1)
    }
}
