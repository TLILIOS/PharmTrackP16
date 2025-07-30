import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    
    // MARK: - Medicine Accessibility
    
    func medicineAccessibility(_ medicine: Medicine) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(medicineAccessibilityLabel(medicine))
            .accessibilityHint("Toucher deux fois pour voir les détails")
            .accessibilityValue(medicineAccessibilityValue(medicine))
            .accessibilityAddTraits(.isButton)
    }
    
    private func medicineAccessibilityLabel(_ medicine: Medicine) -> String {
        var label = medicine.name
        
        if let dosage = medicine.dosage {
            label += ", \(dosage)"
        }
        
        if let form = medicine.form {
            label += ", \(form)"
        }
        
        return label
    }
    
    private func medicineAccessibilityValue(_ medicine: Medicine) -> String {
        var value = "\(medicine.currentQuantity) \(medicine.unit) disponibles"
        
        switch medicine.stockStatus {
        case .critical:
            value += ", stock critique"
        case .warning:
            value += ", stock faible"
        case .normal:
            value += ", stock normal"
        }
        
        if medicine.isExpiringSoon {
            value += ", expire bientôt"
        }
        
        if medicine.isExpired {
            value += ", expiré"
        }
        
        return value
    }
    
    // MARK: - Aisle Accessibility
    
    func aisleAccessibility(_ aisle: Aisle, medicineCount: Int) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(aisle.name), rayon")
            .accessibilityValue("\(medicineCount) médicaments")
            .accessibilityHint("Toucher deux fois pour voir les médicaments de ce rayon")
            .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Stock Status Accessibility
    
    func stockStatusAccessibility(_ status: StockStatus) -> some View {
        self
            .accessibilityLabel(stockStatusAccessibilityLabel(status))
    }
    
    private func stockStatusAccessibilityLabel(_ status: StockStatus) -> String {
        switch status {
        case .normal:
            return "Stock suffisant"
        case .warning:
            return "Stock faible, attention requise"
        case .critical:
            return "Stock critique, action urgente requise"
        }
    }
    
    // MARK: - Dynamic Type Support
    
    func dynamicTypeAccessibility() -> some View {
        self
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
    
    // MARK: - Form Field Accessibility
    
    func formFieldAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }
    
    // MARK: - Button Accessibility
    
    func buttonAccessibility(label: String, hint: String? = nil, isEnabled: Bool = true) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .disabled(!isEnabled)
    }
}

// MARK: - Accessibility Identifiers

struct AccessibilityIdentifiers {
    // Auth
    static let emailField = "email_field"
    static let passwordField = "password_field"
    static let signInButton = "sign_in_button"
    static let signUpButton = "sign_up_button"
    
    // Navigation
    static let dashboardTab = "dashboard_tab"
    static let medicinesTab = "medicines_tab"
    static let aislesTab = "aisles_tab"
    static let historyTab = "history_tab"
    static let profileTab = "profile_tab"
    
    // Medicine
    static let addMedicineButton = "add_medicine_button"
    static let medicineSearchField = "medicine_search_field"
    static let medicineList = "medicine_list"
    static let adjustStockButton = "adjust_stock_button"
    
    // Common
    static let saveButton = "save_button"
    static let cancelButton = "cancel_button"
    static let deleteButton = "delete_button"
}

// MARK: - Semantic Content

extension View {
    func semanticContentAttribute(_ attribute: SemanticContentAttribute) -> some View {
        self.environment(\.layoutDirection, attribute == .forceRightToLeft ? .rightToLeft : .leftToRight)
    }
}

enum SemanticContentAttribute {
    case unspecified
    case forceLeftToRight
    case forceRightToLeft
}