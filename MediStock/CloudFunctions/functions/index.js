/**
 * Cloud Functions Firebase pour validation côté serveur
 * Garantit l'intégrité des données même si la validation client est contournée
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Constantes de validation
const VALIDATION_RULES = {
    maxNameLength: 100,
    maxDescriptionLength: 500,
    maxAislesPerUser: 50,
    maxMedicinesPerUser: 1000,
    colorHexPattern: /^#[0-9A-Fa-f]{6}$/,
    validIcons: [
        'pills', 'pills.fill', 'pills.circle', 'pills.circle.fill',
        'cross.case', 'cross.case.fill', 'bandage', 'bandage.fill',
        'heart', 'heart.fill', 'stethoscope', 'medical.thermometer',
        'syringe', 'syringe.fill', 'drop', 'drop.fill',
        'capsule', 'capsule.fill', 'cross.vial', 'cross.vial.fill',
        'waveform.path.ecg', 'brain.head.profile', 'lungs',
        'figure.walk', 'bed.double', 'wheelchair'
    ]
};

// ============================================
// TRIGGERS FIRESTORE - Validation automatique
// ============================================

/**
 * Trigger onCreate pour les rayons
 * Valide les données lors de la création
 */
exports.validateAisleOnCreate = functions.firestore
    .document('aisles/{aisleId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const aisleId = context.params.aisleId;
        
        try {
            // Validation du nom
            if (!data.name || data.name.trim().length === 0) {
                throw new Error('Le nom du rayon est obligatoire');
            }
            
            if (data.name.length > VALIDATION_RULES.maxNameLength) {
                throw new Error(`Le nom ne peut pas dépasser ${VALIDATION_RULES.maxNameLength} caractères`);
            }
            
            // Validation de la couleur
            if (!VALIDATION_RULES.colorHexPattern.test(data.colorHex)) {
                throw new Error('Format de couleur invalide. Utilisez #RRGGBB');
            }
            
            // Validation de l'icône
            if (!VALIDATION_RULES.validIcons.includes(data.icon)) {
                throw new Error('Icône SF Symbol invalide');
            }
            
            // Vérifier l'unicité du nom pour cet utilisateur
            const duplicates = await db.collection('aisles')
                .where('userId', '==', data.userId)
                .where('name', '==', data.name.trim())
                .get();
            
            if (duplicates.size > 1) {
                throw new Error('Un rayon avec ce nom existe déjà');
            }
            
            // Vérifier la limite de rayons par utilisateur
            const userAislesCount = await db.collection('aisles')
                .where('userId', '==', data.userId)
                .count()
                .get();
            
            if (userAislesCount.data().count > VALIDATION_RULES.maxAislesPerUser) {
                throw new Error(`Limite de ${VALIDATION_RULES.maxAislesPerUser} rayons atteinte`);
            }
            
            // Ajouter les timestamps si manquants
            if (!data.createdAt || !data.updatedAt) {
                await snap.ref.update({
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            
        } catch (error) {
            console.error('Validation error for aisle:', error);
            // Supprimer le document invalide
            await snap.ref.delete();
            // Logger l'erreur pour monitoring
            await logValidationError('aisle', aisleId, error.message);
        }
    });

/**
 * Trigger onCreate pour les médicaments
 * Valide les données lors de la création
 */
exports.validateMedicineOnCreate = functions.firestore
    .document('medicines/{medicineId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();
        const medicineId = context.params.medicineId;
        
        try {
            // Validation du nom
            if (!data.name || data.name.trim().length === 0) {
                throw new Error('Le nom du médicament est obligatoire');
            }
            
            // Validation des quantités
            if (data.currentQuantity < 0) {
                throw new Error('La quantité actuelle ne peut pas être négative');
            }
            
            if (data.maxQuantity < data.currentQuantity) {
                throw new Error('La quantité maximale doit être supérieure ou égale à la quantité actuelle');
            }
            
            // Validation des seuils
            if (data.criticalThreshold >= data.warningThreshold) {
                throw new Error('Le seuil critique doit être inférieur au seuil d\'alerte');
            }
            
            // Validation de la date d'expiration
            if (data.expiryDate) {
                const expiryDate = data.expiryDate.toDate();
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                
                if (expiryDate < today) {
                    throw new Error('La date d\'expiration ne peut pas être dans le passé');
                }
            }
            
            // Vérifier que le rayon existe et appartient à l'utilisateur
            const aisleDoc = await db.collection('aisles').doc(data.aisleId).get();
            if (!aisleDoc.exists) {
                throw new Error('Le rayon sélectionné n\'existe pas');
            }
            
            if (aisleDoc.data().userId !== data.userId) {
                throw new Error('Le rayon n\'appartient pas à cet utilisateur');
            }
            
            // Vérifier la limite de médicaments par utilisateur
            const userMedicinesCount = await db.collection('medicines')
                .where('userId', '==', data.userId)
                .count()
                .get();
            
            if (userMedicinesCount.data().count > VALIDATION_RULES.maxMedicinesPerUser) {
                throw new Error(`Limite de ${VALIDATION_RULES.maxMedicinesPerUser} médicaments atteinte`);
            }
            
            // Ajouter les timestamps si manquants
            if (!data.createdAt || !data.updatedAt) {
                await snap.ref.update({
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            }
            
        } catch (error) {
            console.error('Validation error for medicine:', error);
            // Supprimer le document invalide
            await snap.ref.delete();
            // Logger l'erreur pour monitoring
            await logValidationError('medicine', medicineId, error.message);
        }
    });

/**
 * Trigger onUpdate pour maintenir l'intégrité des timestamps
 */
exports.updateTimestamps = functions.firestore
    .document('{collection}/{docId}')
    .onUpdate(async (change, context) => {
        const collection = context.params.collection;
        
        // Seulement pour les collections pertinentes
        if (!['aisles', 'medicines'].includes(collection)) {
            return null;
        }
        
        const before = change.before.data();
        const after = change.after.data();
        
        // Si updatedAt n'a pas été mis à jour, le faire maintenant
        if (before.updatedAt && after.updatedAt && 
            before.updatedAt.isEqual(after.updatedAt)) {
            
            return change.after.ref.update({
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        
        return null;
    });

/**
 * Trigger onDelete pour nettoyer les références
 */
exports.cleanupOnAisleDelete = functions.firestore
    .document('aisles/{aisleId}')
    .onDelete(async (snap, context) => {
        const aisleId = context.params.aisleId;
        const userId = snap.data().userId;
        
        // Vérifier s'il y a des médicaments dans ce rayon
        const medicines = await db.collection('medicines')
            .where('userId', '==', userId)
            .where('aisleId', '==', aisleId)
            .get();
        
        if (!medicines.empty) {
            console.warn(`Tentative de suppression du rayon ${aisleId} avec ${medicines.size} médicaments`);
            
            // Option 1: Déplacer les médicaments vers un rayon "Non classé"
            // Option 2: Bloquer la suppression (nécessite une approche différente)
            
            // Pour cet exemple, on crée un rayon "Non classé" si nécessaire
            const unclassifiedAisle = await getOrCreateUnclassifiedAisle(userId);
            
            const batch = db.batch();
            medicines.forEach(doc => {
                batch.update(doc.ref, { 
                    aisleId: unclassifiedAisle.id,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp()
                });
            });
            
            await batch.commit();
        }
    });

// ============================================
// FONCTIONS UTILITAIRES
// ============================================

/**
 * Crée ou récupère un rayon "Non classé" pour l'utilisateur
 */
async function getOrCreateUnclassifiedAisle(userId) {
    const query = await db.collection('aisles')
        .where('userId', '==', userId)
        .where('name', '==', 'Non classé')
        .limit(1)
        .get();
    
    if (!query.empty) {
        return { id: query.docs[0].id, ...query.docs[0].data() };
    }
    
    // Créer le rayon "Non classé"
    const docRef = await db.collection('aisles').add({
        name: 'Non classé',
        description: 'Médicaments non classés',
        colorHex: '#808080',
        icon: 'tray',
        userId: userId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { id: docRef.id, name: 'Non classé' };
}

/**
 * Log les erreurs de validation pour monitoring
 */
async function logValidationError(type, documentId, errorMessage) {
    await db.collection('validation_errors').add({
        type: type,
        documentId: documentId,
        errorMessage: errorMessage,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
    });
}

// ============================================
// CALLABLE FUNCTIONS - API pour validation avancée
// ============================================

/**
 * Fonction callable pour valider un rayon avant création
 */
exports.validateAisle = functions.https.onCall(async (data, context) => {
    // Vérifier l'authentification
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }
    
    const { name, colorHex, icon } = data;
    const userId = context.auth.uid;
    
    try {
        // Validation du nom
        if (!name || name.trim().length === 0) {
            throw new Error('Le nom est obligatoire');
        }
        
        // Vérifier l'unicité
        const duplicates = await db.collection('aisles')
            .where('userId', '==', userId)
            .where('name', '==', name.trim())
            .get();
        
        if (!duplicates.empty) {
            throw new Error('Un rayon avec ce nom existe déjà');
        }
        
        // Validation de la couleur
        if (!VALIDATION_RULES.colorHexPattern.test(colorHex)) {
            throw new Error('Format de couleur invalide');
        }
        
        // Validation de l'icône
        if (!VALIDATION_RULES.validIcons.includes(icon)) {
            throw new Error('Icône invalide');
        }
        
        return { valid: true };
        
    } catch (error) {
        throw new functions.https.HttpsError('invalid-argument', error.message);
    }
});

/**
 * Fonction callable pour valider un médicament avant création
 */
exports.validateMedicine = functions.https.onCall(async (data, context) => {
    // Vérifier l'authentification
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Utilisateur non authentifié');
    }
    
    const userId = context.auth.uid;
    
    try {
        // Validations de base
        if (!data.name || data.name.trim().length === 0) {
            throw new Error('Le nom est obligatoire');
        }
        
        if (data.currentQuantity < 0) {
            throw new Error('La quantité ne peut pas être négative');
        }
        
        if (data.criticalThreshold >= data.warningThreshold) {
            throw new Error('Seuils incohérents');
        }
        
        // Vérifier que le rayon existe
        const aisleDoc = await db.collection('aisles').doc(data.aisleId).get();
        if (!aisleDoc.exists || aisleDoc.data().userId !== userId) {
            throw new Error('Rayon invalide');
        }
        
        return { valid: true };
        
    } catch (error) {
        throw new functions.https.HttpsError('invalid-argument', error.message);
    }
});