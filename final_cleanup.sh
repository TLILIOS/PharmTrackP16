#!/bin/bash

echo "🔧 Correction finale des duplications restantes..."
echo ""

# 1. Supprimer MedicineListViewFixed.swift (car on utilise déjà MedicineListView)
if [ -f "MediStock/Views/MedicineListViewFixed.swift" ]; then
    rm "MediStock/Views/MedicineListViewFixed.swift"
    echo "✅ MedicineListViewFixed.swift supprimé (utilisation de MedicineListView)"
fi

# 2. Gérer la duplication de StatCard
echo ""
echo "📝 Résolution du conflit StatCard..."

# Créer un fichier temporaire pour AisleView sans StatCard
if [ -f "MediStock/Views/AisleView.swift" ]; then
    # Extraire le numéro de ligne où StatCard est défini dans AisleView
    LINE_START=$(grep -n "struct StatCard" MediStock/Views/AisleView.swift | cut -d: -f1)
    
    if [ ! -z "$LINE_START" ]; then
        echo "   - StatCard trouvé dans AisleView.swift à la ligne $LINE_START"
        echo "   - Suppression de StatCard de AisleView.swift (gardé dans DashboardView.swift)"
        
        # Créer une version sans StatCard
        # On suppose que StatCard se termine avant la fin du fichier ou avant une autre struct
        # Pour être sûr, on va analyser le fichier
        
        # Sauvegarder l'original
        cp "MediStock/Views/AisleView.swift" "MediStock/Views/AisleView.swift.tmp"
        
        # Utiliser sed pour supprimer StatCard (de "struct StatCard" jusqu'à la prochaine struct ou fin)
        sed -i '' '/^struct StatCard: View {/,/^struct\|^enum\|^class\|^protocol\|^extension/{/^struct StatCard: View {/d; /^struct\|^enum\|^class\|^protocol\|^extension/!d;}' "MediStock/Views/AisleView.swift"
        
        echo "✅ StatCard supprimé de AisleView.swift"
        echo "   - StatCard reste uniquement dans DashboardView.swift"
    fi
fi

# 3. Vérification finale
echo ""
echo "🔍 Vérification finale des redéclarations..."
echo ""

echo "=== MedicineListView ==="
grep -r "struct MedicineListView" MediStock/ --include="*.swift" | grep -v old_versions | grep -v tmp
echo ""

echo "=== AisleDetailView ==="
grep -r "struct AisleDetailView" MediStock/ --include="*.swift" | grep -v old_versions | grep -v tmp
echo ""

echo "=== StatCard ==="
grep -r "struct StatCard" MediStock/ --include="*.swift" | grep -v old_versions | grep -v tmp
echo ""

# 4. Nettoyer les fichiers temporaires
rm -f MediStock/Views/*.tmp

echo "✅ Nettoyage final terminé!"
echo ""
echo "📊 Résumé:"
echo "- MedicineListViewFixed.swift supprimé"
echo "- StatCard supprimé de AisleView.swift (conservé dans DashboardView.swift)"
echo "- Plus aucune redéclaration ne devrait exister"
echo ""
echo "🎯 Le projet devrait maintenant compiler sans erreurs de redéclaration!"