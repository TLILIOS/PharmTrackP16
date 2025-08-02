#!/bin/bash

# Script de validation avant nettoyage - Approche KISS et sécurisée
# Ce script vérifie que les fichiers peuvent être supprimés sans risque

echo "🔍 Validation Avant Nettoyage - MediStock"
echo "========================================"

# Couleurs pour la sortie
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Créer un dossier de sauvegarde
BACKUP_DIR="BACKUP_BEFORE_CLEANUP_$(date +%Y%m%d_%H%M%S)"
echo -e "${YELLOW}📦 Création du backup dans: $BACKUP_DIR${NC}"
mkdir -p "$BACKUP_DIR"

# Liste des fichiers à vérifier
FILES_TO_CHECK=(
    ".DS_Store"
    "MediStock/.DS_Store"
    "MediStock/Views/.DS_Store"
    "MediStock/Services/DataService_OLD.swift.bak"
    "FIX_NAVIGATION_DESTINATIONS.md"
    "FIX_MEDICINE_VIEW_DISAPPEARING.md"
    "FIX_EXPORT_BUTTON.md"
    "FIX_NAVIGATION_FINAL.md"
    "FIX_COMPILATION_ERRORS.md"
    "REDECLARATION_FIXES.md"
    "REDECLARATION_FIXES_COMPLETE.md"
    "REFACTORING_IMPLEMENTATION_GUIDE.md"
    "MIGRATION_GUIDE.md"
    "test_export_functionality.swift"
    "add_function_test.swift"
    "code_usage_analysis.swift"
    "generate_test_file.swift"
)

echo ""
echo "🔍 Vérification des fichiers..."
echo "==============================="

SAFE_TO_DELETE=()
RISKY_FILES=()

for file in "${FILES_TO_CHECK[@]}"; do
    if [ -f "$file" ]; then
        echo -n "Checking: $file ... "
        
        # Vérifier si le fichier est référencé quelque part
        # Exclure les .md et le fichier lui-même des résultats
        REFERENCES=$(grep -r "$(basename "$file")" . \
            --include="*.swift" \
            --include="*.plist" \
            --include="*.xcconfig" \
            --include="*.pbxproj" \
            --exclude-dir=".git" \
            --exclude-dir="$BACKUP_DIR" \
            2>/dev/null | grep -v "$file:" | wc -l)
        
        if [ "$REFERENCES" -eq 0 ]; then
            echo -e "${GREEN}✅ Aucune référence - SAFE${NC}"
            SAFE_TO_DELETE+=("$file")
            # Copier dans le backup
            cp "$file" "$BACKUP_DIR/" 2>/dev/null
        else
            echo -e "${RED}⚠️  Référencé $REFERENCES fois - RISKY${NC}"
            RISKY_FILES+=("$file")
        fi
    else
        echo -e "Skip: $file ... ${YELLOW}N'existe pas${NC}"
    fi
done

echo ""
echo "📊 Résumé de l'Analyse"
echo "====================="
echo -e "${GREEN}✅ Fichiers sûrs à supprimer: ${#SAFE_TO_DELETE[@]}${NC}"
echo -e "${RED}⚠️  Fichiers à risque: ${#RISKY_FILES[@]}${NC}"

if [ ${#RISKY_FILES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}⚠️  ATTENTION: Les fichiers suivants sont référencés:${NC}"
    for file in "${RISKY_FILES[@]}"; do
        echo "  - $file"
        echo "    Références:"
        grep -r "$(basename "$file")" . \
            --include="*.swift" \
            --include="*.plist" \
            --include="*.xcconfig" \
            --include="*.pbxproj" \
            --exclude-dir=".git" \
            --exclude-dir="$BACKUP_DIR" \
            2>/dev/null | grep -v "$file:" | head -3
    done
fi

echo ""
echo "🛠️  Script de Nettoyage Généré"
echo "=============================="

# Générer le script de nettoyage sécurisé
cat > cleanup_safe.sh << 'EOF'
#!/bin/bash

# Script de nettoyage sécurisé - Généré automatiquement
# Date: $(date)

echo "🧹 Nettoyage Sécurisé MediStock"
echo "==============================="

# Vérifier que le backup existe
if [ ! -d "BACKUP_DIR_PLACEHOLDER" ]; then
    echo "❌ ERREUR: Backup non trouvé. Exécutez d'abord cleanup_validation.sh"
    exit 1
fi

# Fichiers validés comme sûrs à supprimer
FILES_TO_DELETE=(
EOF

# Ajouter les fichiers sûrs au script
for file in "${SAFE_TO_DELETE[@]}"; do
    echo "    \"$file\"" >> cleanup_safe.sh
done

cat >> cleanup_safe.sh << 'EOF'
)

echo "📋 Suppression de ${#FILES_TO_DELETE[@]} fichiers..."

for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        echo "  🗑️  Suppression: $file"
        rm "$file"
    fi
done

echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "Pour restaurer si nécessaire:"
echo "  cp BACKUP_DIR_PLACEHOLDER/* ."
EOF

# Remplacer le placeholder avec le vrai nom du backup
sed -i '' "s/BACKUP_DIR_PLACEHOLDER/$BACKUP_DIR/g" cleanup_safe.sh
chmod +x cleanup_safe.sh

echo ""
echo "✅ Validation Terminée !"
echo ""
echo "Prochaines étapes:"
echo "1. Examinez les résultats ci-dessus"
echo "2. Si tout est OK, exécutez: ./cleanup_safe.sh"
echo "3. Testez l'application après nettoyage"
echo "4. Si problème, restaurez depuis: $BACKUP_DIR"
echo ""
echo "💡 Conseil: Faites un commit Git AVANT d'exécuter cleanup_safe.sh"