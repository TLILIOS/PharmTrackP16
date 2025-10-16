import Foundation
import SwiftUI
import UIKit
import FirebaseFirestore

// MARK: - Modèles de domaine (pas de DTOs, direct mapping avec Firestore)

struct Medicine: Identifiable, Codable, Equatable, Hashable {
    var id: String?  // Changé de @DocumentID à var simple car @DocumentID ne fonctionne pas avec doc.data(as:)
    let name: String
    let description: String?
    let dosage: String?
    let form: String?
    let reference: String?
    let unit: String
    var currentQuantity: Int
    let maxQuantity: Int
    let warningThreshold: Int
    let criticalThreshold: Int
    let expiryDate: Date?
    let aisleId: String
    let createdAt: Date
    let updatedAt: Date

    // Computed properties utiles
    var stockStatus: StockStatus {
        if currentQuantity <= criticalThreshold { return .critical }
        if currentQuantity <= warningThreshold { return .warning }
        return .normal
    }

    var isExpiringSoon: Bool {
        guard let expiryDate else { return false }
        return expiryDate <= Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 jours
    }

    var isExpired: Bool {
        guard let expiryDate else { return false }
        return expiryDate <= Date()
    }

    // Custom Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(dosage)
        hasher.combine(form)
        hasher.combine(reference)
        hasher.combine(unit)
        hasher.combine(currentQuantity)
        hasher.combine(maxQuantity)
        hasher.combine(warningThreshold)
        hasher.combine(criticalThreshold)
        hasher.combine(expiryDate)
        hasher.combine(aisleId)
        hasher.combine(createdAt)
        hasher.combine(updatedAt)
    }

    // Custom Equatable implementation
    static func == (lhs: Medicine, rhs: Medicine) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.dosage == rhs.dosage &&
        lhs.form == rhs.form &&
        lhs.reference == rhs.reference &&
        lhs.unit == rhs.unit &&
        lhs.currentQuantity == rhs.currentQuantity &&
        lhs.maxQuantity == rhs.maxQuantity &&
        lhs.warningThreshold == rhs.warningThreshold &&
        lhs.criticalThreshold == rhs.criticalThreshold &&
        lhs.expiryDate == rhs.expiryDate &&
        lhs.aisleId == rhs.aisleId &&
        lhs.createdAt == rhs.createdAt &&
        lhs.updatedAt == rhs.updatedAt
    }

    // Memberwise initializer (needed because of custom decoder)
    init(
        id: String? = nil,
        name: String,
        description: String? = nil,
        dosage: String? = nil,
        form: String? = nil,
        reference: String? = nil,
        unit: String,
        currentQuantity: Int,
        maxQuantity: Int,
        warningThreshold: Int,
        criticalThreshold: Int,
        expiryDate: Date? = nil,
        aisleId: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.dosage = dosage
        self.form = form
        self.reference = reference
        self.unit = unit
        self.currentQuantity = currentQuantity
        self.maxQuantity = maxQuantity
        self.warningThreshold = warningThreshold
        self.criticalThreshold = criticalThreshold
        self.expiryDate = expiryDate
        self.aisleId = aisleId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Custom decoding to handle dosage as Int or String
    enum CodingKeys: String, CodingKey {
        case id, name, description, dosage, form, reference, unit
        case currentQuantity, maxQuantity, warningThreshold, criticalThreshold
        case expiryDate, aisleId, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode dosage with fallback (Int → String conversion)
        let dosageValue: String?
        if let intDosage = try? container.decode(Int.self, forKey: .dosage) {
            dosageValue = String(intDosage)
        } else {
            dosageValue = try? container.decode(String.self, forKey: .dosage)
        }

        // Decode all other fields
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try? container.decode(String.self, forKey: .description)
        self.dosage = dosageValue
        self.form = try? container.decode(String.self, forKey: .form)
        self.reference = try? container.decode(String.self, forKey: .reference)
        self.unit = try container.decode(String.self, forKey: .unit)
        self.currentQuantity = try container.decode(Int.self, forKey: .currentQuantity)
        self.maxQuantity = try container.decode(Int.self, forKey: .maxQuantity)
        self.warningThreshold = try container.decode(Int.self, forKey: .warningThreshold)
        self.criticalThreshold = try container.decode(Int.self, forKey: .criticalThreshold)
        self.expiryDate = try? container.decode(Date.self, forKey: .expiryDate)
        self.aisleId = try container.decode(String.self, forKey: .aisleId)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct Aisle: Identifiable, Codable, Equatable, Hashable {
    var id: String?  // Changé de @DocumentID à var simple car @DocumentID ne fonctionne pas avec doc.data(as:)
    let name: String
    let description: String?
    let colorHex: String
    let icon: String

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    // Hashable implementation for color property
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(description)
        hasher.combine(colorHex)
        hasher.combine(icon)
    }

    static func == (lhs: Aisle, rhs: Aisle) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.colorHex == rhs.colorHex &&
        lhs.icon == rhs.icon
    }
}

struct User: Identifiable, Codable, Equatable {
    let id: String
    let email: String?
    let displayName: String?
}

struct HistoryEntry: Identifiable, Codable, Hashable {
    let id: String
    let medicineId: String
    let userId: String
    let action: String
    let details: String
    let timestamp: Date
}

struct StockHistory: Identifiable, Codable {
    let id: String
    let medicineId: String
    let userId: String
    let type: HistoryType
    let date: Date
    let change: Int
    let previousQuantity: Int
    let newQuantity: Int
    let reason: String?
    
    enum HistoryType: String, Codable {
        case adjustment = "adjustment"
        case addition = "addition"
        case deletion = "deletion"
    }
}

// MARK: - Enums

enum StockStatus {
    case normal, warning, critical

    var statusColor: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    var label: String {
        switch self {
        case .normal: return "Stock normal"
        case .warning: return "Stock faible"
        case .critical: return "Stock critique"
        }
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Email invalide"
        case .wrongPassword: return "Mot de passe incorrect"
        case .userNotFound: return "Utilisateur non trouvé"
        case .emailAlreadyInUse: return "Email déjà utilisé"
        case .weakPassword: return "Mot de passe trop faible"
        case .networkError: return "Erreur réseau"
        case .unknownError(let error): return error.localizedDescription
        }
    }
}

// MARK: - Extensions utilitaires
// Note: Les extensions Color ont été déplacées dans Extensions/Color+Extensions.swift

extension Date {
    var isExpiringSoon: Bool {
        self <= Date().addingTimeInterval(30 * 24 * 60 * 60)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: self)
    }
}