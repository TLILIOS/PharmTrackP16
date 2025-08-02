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

// MARK: - Test Data Collections

struct TestData {
    static let mockAisles: [Aisle] = [
        .mock(id: "1", name: "Antalgiques", colorHex: "#FF0000", icon: "pills"),
        .mock(id: "2", name: "Antibiotiques", colorHex: "#00FF00", icon: "cross.case"),
        .mock(id: "3", name: "Anti-inflammatoires", colorHex: "#0000FF", icon: "bandage"),
        .mock(id: "4", name: "Vitamines", colorHex: "#FFFF00", icon: "heart"),
        .mock(id: "5", name: "Antiseptiques", colorHex: "#FF00FF", icon: "drop"),
        .mock(id: "6", name: "Cardiologie", colorHex: "#00FFFF", icon: "heart.fill"),
        .mock(id: "7", name: "Dermatologie", colorHex: "#FFA500", icon: "bandage.fill"),
        .mock(id: "8", name: "Ophtalmologie", colorHex: "#800080", icon: "eye"),
        .mock(id: "9", name: "ORL", colorHex: "#FFC0CB", icon: "ear"),
        .mock(id: "10", name: "Pédiatrie", colorHex: "#008000", icon: "figure.walk"),
        // Plus de rayons pour tester la pagination
        .mock(id: "11", name: "Neurologie", colorHex: "#000080", icon: "brain.head.profile"),
        .mock(id: "12", name: "Pneumologie", colorHex: "#808080", icon: "lungs"),
        .mock(id: "13", name: "Gastro-entérologie", colorHex: "#800000", icon: "pills.circle"),
        .mock(id: "14", name: "Rhumatologie", colorHex: "#008080", icon: "bandage"),
        .mock(id: "15", name: "Endocrinologie", colorHex: "#808000", icon: "drop.fill"),
        .mock(id: "16", name: "Urologie", colorHex: "#C0C0C0", icon: "drop"),
        .mock(id: "17", name: "Gynécologie", colorHex: "#FFD700", icon: "heart"),
        .mock(id: "18", name: "Psychiatrie", colorHex: "#4B0082", icon: "brain.head.profile"),
        .mock(id: "19", name: "Anesthésie", colorHex: "#FF6347", icon: "syringe"),
        .mock(id: "20", name: "Urgences", colorHex: "#40E0D0", icon: "cross.case.fill"),
        .mock(id: "21", name: "Gériatrie", colorHex: "#EE82EE", icon: "figure.walk"),
        .mock(id: "22", name: "Oncologie", colorHex: "#F0E68C", icon: "cross.vial"),
        .mock(id: "23", name: "Radiologie", colorHex: "#B22222", icon: "waveform.path.ecg"),
        .mock(id: "24", name: "Chirurgie", colorHex: "#5F9EA0", icon: "bandage"),
        .mock(id: "25", name: "Réanimation", colorHex: "#D2691E", icon: "heart.fill"),
        .mock(id: "26", name: "Soins palliatifs", colorHex: "#FF1493", icon: "bed.double"),
        .mock(id: "27", name: "Médecine sportive", colorHex: "#00CED1", icon: "figure.walk"),
        .mock(id: "28", name: "Allergologie", colorHex: "#FF8C00", icon: "drop"),
        .mock(id: "29", name: "Immunologie", colorHex: "#8B008B", icon: "cross.vial.fill"),
        .mock(id: "30", name: "Hématologie", colorHex: "#556B2F", icon: "drop.fill")
    ]
    
    static let mockMedicines: [Medicine] = [
        .mock(id: "1", name: "Doliprane 500mg", aisleId: "1"),
        .mock(id: "2", name: "Aspirine 100mg", aisleId: "1"),
        .mock(id: "3", name: "Ibuprofène 400mg", aisleId: "3"),
        .mock(id: "4", name: "Amoxicilline 1g", aisleId: "2"),
        .mock(id: "5", name: "Vitamine C", aisleId: "4")
    ]
}