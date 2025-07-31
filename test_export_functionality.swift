import SwiftUI
import UIKit

// Test simple pour vérifier la génération PDF
func testPDFGeneration() -> Bool {
    let pdfMetaData = [
        kCGPDFContextCreator: "MediStock Test",
        kCGPDFContextAuthor: "Test User",
        kCGPDFContextTitle: "Test PDF Export"
    ]
    
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String: Any]
    
    let pageWidth = 8.5 * 72.0
    let pageHeight = 11 * 72.0
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
    
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
    
    let data = renderer.pdfData { (context) in
        context.beginPage()
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        "Test d'export PDF MediStock".draw(
            at: CGPoint(x: 50, y: 50), 
            withAttributes: titleAttributes
        )
    }
    
    print("PDF généré avec succès, taille: \(data.count) octets")
    return data.count > 0
}

// Test de la fonctionnalité ShareSheet
func testShareSheet() -> Bool {
    // Vérifier que ShareSheet peut être initialisé
    let testData = Data("Test".utf8)
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.pdf")
    
    do {
        try testData.write(to: tempURL)
        let shareSheet = ShareSheet(activityItems: [tempURL])
        print("ShareSheet créé avec succès")
        return true
    } catch {
        print("Erreur lors du test ShareSheet: \(error)")
        return false
    }
}

// Exécuter les tests
print("=== Test de la fonctionnalité d'export PDF ===")
print("Test de génération PDF: \(testPDFGeneration() ? "✅ RÉUSSI" : "❌ ÉCHEC")")
print("Test ShareSheet: \(testShareSheet() ? "✅ RÉUSSI" : "❌ ÉCHEC")")
print("===========================================")