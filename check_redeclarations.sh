#!/bin/bash

# Script de vérification des redéclarations dans le code Swift
# Usage: ./check_redeclarations.sh

echo "======================================"
echo "Vérification des redéclarations Swift"
echo "======================================"
echo ""

# Fonction pour afficher les résultats avec couleur
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "\033[32m✓\033[0m $2"
    else
        echo -e "\033[31m✗\033[0m $2"
    fi
}

# Vérifier les déclarations de classes/structs/enums/protocoles
echo "1. Recherche des déclarations multiples..."
echo "----------------------------------------"

error_found=0

for type in "class" "struct" "enum" "protocol"; do
    echo -n "Vérification des $type... "
    duplicates=$(find . -name "*.swift" -not -path "./Pods/*" -not -path "./.build/*" -exec grep -h "^$type " {} \; 2>/dev/null | grep -E "^$type [A-Za-z0-9_]+(\s*:|$)" | sed "s/:.*//" | sort | uniq -d)
    
    if [ -z "$duplicates" ]; then
        show_result 0 "Aucune duplication trouvée"
    else
        show_result 1 "Duplications trouvées:"
        echo "$duplicates" | while read line; do
            echo "  - $line"
            # Afficher les fichiers contenant cette déclaration
            find . -name "*.swift" -not -path "./Pods/*" -not -path "./.build/*" -exec grep -l "^$line" {} \; | sed 's/^/    /'
        done
        error_found=1
    fi
done

echo ""
echo "2. Vérification des extensions multiples..."
echo "-----------------------------------------"

# Chercher les extensions définies plusieurs fois pour le même type
extensions=$(find . -name "*.swift" -not -path "./Pods/*" -not -path "./.build/*" -exec grep -h "^extension " {} \; 2>/dev/null | sed 's/{.*//' | sort | uniq -c | grep -v "^   1 ")

if [ -z "$extensions" ]; then
    show_result 0 "Pas d'extensions multiples suspectes"
else
    echo "Extensions définies plusieurs fois (vérifier si nécessaire):"
    echo "$extensions"
fi

echo ""
echo "3. Vérification des fonctions globales..."
echo "----------------------------------------"

# Chercher les fonctions globales dupliquées
global_funcs=$(find . -name "*.swift" -not -path "./Pods/*" -not -path "./.build/*" -exec grep -h "^func " {} \; 2>/dev/null | grep -v "^func .*<" | sed 's/(.*//' | sort | uniq -d)

if [ -z "$global_funcs" ]; then
    show_result 0 "Aucune fonction globale dupliquée"
else
    show_result 1 "Fonctions globales dupliquées:"
    echo "$global_funcs"
    error_found=1
fi

echo ""
echo "4. Vérification des variables globales..."
echo "----------------------------------------"

# Chercher les variables globales dupliquées
global_vars=$(find . -name "*.swift" -not -path "./Pods/*" -not -path "./.build/*" -exec grep -hE "^(let|var) " {} \; 2>/dev/null | grep -v "^(let|var) .*=" | sed 's/:.*//' | sort | uniq -d)

if [ -z "$global_vars" ]; then
    show_result 0 "Aucune variable globale dupliquée"
else
    show_result 1 "Variables globales dupliquées:"
    echo "$global_vars"
    error_found=1
fi

echo ""
echo "======================================"
if [ $error_found -eq 0 ]; then
    echo -e "\033[32mAucune erreur de redéclaration trouvée!\033[0m"
    exit 0
else
    echo -e "\033[31mDes erreurs de redéclaration ont été trouvées.\033[0m"
    echo "Veuillez corriger les problèmes ci-dessus."
    exit 1
fi