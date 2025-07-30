#!/bin/bash

# Script pour corriger la redéclaration de MedicineDestination

echo "🔧 Correction du problème de redéclaration MedicineDestination..."

# 1. Sauvegarder les fichiers originaux
echo "📦 Sauvegarde des fichiers originaux..."
if [ -f "MediStock/Views/MedicineView.swift" ]; then
    cp "MediStock/Views/MedicineView.swift" "MediStock/Views/MedicineView.backup.swift"
    echo "✅ MedicineView.swift sauvegardé"
fi

# 2. Appliquer la version corrigée
echo "🔄 Application de la version corrigée..."
if [ -f "MediStock/Views/MedicineViewCorrected.swift" ]; then
    cp "MediStock/Views/MedicineViewCorrected.swift" "MediStock/Views/MedicineView.swift"
    echo "✅ MedicineView.swift corrigé"
fi

# 3. Supprimer la redéclaration dans le dossier MediStocks (avec 's')
echo "🗑️ Suppression de la redéclaration dans MediStocks/Views/DashboardView.swift..."
if [ -f "MediStocks/Views/DashboardView.swift" ]; then
    # Supprimer les lignes 228-233 qui contiennent la redéclaration
    sed -i '' '228,233d' "MediStocks/Views/DashboardView.swift"
    echo "✅ Redéclaration supprimée de DashboardView.swift"
fi

# 4. Vérifier qu'il n'y a plus de redéclarations
echo "🔍 Vérification des redéclarations..."
echo "Recherche de 'enum MedicineDestination' dans le projet:"
grep -r "enum MedicineDestination" MediStock/ MediStocks/ 2>/dev/null | grep -v ".backup"

echo ""
echo "✅ Correction terminée!"
echo ""
echo "📝 Résumé:"
echo "- MedicineView.swift a été remplacé par la version corrigée"
echo "- La redéclaration dans MediStocks/Views/DashboardView.swift a été supprimée"
echo "- Les sauvegardes sont disponibles avec l'extension .backup"
echo ""
echo "🎯 Prochaine étape: Compiler le projet dans Xcode pour vérifier que l'erreur est résolue"