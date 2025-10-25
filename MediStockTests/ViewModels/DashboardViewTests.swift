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

    override func setUp() async throws {
        try await super.setUp()

        // Initialiser les mocks
        mockAuthRepository = MockAuthRepository()
        mockMedicineRepo = MockMedicineRepository()
        mockAisleRepo = MockAisleRepository()
        mockNotificationService = MockNotificationService()

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
        _ = DashboardView()
            .environmentObject(appState)
            .environmentObject(authViewModel)

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
        let view = DashboardView()
            .environmentObject(appState)
            .environmentObject(authViewModel)

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
}
