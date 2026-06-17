#!/bin/bash
# =============================================================
# Odoo Database Backup Tool - Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/user/odoo_backup/main/install.sh | bash
# =============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/Pani-k-folk/odoo-backup.git"
INSTALL_DIR="$HOME/.local/share/odoo-backup"
BIN_DIR="$HOME/.local/bin"
BIN_NAME="odoo-backup"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Odoo Database Backup Tool Installer   ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# ---- Check dependencies ----
echo -e "${YELLOW}Checking dependencies...${NC}"

# Check git
if ! command -v git &> /dev/null; then
    echo -e "${RED}✗ git is not installed${NC}"
    echo -e "${YELLOW}  Install: sudo apt-get install git${NC}"
    exit 1
fi
echo -e "${GREEN}✓ git is installed${NC}"

# Check sshpass (optional)
if command -v sshpass &> /dev/null; then
    echo -e "${GREEN}✓ sshpass is installed${NC}"
else
    echo -e "${YELLOW}⚠ sshpass is not installed${NC}"
    echo -e "${YELLOW}  This is optional - only required for password authentication${NC}"
    echo -e "${YELLOW}  If you use SSH key authentication, you don't need sshpass${NC}"
    echo -e "${YELLOW}  Install later: sudo apt-get install sshpass${NC}"
fi

echo ""

# ---- Clone or update repository ----
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Existing installation found at ${INSTALL_DIR}${NC}"
    read -p "Update existing installation? (y/N): " UPDATE_CHOICE
    if [[ "$UPDATE_CHOICE" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Updating...${NC}"
        git -C "$INSTALL_DIR" pull origin main
        echo -e "${GREEN}✓ Updated successfully${NC}"
    else
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi
else
    echo -e "${CYAN}Cloning repository...${NC}"
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone "$REPO_URL" "$INSTALL_DIR"
    echo -e "${GREEN}✓ Cloned successfully${NC}"
fi

echo ""

# ---- Create symlink ----
echo -e "${CYAN}Creating symlink...${NC}"
mkdir -p "$BIN_DIR"
chmod +x "$INSTALL_DIR/backup_db.sh"

# Remove existing symlink if exists
if [ -L "$BIN_DIR/$BIN_NAME" ]; then
    rm "$BIN_DIR/$BIN_NAME"
fi

ln -s "$INSTALL_DIR/backup_db.sh" "$BIN_DIR/$BIN_NAME"
echo -e "${GREEN}✓ Symlink created: $BIN_DIR/$BIN_NAME${NC}"

echo ""

# ---- Create config example ----
echo -e "${CYAN}Creating config example...${NC}"
if [ ! -f "$INSTALL_DIR/config.conf.example" ]; then
    cat > "$INSTALL_DIR/config.conf.example" << 'EOF'
# Odoo Database Backup Configuration
# Copy this file to config.conf and fill in your values

[project_name]
SSH_USER=odoo
SSH_HOST=192.168.1.100
SSH_PORT=22
SSH_AUTH_METHOD=password
SSH_KEY_PATH=
DOCKER_DB=odoo_db_1
DB_NAME=production
LOCAL_PATH=/home/user/backups

# SSH_AUTH_METHOD options:
# - password: Requires sshpass to be installed
# - key: Uses SSH key authentication (no sshpass needed)
EOF
    echo -e "${GREEN}✓ Config example created: $INSTALL_DIR/config.conf.example${NC}"
else
    echo -e "${YELLOW}⚠ Config example already exists${NC}"
fi

echo ""

# ---- Check PATH ----
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo -e "${YELLOW}⚠ $BIN_DIR is not in your PATH${NC}"
    echo -e "${YELLOW}  Add this to your ~/.bashrc or ~/.zshrc:${NC}"
    echo -e "${CYAN}  export PATH=\"$BIN_DIR:\$PATH\"${NC}"
    echo ""
fi

# ---- Summary ----
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}      Installation Complete!            ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo -e "  ${CYAN}$BIN_NAME --add${NC}         Add new project"
echo -e "  ${CYAN}$BIN_NAME -l${NC}            List all projects"
echo -e "  ${CYAN}$BIN_NAME <project>${NC}     Run backup"
echo ""
echo -e "${YELLOW}Examples:${NC}"
echo -e "  ${CYAN}$BIN_NAME --add${NC}"
echo -e "  ${CYAN}$BIN_NAME myproject${NC}"
echo ""
if ! command -v sshpass &> /dev/null; then
    echo -e "${YELLOW}Note:${NC}"
    echo -e "  sshpass is not installed. You can still use SSH key authentication."
    echo -e "  If you want to use password authentication, install sshpass:"
    echo -e "  ${CYAN}sudo apt-get install sshpass${NC}"
    echo ""
fi
echo -e "${GREEN}========================================${NC}"
