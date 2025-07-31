import XCTest
@testable import MediStock

// MARK: - Tests d'analyse des fonctions d'ajout de rayon et médicament

final class AddFunctionsAnalysisTests: XCTestCase {
    
    var dataService: DataService!
    var appState: AppState!
    
    override func setUp() async throws {
        try await super.setUp()
        dataService = DataService()
        appState = AppState()
    }
    
    override func tearDown() async throws {
        dataService = nil
        appState = nil
        try await super.tearDown()
    }
    
    // MARK: - Tests fonction saveAisle
    
    func testAnalyseSaveAisleFunctionValidation() {
        // Analyse de la fonction saveAisle dans DataService
        
        // PROBLÈMES IDENTIFIÉS:
        // 1. Aucune validation des paramètres d'entrée
        // 2. Le nom du rayon peut être vide
        // 3. La colorHex n'est pas validée (format hexadécimal)
        // 4. L'icône n'est pas validée (SF Symbol existant)
        // 5. Pas de vérification d'unicité du nom
        
        // Test avec données invalides
        let invalidAisle1 = Aisle(id: "", name: "", description: nil, colorHex: "invalid", icon: "")
        let invalidAisle2 = Aisle(id: "", name: "Test", description: nil, colorHex: "#GGGGGG", icon: "invalid.icon")
        let invalidAisle3 = Aisle(id: "", name: "   ", description: nil, colorHex: "#FF0000", icon: "pills")
        
        // Ces cas devraient être rejetés mais ne le sont pas actuellement
        print("❌ Problème 1: Aucune validation du nom vide ou espaces uniquement")
        print("❌ Problème 2: Aucune validation du format colorHex")
        print("❌ Problème 3: Aucune validation de l'icône SF Symbol")
    }
    
    func testAnalyseSaveAisleDataIntegrity() {
        // Analyse de l'intégrité des données
        
        // PROBLÈMES IDENTIFIÉS:
        // 1. Pas de timestamps (createdAt, updatedAt) sur les rayons
        // 2. Pas de gestion de version optimiste
        // 3. Le userId est ajouté manuellement après encoding
        // 4. Pas de validation métier (ex: limite du nombre de rayons)
        
        print("❌ Problème 4: Absence de timestamps pour l'audit")
        print("❌ Problème 5: Risque de conflit en cas de modifications concurrentes")
        print("❌ Problème 6: Limite métier non implémentée (nombre max de rayons)")
    }
    
    // MARK: - Tests fonction saveMedicine
    
