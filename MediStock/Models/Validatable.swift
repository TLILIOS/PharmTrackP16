import Foundation

// MARK: - Protocol de validation
protocol Validatable {
    func validate() throws
}

// MARK: - Règles de validation métier
struct ValidationRules {
    // Limites générales
    static let maxNameLength = 100
    static let maxDescriptionLength = 500
    static let maxAislesPerUser = 50
    static let maxMedicinesPerUser = 1000
    
    // Regex patterns
    static let colorHexPattern = "^#[0-9A-Fa-f]{6}$"
    static let namePattern = "^[\\p{L}\\p{N}\\s\\-'.,()]+$" // Lettres, chiffres, espaces, tirets, apostrophes
    
    // Icônes SF Symbols valides (liste partielle pour démonstration)
    static let validIcons = [
        "pills", "pills.fill", "pills.circle", "pills.circle.fill",
        "cross.case", "cross.case.fill", "bandage", "bandage.fill",
        "heart", "heart.fill", "stethoscope", "medical.thermometer",
        "syringe", "syringe.fill", "drop", "drop.fill",
        "capsule", "capsule.fill", "cross.vial", "cross.vial.fill",
        "waveform.path.ecg", "brain.head.profile", "lungs",
        "figure.walk", "bed.double", "wheelchair"
    ]
}

// MARK: - Utilitaires de validation
struct ValidationHelper {
    static func isValidColorHex(_ hex: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: ValidationRules.colorHexPattern)
        let range = NSRange(location: 0, length: hex.utf16.count)
        return regex?.firstMatch(in: hex, options: [], range: range) != nil
    }
    
    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard trimmed.count <= ValidationRules.maxNameLength else { return false }
        
        let regex = try? NSRegularExpression(pattern: ValidationRules.namePattern)
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        return regex?.firstMatch(in: trimmed, options: [], range: range) != nil
    }
    
    static func isValidIcon(_ icon: String) -> Bool {
        return ValidationRules.validIcons.contains(icon)
    }
    
    static func sanitizeName(_ name: String) -> String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}