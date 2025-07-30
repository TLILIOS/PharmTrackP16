#!/bin/bash

# Script de déploiement des Cloud Functions et règles Firestore
# Usage: ./deploy.sh [options]
# Options:
#   --functions   Déploie uniquement les Cloud Functions
#   --rules       Déploie uniquement les règles Firestore
#   --all         Déploie tout (par défaut)

set -e

echo "🚀 Déploiement MediStock Backend"
echo "================================"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "package.json" ]; then
    log_error "Erreur : package.json non trouvé. Exécutez ce script depuis le dossier CloudFunctions."
    exit 1
fi

# Vérifier que Firebase CLI est installé
if ! command -v firebase &> /dev/null; then
    log_error "Firebase CLI n'est pas installé. Installez-le avec : npm install -g firebase-tools"
    exit 1
fi

# Vérifier l'authentification Firebase
log_info "Vérification de l'authentification Firebase..."
if ! firebase projects:list &> /dev/null; then
    log_warning "Vous n'êtes pas connecté à Firebase."
    firebase login
fi

# Installer les dépendances si nécessaire
if [ ! -d "node_modules" ]; then
    log_info "Installation des dépendances..."
    npm install
fi

# Déterminer quoi déployer
DEPLOY_FUNCTIONS=false
DEPLOY_RULES=false

if [ $# -eq 0 ] || [ "$1" = "--all" ]; then
    DEPLOY_FUNCTIONS=true
    DEPLOY_RULES=true
elif [ "$1" = "--functions" ]; then
    DEPLOY_FUNCTIONS=true
elif [ "$1" = "--rules" ]; then
    DEPLOY_RULES=true
else
    log_error "Option invalide : $1"
    echo "Usage: ./deploy.sh [--functions|--rules|--all]"
    exit 1
fi

# Déployer les Cloud Functions
if [ "$DEPLOY_FUNCTIONS" = true ]; then
    log_info "Déploiement des Cloud Functions..."
    
    # Linter le code avant déploiement
    log_info "Vérification du code..."
    npm run lint || {
        log_warning "Des problèmes de lint ont été détectés. Correction automatique..."
        npm run lint:fix
    }
    
    # Déployer les fonctions
    firebase deploy --only functions
    
    if [ $? -eq 0 ]; then
        log_info "Cloud Functions déployées avec succès !"
    else
        log_error "Erreur lors du déploiement des Cloud Functions"
        exit 1
    fi
fi

# Déployer les règles Firestore
if [ "$DEPLOY_RULES" = true ]; then
    log_info "Déploiement des règles Firestore..."
    
    # Vérifier que le fichier firestore.rules existe
    if [ ! -f "firestore.rules" ]; then
        log_error "firestore.rules non trouvé"
        exit 1
    fi
    
    # Déployer les règles
    firebase deploy --only firestore:rules
    
    if [ $? -eq 0 ]; then
        log_info "Règles Firestore déployées avec succès !"
    else
        log_error "Erreur lors du déploiement des règles Firestore"
        exit 1
    fi
fi

# Afficher les URLs des fonctions déployées
if [ "$DEPLOY_FUNCTIONS" = true ]; then
    echo ""
    log_info "URLs des Cloud Functions :"
    firebase functions:list | grep "https://"
fi

echo ""
echo "================================"
log_info "Déploiement terminé avec succès !"
echo ""
echo "Prochaines étapes :"
echo "1. Testez les fonctions avec : firebase emulators:start"
echo "2. Surveillez les logs avec : firebase functions:log"
echo "3. Vérifiez les métriques dans la console Firebase"