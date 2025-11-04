#!/bin/bash

# 🔐 Script Helper - Configuration Secrets GitHub
# Projet: MediStock
# Auteur: TLILI HAMDI
# Date: 2025-11-04

set -e  # Exit on error

echo "🔐 MediStock - GitHub Secrets Configuration Helper"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GoogleService-Info.plist exists
PLIST_FILE="MediStock/GoogleService-Info.plist"

if [ ! -f "$PLIST_FILE" ]; then
    echo -e "${RED}❌ Error: GoogleService-Info.plist not found at $PLIST_FILE${NC}"
    echo "   Please make sure you're in the project root directory."
    exit 1
fi

echo -e "${GREEN}✅ GoogleService-Info.plist found${NC}"
echo ""

# Extract and display secrets
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}📋 Secrets to Configure in GitHub${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Secret 1: FIREBASE_API_KEY
echo -e "${YELLOW}🔑 Secret 1: FIREBASE_API_KEY${NC}"
echo "----------------------------------------"

# Extract API_KEY from plist
API_KEY=$(plutil -extract API_KEY xml1 -o - "$PLIST_FILE" | grep -oE '<string>[^<]+</string>' | sed -E 's/<\/?string>//g')

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ Failed to extract API_KEY${NC}"
    exit 1
fi

echo -e "${GREEN}Value to copy:${NC}"
echo "$API_KEY"
echo ""
echo "This value has been copied to your clipboard!"
echo "$API_KEY" | pbcopy
echo ""
echo "Next steps:"
echo "1. Go to: https://github.com/TLILIOS/PharmTrackP16/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Name: FIREBASE_API_KEY"
echo "4. Secret: Paste (Cmd+V)"
echo "5. Click 'Add secret'"
echo ""

read -p "Press Enter when you've added FIREBASE_API_KEY to continue..."
echo ""

# Secret 2: GOOGLE_SERVICE_INFO_PLIST
echo -e "${YELLOW}🔑 Secret 2: GOOGLE_SERVICE_INFO_PLIST${NC}"
echo "----------------------------------------"
echo "Encoding GoogleService-Info.plist to base64..."

# Encode to base64 and copy to clipboard
BASE64_PLIST=$(base64 -i "$PLIST_FILE" | tr -d '\n')

if [ -z "$BASE64_PLIST" ]; then
    echo -e "${RED}❌ Failed to encode plist to base64${NC}"
    exit 1
fi

# Get length for validation
LENGTH=${#BASE64_PLIST}

echo -e "${GREEN}✅ Encoded successfully${NC}"
echo "Length: $LENGTH characters"
echo ""
echo "The base64-encoded value has been copied to your clipboard!"
echo "$BASE64_PLIST" | pbcopy
echo ""
echo "Next steps:"
echo "1. Go to: https://github.com/TLILIOS/PharmTrackP16/settings/secrets/actions"
echo "2. Click 'New repository secret'"
echo "3. Name: GOOGLE_SERVICE_INFO_PLIST"
echo "4. Secret: Paste (Cmd+V)"
echo "5. Click 'Add secret'"
echo ""

read -p "Press Enter when you've added GOOGLE_SERVICE_INFO_PLIST to continue..."
echo ""

# Validation
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}✅ Configuration Complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Secrets configured:"
echo "  ✅ FIREBASE_API_KEY"
echo "  ✅ GOOGLE_SERVICE_INFO_PLIST"
echo ""
echo "Next steps:"
echo ""
echo "1. Verify secrets are visible in GitHub:"
echo "   https://github.com/TLILIOS/PharmTrackP16/settings/secrets/actions"
echo ""
echo "2. Re-trigger failed workflows:"
echo "   Option A: Go to Actions tab → Select failed workflow → 'Re-run all jobs'"
echo "   Option B: Make a new commit and push (workflows will auto-trigger)"
echo ""
echo "3. Monitor workflow execution:"
echo "   https://github.com/TLILIOS/PharmTrackP16/actions"
echo ""
echo "4. Expected result:"
echo "   ✅ 'iOS Build and Test' should pass (~15 min)"
echo "   ✅ 'PR Validation' should pass (~20 min)"
echo "   ✅ 'SwiftLint' should pass (~5 min)"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Clean up sensitive files${NC}"
echo ""
echo "Run these commands to remove helper files:"
echo "  rm setup_github_secrets.sh"
echo "  rm SECRETS_TO_CONFIGURE.md"
echo ""
echo -e "${GREEN}🎉 Setup complete! Good luck with your CI/CD pipeline!${NC}"
echo ""
echo "For troubleshooting, see: docs/GITHUB_SECRETS_SETUP.md"
echo ""
