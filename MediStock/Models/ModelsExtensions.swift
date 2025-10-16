import Foundation

// MARK: - Extensions pour ajouter la validation aux modèles

extension Aisle: Validatable {
    func validate() throws {
        // Validation du nom
        let sanitizedName = ValidationHelper.sanitizeName(name)
        guard ValidationHelper.isValidName(sanitizedName) else {
            throw ValidationError.emptyName
        }
        
        // Validation de la couleur
        guard ValidationHelper.isValidColorHex(colorHex) else {
            throw ValidationError.invalidColorFormat(provided: colorHex)
        }
        
        // Validation de l'icône
        guard ValidationHelper.isValidIcon(icon) else {
            throw ValidationError.invalidIcon(provided: icon)
        }
        
        // Validation de la description (optionnelle mais limitée en taille)
        if let desc = description, desc.count > ValidationRules.maxDescriptionLength {
            throw ValidationError.nameTooLong(maxLength: ValidationRules.maxDescriptionLength)
        }
    }
    
    // Helper pour créer une copie avec des champs modifiés
    func copyWith(
        id: String? = nil,
        name: String? = nil,
        description: String?? = nil,
        colorHex: String? = nil,
        icon: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) -> AisleWithTimestamps {
        return AisleWithTimestamps(
            id: id ?? self.id ?? "",
            name: name ?? self.name,
            description: description ?? self.description,
            colorHex: colorHex ?? self.colorHex,
            icon: icon ?? self.icon,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}

extension Medicine: Validatable {
    // Helper pour récupérer l'ID de manière sécurisée
    var safeId: String {
        id ?? ""
    }

    func validate() throws {
        // Validation du nom
        let sanitizedName = ValidationHelper.sanitizeName(name)
        guard ValidationHelper.isValidName(sanitizedName) else {
            throw ValidationError.emptyName
        }
        
        // Validation de l'unité
        guard !unit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.invalidUnit
        }
        
        // Validation des quantités
        guard currentQuantity >= 0 else {
            throw ValidationError.negativeQuantity(field: "quantité actuelle")
        }
        
        guard maxQuantity >= 0 else {
            throw ValidationError.negativeQuantity(field: "quantité maximale")
        }
        
        guard maxQuantity >= currentQuantity else {
            throw ValidationError.invalidMaxQuantity
        }
        
        // Validation des seuils
        guard criticalThreshold >= 0 else {
            throw ValidationError.negativeQuantity(field: "seuil critique")
        }
        
        guard warningThreshold >= 0 else {
            throw ValidationError.negativeQuantity(field: "seuil d'alerte")
        }
        
        guard criticalThreshold < warningThreshold else {
            throw ValidationError.invalidThresholds(critical: criticalThreshold, warning: warningThreshold)
        }
        
        // Validation de la date d'expiration (si présente)
        if let expiry = expiryDate {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let expiryDay = calendar.startOfDay(for: expiry)
            
            if expiryDay < today {
                throw ValidationError.expiredDate(date: expiry)
            }
        }
        
        // Validation de l'ID du rayon (doit être non vide)
        guard !aisleId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField(field: "rayon")
        }
    }
    
    // Helper pour créer une copie avec des champs modifiés
    func copyWith(
        id: String? = nil,
        name: String? = nil,
        description: String?? = nil,
        dosage: String?? = nil,
        form: String?? = nil,
        reference: String?? = nil,
        unit: String? = nil,
        currentQuantity: Int? = nil,
        maxQuantity: Int? = nil,
        warningThreshold: Int? = nil,
        criticalThreshold: Int? = nil,
        expiryDate: Date?? = nil,
        aisleId: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) -> Medicine {
        return Medicine(
            id: id ?? self.id,
            name: name ?? self.name,
            description: description ?? self.description,
            dosage: dosage ?? self.dosage,
            form: form ?? self.form,
            reference: reference ?? self.reference,
            unit: unit ?? self.unit,
            currentQuantity: currentQuantity ?? self.currentQuantity,
            maxQuantity: maxQuantity ?? self.maxQuantity,
            warningThreshold: warningThreshold ?? self.warningThreshold,
            criticalThreshold: criticalThreshold ?? self.criticalThreshold,
            expiryDate: expiryDate ?? self.expiryDate,
            aisleId: aisleId ?? self.aisleId,
            createdAt: createdAt ?? self.createdAt,
            updatedAt: updatedAt ?? self.updatedAt
        )
    }
}

// MARK: - Nouveau modèle Aisle avec timestamps
struct AisleWithTimestamps: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let description: String?
    let colorHex: String
    let icon: String
    let createdAt: Date
    let updatedAt: Date
    
    // Conversion vers l'ancien modèle pour compatibilité
    var toAisle: Aisle {
        var aisle = Aisle(
            name: name,
            description: description,
            colorHex: colorHex,
            icon: icon
        )
        aisle.id = id
        return aisle
    }
}