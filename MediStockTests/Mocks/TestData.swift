import Foundation
@testable import MediStock

// MARK: - Test Data Extensions

extension Medicine {
    static func mock(
        id: String = "medicine-1",
        name: String = "Doliprane",
        description: String? = "Antalgique",
        dosage: String? = "500mg",
        form: String? = "Comprimé",
        reference: String? = "DOL500",
        unit: String = "comprimé",
        currentQuantity: Int = 50,
        maxQuantity: Int = 100,
        warningThreshold: Int = 20,
        criticalThreshold: Int = 10,
        expiryDate: Date? = Date().addingTimeInterval(365 * 24 * 60 * 60),
        aisleId: String = "aisle-1"
    ) -> Medicine {
        Medicine(
            id: id,
            name: name,
            description: description,
            dosage: dosage,
            form: form,
            reference: reference,
            unit: unit,
            currentQuantity: currentQuantity,
            maxQuantity: maxQuantity,
            warningThreshold: warningThreshold,
            criticalThreshold: criticalThreshold,
            expiryDate: expiryDate,
            aisleId: aisleId,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static var mockCritical: Medicine {
        mock(
            id: "medicine-critical",
            name: "Aspirine",
            currentQuantity: 5,
            criticalThreshold: 10
        )
    }
    
    static var mockExpiring: Medicine {
        mock(
            id: "medicine-expiring",
            name: "Ibuprofène",
            expiryDate: Date().addingTimeInterval(15 * 24 * 60 * 60) // 15 jours
        )
    }
    
    static var mockExpired: Medicine {
        mock(
            id: "medicine-expired",
            name: "Paracétamol",
            expiryDate: Date().addingTimeInterval(-1 * 24 * 60 * 60) // Hier
        )
    }
}

extension Aisle {
    static func mock(
        id: String = "aisle-1",
        name: String = "Antalgiques",
        description: String? = "Médicaments contre la douleur",
        colorHex: String = "#0000FF",
        icon: String = "pills"
    ) -> Aisle {
        Aisle(
            id: id,
            name: name,
            description: description,
            colorHex: colorHex,
            icon: icon
        )
    }
}

extension User {
    static func mock(
        id: String = "user-1",
        email: String = "test@example.com",
        displayName: String = "Test User"
    ) -> User {
        User(
            id: id,
            email: email,
            displayName: displayName
        )
    }
}

extension HistoryEntry {
    static func mock(
        id: String = UUID().uuidString,
        medicineId: String = "medicine-1",
        userId: String = "user-1",
        action: String = "Ajout",
        details: String = "Test action",
        timestamp: Date = Date()
    ) -> HistoryEntry {
        HistoryEntry(
            id: id,
            medicineId: medicineId,
            userId: userId,
            action: action,
            details: details,
            timestamp: timestamp
        )
    }
}