#!/bin/bash

echo "🧹 Nettoyage des duplications et redéclarations..."
echo ""

# 1. Supprimer le répertoire MediStocks (avec 's')
if [ -d "MediStocks/" ]; then
    echo "🗑️ Suppression du répertoire dupliqué MediStocks/..."
    rm -rf MediStocks/
    echo "✅ MediStocks/ supprimé"
fi

# 2. Supprimer les fichiers de sauvegarde
echo ""
echo "🗑️ Suppression des fichiers de sauvegarde..."
find MediStock -name "*.backup.swift" -type f -delete
echo "✅ Fichiers .backup.swift supprimés"

# 3. Supprimer le fichier MedicineViewCorrected.swift
if [ -f "MediStock/Views/MedicineViewCorrected.swift" ]; then
    rm "MediStock/Views/MedicineViewCorrected.swift"
    echo "✅ MedicineViewCorrected.swift supprimé"
fi

# 4. Gérer le conflit entre Views/ et FixedViews/
echo ""
echo "📂 Résolution des conflits entre Views/ et FixedViews/..."

# Option : Utiliser les versions FixedViews qui sont plus récentes et corrigées
# Sauvegarder d'abord les versions actuelles
mkdir -p MediStock/Views/old_versions

# MedicineListView
if [ -f "MediStock/Views/MedicineView.swift" ] && [ -f "MediStock/Views/FixedViews/MedicineListView.swift" ]; then
    mv "MediStock/Views/MedicineView.swift" "MediStock/Views/old_versions/"
    mv "MediStock/Views/FixedViews/MedicineListView.swift" "MediStock/Views/MedicineView.swift"
    echo "✅ MedicineListView : version FixedViews utilisée"
fi

# AisleListView
if [ -f "MediStock/Views/AisleView.swift" ] && [ -f "MediStock/Views/FixedViews/AisleListView.swift" ]; then
    mv "MediStock/Views/AisleView.swift" "MediStock/Views/old_versions/"
    mv "MediStock/Views/FixedViews/AisleListView.swift" "MediStock/Views/AisleView.swift"
    echo "✅ AisleListView : version FixedViews utilisée"
fi

# Supprimer le dossier FixedViews maintenant vide
if [ -d "MediStock/Views/FixedViews/" ]; then
    rmdir "MediStock/Views/FixedViews/" 2>/dev/null
    echo "✅ Dossier FixedViews/ supprimé"
fi

# 5. Vérifier les redéclarations restantes
echo ""
echo "🔍 Vérification des redéclarations..."
echo ""
echo "MedicineListView:"
grep -r "struct MedicineListView" MediStock/ --include="*.swift" | grep -v old_versions
echo ""
echo "AisleDetailView:"
grep -r "struct AisleDetailView" MediStock/ --include="*.swift" | grep -v old_versions
echo ""
echo "StatCard:"
grep -r "struct StatCard" MediStock/ --include="*.swift" | grep -v old_versions

echo ""
echo "✅ Nettoyage terminé!"
echo ""
echo "📝 Actions effectuées:"
echo "- Suppression du répertoire MediStocks/"
echo "- Suppression des fichiers .backup.swift"
echo "- Utilisation des versions FixedViews/ (plus récentes)"
echo "- Sauvegarde des anciennes versions dans old_versions/"
echo ""
echo "🎯 Prochaine étape: Compiler le projet dans Xcode"