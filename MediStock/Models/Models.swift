import Foundation
import SwiftUI
import UIKit

// MARK: - Modèles de domaine (pas de DTOs, direct mapping avec Firestore)

struct Medicine: Identifiable, Codable, Equatable, Hashable {
    let id: String
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
}

struct Aisle: Identifiable, Codable, Equatable, Hashable {
    let id: String
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

extension Color {
    init?(hex: String) {
        let r, g, b: Double
        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])
        
        guard hexColor.count == 6,
              let hexNumber = Int(hexColor, radix: 16) else { return nil }
        
        r = Double((hexNumber & 0xff0000) >> 16) / 255
        g = Double((hexNumber & 0x00ff00) >> 8) / 255
        b = Double((hexNumber & 0x0000ff)) / 255
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "#000000" }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

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