#!/bin/bash
# encode-secrets.sh - Helper script to encode production secrets for Kubernetes
# Usage: ./encode-secrets.sh

set -e

echo "==================================================================="
echo "  EDK Admin Packages - Production Secrets Encoder"
echo "==================================================================="
echo ""
echo "This script will help you encode production secrets for Kubernetes."
echo "The output will be base64-encoded values ready to use in"
echo "admin-packages-secrets.yaml"
echo ""
echo "IMPORTANT: Values shown will be base64 encoded but are still"
echo "           sensitive. Do not share this output publicly!"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "-------------------------------------------------------------------"
echo "PRZELEWY24 Secrets (PRODUCTION)"
echo "-------------------------------------------------------------------"

echo -e "${YELLOW}Current values from .env:${NC}"
echo "  PRZELEWY24_CRC_KEY=e4b020fec8e5bac1"
echo "  PRZELEWY24_API_KEY=74cb414be80b4ddfdd34758ad7b401e7"
echo ""

echo "PRZELEWY24_CRC_KEY:"
echo -e "${GREEN}  $(echo -n "e4b020fec8e5bac1" | base64)${NC}"
echo ""

echo "PRZELEWY24_API_KEY:"
echo -e "${GREEN}  $(echo -n "74cb414be80b4ddfdd34758ad7b401e7" | base64)${NC}"
echo ""

echo "-------------------------------------------------------------------"
echo "DATABASE URL (PRODUCTION)"
echo "-------------------------------------------------------------------"
echo -e "${YELLOW}Format: postgresql://username:password@host:port/database${NC}"
echo ""

read -p "Enter DATABASE_URL (or press Enter for example): " db_url
if [ -z "$db_url" ]; then
    db_url="postgresql://edk_user:CHANGE_ME@postgres-prod:5432/edk_packages_production"
    echo -e "${RED}Using EXAMPLE value - MUST be changed!${NC}"
fi

echo "DATABASE_URL:"
echo -e "${GREEN}  $(echo -n "$db_url" | base64)${NC}"
echo ""

echo "-------------------------------------------------------------------"
echo "RAILS SECRET_KEY_BASE (PRODUCTION)"
echo "-------------------------------------------------------------------"
echo -e "${YELLOW}Generating new secret key base...${NC}"

if command -v rails &> /dev/null; then
    secret_key=$(bin/rails secret 2>/dev/null || rails secret 2>/dev/null || openssl rand -hex 64)
else
    echo -e "${YELLOW}Rails not found, using openssl...${NC}"
    secret_key=$(openssl rand -hex 64)
fi

echo "SECRET_KEY_BASE:"
echo -e "${GREEN}  $(echo -n "$secret_key" | base64)${NC}"
echo ""

echo "-------------------------------------------------------------------"
echo "APACZKA API SECRET (PRODUCTION)"
echo "-------------------------------------------------------------------"
echo -e "${YELLOW}Get your production credentials from: https://www.apaczka.pl/${NC}"
echo ""

read -p "Enter APACZKA_APP_SECRET (or press Enter to skip): " apaczka_secret
if [ -z "$apaczka_secret" ]; then
    apaczka_secret="your_apaczka_secret_here_CHANGE_ME"
    echo -e "${RED}Using PLACEHOLDER value - MUST be changed!${NC}"
fi

echo "APACZKA_APP_SECRET:"
echo -e "${GREEN}  $(echo -n "$apaczka_secret" | base64)${NC}"
echo ""

echo "-------------------------------------------------------------------"
echo "SMTP Credentials (PRODUCTION)"
echo "-------------------------------------------------------------------"
echo -e "${YELLOW}Enter your SMTP credentials (Gmail, Postmark, SendGrid, etc.)${NC}"
echo ""

read -p "Enter SMTP_USER_NAME (email or token): " smtp_user
if [ -z "$smtp_user" ]; then
    smtp_user="noreply@edk.org.pl"
    echo -e "${RED}Using EXAMPLE value - MUST be changed!${NC}"
fi

echo "SMTP_USER_NAME:"
echo -e "${GREEN}  $(echo -n "$smtp_user" | base64)${NC}"
echo ""

read -sp "Enter SMTP_PASSWORD (input hidden): " smtp_pass
echo ""
if [ -z "$smtp_pass" ]; then
    smtp_pass="your_smtp_password_CHANGE_ME"
    echo -e "${RED}Using PLACEHOLDER value - MUST be changed!${NC}"
fi

echo "SMTP_PASSWORD:"
echo -e "${GREEN}  $(echo -n "$smtp_pass" | base64)${NC}"
echo ""

echo "==================================================================="
echo "                      SUMMARY"
echo "==================================================================="
echo ""
echo "Copy the GREEN values above to your admin-packages-secrets.yaml file."
echo ""
echo "Next steps:"
echo "  1. Copy admin-packages-secrets.yaml.example to admin-packages-secrets.yaml"
echo "  2. Replace the placeholder values with the encoded values above"
echo "  3. Apply to Kubernetes: kubectl apply -f admin-packages-secrets.yaml"
echo ""
echo -e "${YELLOW}IMPORTANT: Do NOT commit admin-packages-secrets.yaml to git!${NC}"
echo ""
echo "==================================================================="