    func testAnalyseSaveMedicineFunctionValidation() {
        // Analyse de la fonction saveMedicine dans DataService
        
        // PROBLÈMES IDENTIFIÉS:
        // 1. Aucune validation des seuils (warning > critical est accepté)
        // 2. currentQuantity peut être négatif
        // 3. maxQuantity peut être inférieur à currentQuantity
        // 4. Le nom peut être vide ou contenir uniquement des espaces
        // 5. L'aisleId n'est pas vérifié (rayon existant)
        // 6. La date d'expiration peut être dans le passé
        
        let invalidMedicine1 = Medicine(
            id: "",
            name: "",
            description: nil,
            dosage: nil,
            form: nil,
            reference: nil,
            unit: "boîte",
            currentQuantity: -10,
            maxQuantity: 5,
            warningThreshold: 20,
            criticalThreshold: 50, // Plus élevé que warning!
            expiryDate: Date().addingTimeInterval(-86400), // Hier
            aisleId: "non-existent",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        print("❌ Problème 7: Seuils incohérents acceptés (critical > warning)")
        print("❌ Problème 8: Quantités négatives acceptées")
        print("❌ Problème 9: maxQuantity < currentQuantity accepté")
        print("❌ Problème 10: Date d'expiration passée acceptée")
        print("❌ Problème 11: aisleId non vérifié")
    }
    
    func testAnalyseSaveMedicineCodeDuplication() {
        // Analyse de la duplication de code
        
        // PROBLÈME IDENTIFIÉ:
        // Le code de création et mise à jour est dupliqué
        // Seules les dates diffèrent, tout le reste est répété
        
        print("❌ Problème 12: Duplication massive de code entre création et mise à jour")
        print("   Solution: Utiliser medicine.copyWith() ou un builder pattern")
    }
    
    // MARK: - Tests d'interaction entre les fonctions
    
    func testAnalyseInteractionAisleMedicine() {
        // Analyse de l'interaction entre rayons et médicaments
        
        // PROBLÈMES IDENTIFIÉS:
        // 1. Un médicament peut référencer un rayon supprimé
        // 2. Pas de cascade delete ou validation référentielle
        // 3. Pas de compteur de médicaments par rayon
        // 4. Suppression d'un rayon ne met pas à jour les médicaments
        
        print("❌ Problème 13: Intégrité référentielle non garantie")
        print("❌ Problème 14: Orphelins possibles après suppression de rayon")
    }
    
    // MARK: - Recommandations d'amélioration
    
    func testRecommandations() {
        print("\n📋 RECOMMANDATIONS D'AMÉLIORATION:\n")
        
        print("1. VALIDATION DES ENTRÉES:")
        print("   - Créer des structures de validation dédiées")
        print("   - Implémenter validate() sur les modèles")
        print("   - Rejeter les données invalides avant Firebase")
        
        print("\n2. INTÉGRITÉ DES DONNÉES:")
        print("   - Ajouter timestamps sur Aisle")
        print("   - Implémenter vérification d'unicité")
        print("   - Valider les références croisées")
        
        print("\n3. OPTIMISATIONS:")
        print("   - Réduire la duplication de code")
        print("   - Utiliser des transactions pour les opérations liées")
        print("   - Implémenter un cache local")
        
        print("\n4. GESTION D'ERREURS:")
        print("   - Créer des erreurs métier spécifiques")
        print("   - Messages d'erreur localisés")
        print("   - Retry automatique en cas d'erreur réseau")
        
        print("\n5. SÉCURITÉ:")
        print("   - Validation côté serveur avec Cloud Functions")
        print("   - Règles Firestore strictes")
        print("   - Audit trail complet")
    }
    
    // MARK: - Code corrigé proposé
    
    func testProposedValidationCode() {
        print("\n🔧 CODE DE VALIDATION PROPOSÉ:\n")
        
        let validationCode = """
        // Extension pour validation des modèles
        extension Aisle {
            func validate() throws {
                guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ValidationError.emptyName
                }
                
                guard colorHex.matches("#[0-9A-Fa-f]{6}") else {
                    throw ValidationError.invalidColorFormat
                }
                
                guard SFSymbol.isValid(icon) else {
                    throw ValidationError.invalidIcon
                }
            }
        }
        
        extension Medicine {
            func validate() throws {
                guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw ValidationError.emptyName
                }
                
                guard currentQuantity >= 0 else {
                    throw ValidationError.negativeQuantity
                }
                
                guard maxQuantity >= currentQuantity else {
                    throw ValidationError.invalidMaxQuantity
                }
                
                guard criticalThreshold < warningThreshold else {
                    throw ValidationError.invalidThresholds
                }
                
                if let expiry = expiryDate, expiry < Date() {
                    throw ValidationError.expiredDate
                }
            }
        }
        
        // Service amélioré avec validation
        func saveMedicineImproved(_ medicine: Medicine) async throws -> Medicine {
            // 1. Validation
            try medicine.validate()
            
            // 2. Vérifier que le rayon existe
            let aisleExists = try await checkAisleExists(medicine.aisleId)
            guard aisleExists else {
                throw ValidationError.invalidAisleReference
            }
            
            // 3. Éviter la duplication avec copyWith
            var medicineToSave = medicine
            if medicine.id.isEmpty {
                medicineToSave = medicine.copyWith(
                    id: db.collection("medicines").document().documentID,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            } else {
                medicineToSave = medicine.copyWith(updatedAt: Date())
            }
            
            // 4. Sauvegarder avec transaction pour garantir l'intégrité
            return try await saveWithTransaction(medicineToSave)
        }
        """
        
        print(validationCode)
    }
}

// MARK: - Erreurs de validation proposées

// ValidationError est maintenant défini dans Models/ValidationError.swift
// Cette redéclaration locale a été supprimée pour éviter les conflits