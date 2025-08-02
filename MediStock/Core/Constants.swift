import Foundation
import SwiftUI

// MARK: - Constantes Centralisées de l'Application
// Élimine la duplication des valeurs magiques dans le code

enum AppConstants {
    
    // MARK: - Pagination
    
    enum Pagination {
        /// Nombre d'éléments par page par défaut
        static let defaultLimit = 20
        
        /// Nombre maximum d'éléments par requête
        static let maxLimit = 100
        
        /// Nombre d'éléments pour les listes courtes
        static let shortListLimit = 10
    }
    
    // MARK: - Dates et Délais
    
    enum Dates {
        /// Nombre de jours avant expiration pour l'alerte
        static let expiryWarningDaysAhead = 30
        
        /// Nombre maximum d'années dans le futur pour une date d'expiration
        static let maxExpiryYearsAhead = 10
        
        /// Secondes par jour (pour les calculs)
        static let secondsPerDay = 24 * 60 * 60
        
        /// Durée de validité d'une session (24h)
        static let sessionValidityDuration: TimeInterval = 24 * 60 * 60
        
        /// Délai de debounce pour la recherche (millisecondes)
        static let searchDebounceDelay = 300
    }
    
    // MARK: - Limites Métier
    
    enum Limits {
        /// Nombre maximum de médicaments par utilisateur
        static let maxMedicinesPerUser = 1000
        
        /// Nombre maximum de rayons par utilisateur
        static let maxAislesPerUser = 50
        
        /// Stock maximum pour un médicament
        static let maxMedicineStock = 9999
        
        /// Stock critique par défaut
        static let defaultCriticalStock = 10
        
        /// Longueur maximale d'un nom
        static let maxNameLength = 100
        
        /// Longueur maximale d'une description
        static let maxDescriptionLength = 500
    }
    
    // MARK: - Validation
    
    enum Validation {
        /// Pattern regex pour la validation des couleurs hexadécimales
        static let hexColorPattern = "^#[0-9A-Fa-f]{6}$"
        
        /// Caractères autorisés dans les noms
        static let allowedNameCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(.punctuationCharacters)
        
        /// Email regex pattern
        static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    }
    
    // MARK: - UI/UX
    
    enum UI {
        /// Durée des animations par défaut
        static let animationDuration = 0.3
        
        /// Rayon des coins arrondis standard
        static let cornerRadius: CGFloat = 12
        
        /// Espacement standard entre éléments
        static let standardSpacing: CGFloat = 16
        
        /// Taille des icônes dans les listes
        static let listIconSize: CGFloat = 40
        
        /// Hauteur minimale des boutons
        static let buttonMinHeight: CGFloat = 44
        
        /// Opacité pour les éléments désactivés
        static let disabledOpacity = 0.6
    }
    
    // MARK: - Firebase
    
    enum Firebase {
        /// Collections Firestore
        static let medicinesCollection = "medicines"
        static let aislesCollection = "aisles"
        static let historyCollection = "history"
        static let usersCollection = "users"
        
        /// Timeout pour les opérations réseau (secondes)
        static let networkTimeout: TimeInterval = 30
        
        /// Nombre de tentatives en cas d'échec
        static let maxRetryAttempts = 3
    }
    
    // MARK: - Messages Utilisateur
    
    enum Messages {
        static let loadingMedicines = "Chargement des médicaments..."
        static let loadingAisles = "Chargement des rayons..."
        static let savingData = "Enregistrement en cours..."
        static let deletingItem = "Suppression en cours..."
        
        static let errorGeneric = "Une erreur est survenue"
        static let errorNetwork = "Erreur de connexion"
        static let errorAuth = "Erreur d'authentification"
        
        static let successSave = "Enregistrement réussi"
        static let successDelete = "Suppression réussie"
        
        static let confirmDelete = "Êtes-vous sûr de vouloir supprimer cet élément ?"
        static let cannotUndo = "Cette action est irréversible"
    }
    
    // MARK: - Identifiants et Clés
    
    enum Keys {
        /// Clés UserDefaults
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedTheme = "selectedTheme"
        static let preferredLanguage = "preferredLanguage"
        static let lastSyncDate = "lastSyncDate"
        
        /// Clés Keychain
        static let authTokenKey = "auth_token"
        static let biometricAuthKey = "biometric_auth_data"
        
        /// Bundle Identifier
        static var bundleIdentifier: String {
            Bundle.main.bundleIdentifier ?? "com.medistock.app"
        }
    }
    
    // MARK: - Formats
    
    enum Formats {
        /// Format de date pour l'affichage
        static let dateDisplayFormat = "dd/MM/yyyy"
        
        /// Format de date et heure
        static let dateTimeFormat = "dd/MM/yyyy HH:mm"
        
        /// Format pour l'export CSV
        static let csvDateFormat = "yyyy-MM-dd HH:mm:ss"
        
        /// Locale par défaut
        static let defaultLocale = Locale(identifier: "fr_FR")
    }
}

// MARK: - Extension pour un accès simplifié

extension AppConstants {
    /// Vérifie si une date est proche de l'expiration
    static func isNearExpiry(_ date: Date) -> Bool {
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return daysUntilExpiry <= Dates.expiryWarningDaysAhead && daysUntilExpiry >= 0
    }
    
    /// Vérifie si un stock est critique
    static func isCriticalStock(_ stock: Int, criticalThreshold: Int? = nil) -> Bool {
        let threshold = criticalThreshold ?? Limits.defaultCriticalStock
        return stock <= threshold
    }
}

// MARK: - Utilisation

/*
 Remplacement des valeurs magiques dans le code :
 
 AVANT:
 ```swift
 let limit = 20
 let expiryDays = 30
 let maxStock = 9999
 ```
 
 APRÈS:
 ```swift
 let limit = AppConstants.Pagination.defaultLimit
 let expiryDays = AppConstants.Dates.expiryWarningDaysAhead
 let maxStock = AppConstants.Limits.maxMedicineStock
 ```
 
 Avantages:
 - Centralisation de toutes les constantes
 - Modification facile sans chercher dans tout le code
 - Documentation automatique des valeurs
 - Type-safety avec les enums
 */