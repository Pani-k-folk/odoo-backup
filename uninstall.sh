#!/bin/bash
# =============================================================
# Odoo Database Backup Tool - Uninstallation Script
# Usage: odoo-backup-uninstall
# =============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/share/odoo-backup"
BIN_DIR="$HOME/.local/bin"
BIN_NAME="odoo-backup"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Odoo Database Backup Tool Uninstaller ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# ---- Check if installed ----
if [ ! -d "$INSTALL_DIR" ] && [ ! -L "$BIN_DIR/$BIN_NAME" ]; then
    echo -e "${YELLOW}Odoo Backup Tool is not installed${NC}"
    exit 0
fi

# ---- Confirm uninstallation ----
echo -e "${YELLOW}This will remove:${NC}"
echo -e "  - Symlink: $BIN_DIR/$BIN_NAME"
echo -e "  - Installation: $INSTALL_DIR"
echo ""
echo -e "${RED}Note: Your config.conf and backup files will NOT be deleted${NC}"
echo ""
read -p "Continue with uninstallation? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Uninstallation cancelled${NC}"
    exit 0
fi

echo ""

# ---- Remove symlink ----
if [ -L "$BIN_DIR/$BIN_NAME" ]; then
    echo -e "${CYAN}Removing symlink...${NC}"
    rm "$BIN_DIR/$BIN_NAME"
    echo -e "${GREEN}✓ Removed: $BIN_DIR/$BIN_NAME${NC}"
else
    echo -e "${YELLOW}⚠ Symlink not found: $BIN_DIR/$BIN_NAME${NC}"
fi

echo ""

# ---- Remove installation directory ----
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${CYAN}Removing installation directory...${NC}"
    
    # Check if there are backup files
    BACKUP_COUNT=$(find "$INSTALL_DIR" -name "*.sql" -o -name "*.sql.gz" 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo -e "${YELLOW}⚠ Found $BACKUP_COUNT backup file(s) in installation directory${NC}"
        read -p "Delete backup files too? (y/N): " DELETE_BACKUPS
        if [[ "$DELETE_BACKUPS" =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
            echo -e "${GREEN}✓ Removed: $INSTALL_DIR${NC}"
        else
            # Move backups to home directory first
            BACKUP_DIR="$HOME/odoo-backup-saved"
            mkdir -p "$BACKUP_DIR"
            find "$INSTALL_DIR" -name "*.sql" -o -name "*.sql.gz" 2>/dev/null | while read -r file; do
                mv "$file" "$BACKUP_DIR/"
            done
            rm -rf "$INSTALL_DIR"
            echo -e "${GREEN}✓ Backups saved to: $BACKUP_DIR${NC}"
            echo -e "${GREEN}✓ Removed: $INSTALL_DIR${NC}"
        fi
    else
        rm -rf "$INSTALL_DIR"
        echo -e "${GREEN}✓ Removed: $INSTALL_DIR${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Installation directory not found: $INSTALL_DIR${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    Uninstallation Complete!            ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo -e "  - Your config files in other locations are preserved"
echo -e "  - Your backup files are preserved"
echo -e "  - To reinstall, run the install script again"
echo ""
