#!/bin/bash

echo "Déploiement des index Firestore..."

# Vérifier si Firebase CLI est installé
if ! command -v firebase &> /dev/null
then
    echo "Firebase CLI n'est pas installé. Installation..."
    npm install -g firebase-tools
fi

# Déployer uniquement les index
firebase deploy --only firestore:indexes

echo "Déploiement terminé!"
echo ""
echo "IMPORTANT : Les index peuvent prendre quelques minutes à être créés."
echo "En attendant, le code a été modifié pour éviter l'erreur."