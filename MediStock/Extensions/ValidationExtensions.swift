import Foundation

// MARK: - Validation Extensions

extension String {
    
    // MARK: - Email Validation
    
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    // MARK: - Password Validation
    
    var isStrongPassword: Bool {
        // Au moins 8 caractères
        guard self.count >= 8 else { return false }
        
        // Au moins une majuscule
        let uppercaseRegex = ".*[A-Z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", uppercaseRegex).evaluate(with: self) else { return false }
        
        // Au moins une minuscule
        let lowercaseRegex = ".*[a-z]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", lowercaseRegex).evaluate(with: self) else { return false }
        
        // Au moins un chiffre
        let digitRegex = ".*[0-9]+.*"
        guard NSPredicate(format: "SELF MATCHES %@", digitRegex).evaluate(with: self) else { return false }
        
        // Au moins un caractère spécial (optionnel mais recommandé)
        let specialCharRegex = ".*[!@#$%^&*(),.?\":{}|<>]+.*"
        _ = NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: self)
        
        return true // hasSpecialChar est optionnel
    }
    
    var passwordStrength: PasswordStrength {
        if self.count < 6 {
            return .veryWeak
        } else if self.count < 8 {
            return .weak
        } else if isStrongPassword {
            let specialCharRegex = ".*[!@#$%^&*(),.?\":{}|<>]+.*"
            let hasSpecialChar = NSPredicate(format: "SELF MATCHES %@", specialCharRegex).evaluate(with: self)
            return hasSpecialChar ? .veryStrong : .strong
        } else {
            return .medium
        }
    }
    
    // MARK: - Sanitization
    
    var sanitized: String {
        // Supprime les espaces en début/fin
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Supprime les caractères de contrôle
        let controlChars = CharacterSet.controlCharacters
        let components = trimmed.components(separatedBy: controlChars)
        return components.joined()
    }
    
    var sanitizedForFirestore: String {
        // Firestore n'accepte pas certains caractères dans les champs
        let invalidChars = CharacterSet(charactersIn: "/\\#[]")
        let components = self.components(separatedBy: invalidChars)
        return components.joined(separator: "_")
    }
    
    // MARK: - Input Validation
    
    var isValidMedicineName: Bool {
        let sanitized = self.sanitized
        return !sanitized.isEmpty && sanitized.count <= 100
    }
    
    var isValidDosage: Bool {
        let dosageRegex = #"^\d+(\.\d+)?\s*(mg|g|ml|L|UI|mcg|%)?$"#
        return NSPredicate(format: "SELF MATCHES %@", dosageRegex).evaluate(with: self)
    }
    
    var isValidReference: Bool {
        let referenceRegex = #"^[A-Z0-9\-]+$"#
        return NSPredicate(format: "SELF MATCHES %@", referenceRegex).evaluate(with: self)
    }
}

// MARK: - Password Strength Enum

enum PasswordStrength: Int, CaseIterable {
    case veryWeak = 0
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
    
    var label: String {
        switch self {
        case .veryWeak: return "Très faible"
        case .weak: return "Faible"
        case .medium: return "Moyen"
        case .strong: return "Fort"
        case .veryStrong: return "Très fort"
        }
    }
    
    var color: String {
        switch self {
        case .veryWeak: return "red"
        case .weak: return "orange"
        case .medium: return "yellow"
        case .strong: return "green"
        case .veryStrong: return "blue"
        }
    }
}

// MARK: - Number Validation

extension Int {
    var isValidQuantity: Bool {
        return self >= 0 && self <= 99999
    }
    
    var isValidThreshold: Bool {
        return self >= 0 && self <= 9999
    }
}

// MARK: - Date Validation

extension Date {
    var isValidExpiryDate: Bool {
        // La date d'expiration doit être dans le futur
        return self > Date()
    }
    
    var isReasonableExpiryDate: Bool {
        // La date d'expiration ne devrait pas être plus de 10 ans dans le futur
        let tenYearsFromNow = Calendar.current.date(byAdding: .year, value: 10, to: Date()) ?? Date()
        return self > Date() && self < tenYearsFromNow
    }
}