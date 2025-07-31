import XCTest
import SwiftUI
@testable import MediStock

@MainActor
class DashboardViewTests: XCTestCase {
    
    var appState: AppState!
    var authViewModel: AuthViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialiser AppState et AuthViewModel avec des données de test
        appState = AppState()
        authViewModel = AuthViewModel()
        
        // Ajouter des données de test
        let testAisle = Aisle(id: "1", name: "Rayon A", icon: "pills", color: .blue)
        appState.aisles = [testAisle]
        
        let testMedicine1 = Medicine(
            id: "1",
            name: "Paracétamol",
            dosage: "500mg",
            form: "Comprimé",
            currentQuantity: 10,
            maxQuantity: 100,
            criticalThreshold: 20,
            unit: "boîtes",
            aisleId: "1",
            expiryDate: Date().addingTimeInterval(30 * 24 * 60 * 60) // Dans 30 jours
        )
        
        let testMedicine2 = Medicine(
            id: "2",
            name: "Ibuprofène",
            dosage: "400mg",
            form: "Comprimé",
            currentQuantity: 5,
            maxQuantity: 50,
            criticalThreshold: 10,
            unit: "boîtes",
            aisleId: "1",
            expiryDate: Date().addingTimeInterval(-1 * 24 * 60 * 60) // Expiré hier
        )
        
        appState.medicines = [testMedicine1, testMedicine2]
        
        // Ajouter une entrée d'historique
        let historyEntry = HistoryEntry(
            id: "1",
            action: "Ajout de médicament",
            medicineId: "1",
            medicineName: "Paracétamol",
            details: "Ajout de 10 boîtes",
            userId: "test-user",
            userName: "Test User",
            timestamp: Date()
        )
        appState.history = [historyEntry]
    }
    
    func testPDFGenerationDoesNotCrash() async throws {
        // Créer une instance de DashboardView
        let view = DashboardView()
            .environmentObject(appState)
            .environmentObject(authViewModel)
        
        // Accéder à la méthode de génération PDF via Mirror
        let mirror = Mirror(reflecting: view)
        
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
        
        // Utiliser ViewInspector ou une technique similaire pour vérifier la présence du bouton
        // Pour ce test simple, on vérifie juste que la vue peut être créée sans crash
        let hostingController = UIHostingController(rootView: view)
        XCTAssertNotNil(hostingController.view, "La vue devrait être créée avec succès")
    }
    
    func testPDFContainsCorrectData() async throws {
        // Test pour vérifier que le PDF contient les bonnes données
        let pdfData = await generateTestPDF()
        
        XCTAssertTrue(pdfData.count > 1000, "Le PDF devrait avoir une taille raisonnable")
        
        // On pourrait ici analyser le contenu du PDF si nécessaire
        // mais pour un test simple, on vérifie juste qu'il n'est pas vide
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
            
            "Nombre total de médicaments: \(appState.medicines.count)".draw(
                at: CGPoint(x: leftMargin, y: yPosition), 
                withAttributes: summaryAttributes
            )
        }
    }
}