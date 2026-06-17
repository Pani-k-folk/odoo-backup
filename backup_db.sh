#!/bin/bash
# =============================================================
# Odoo Database Backup Script v2 (with Config File)
# Usage: ./backup_db.sh <project_name>
# Example: ./backup_db.sh aab
# =============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.conf"

# ---- Helper: Print Usage ----
usage() {
    echo -e "${YELLOW}Usage:${NC} $0 <project_name>"
    echo -e "${YELLOW}       $0 --list | -l${NC}  (show all projects)"
    echo -e "${YELLOW}       $0 --add${NC}          (add new project)"
    echo ""
    echo -e "${YELLOW}Example:${NC} $0 aab"
    exit 1
}

# ---- Helper: List all projects ----
list_projects() {
    echo -e "${GREEN}Available Projects:${NC}"
    echo ""
    grep '^\[' "$CONFIG_FILE" | tr -d '[]' | while read -r project; do
        echo -e "  ${CYAN}→ $project${NC}"
    done
    echo ""
}

# ---- Helper: Add new project ----
add_project() {
    echo -e "${GREEN}Add New Project${NC}"
    echo ""
    read -p "Project Name (keyword): " PROJECT
    read -p "SSH User: " SSH_USER
    read -p "SSH Host: " SSH_HOST
    read -p "SSH Port (default 22): " SSH_PORT
    SSH_PORT=${SSH_PORT:-22}
    
    echo ""
    echo -e "${YELLOW}Authentication Method:${NC}"
    echo "  1. Password (requires sshpass)"
    echo "  2. SSH Key"
    read -p "Select (1/2, default 1): " AUTH_CHOICE
    AUTH_CHOICE=${AUTH_CHOICE:-1}
    
    if [ "$AUTH_CHOICE" = "2" ]; then
        SSH_AUTH_METHOD="key"
        read -p "SSH Key Path (e.g. /home/user/.ssh/id_rsa): " SSH_KEY_PATH
        if [ ! -f "$SSH_KEY_PATH" ]; then
            echo -e "${RED}Error: Key file not found: ${SSH_KEY_PATH}${NC}"
            exit 1
        fi
    else
        SSH_AUTH_METHOD="password"
        SSH_KEY_PATH=""
    fi
    
    read -p "Docker Container Name: " DOCKER_DB
    read -p "Database Name: " DB_NAME
    read -p "Local Backup Path: " LOCAL_PATH

    # สร้าง config file ถ้าไม่มี
    touch "$CONFIG_FILE"

    # เช็คว่า Project มีอยู่แล้วไหม
    if grep -q "^\[${PROJECT}\]" "$CONFIG_FILE"; then
        echo -e "${RED}Error: Project '${PROJECT}' already exists!${NC}"
        exit 1
    fi

    # เพิ่ม Config
    cat >> "$CONFIG_FILE" << CONF

[${PROJECT}]
SSH_USER=${SSH_USER}
SSH_HOST=${SSH_HOST}
SSH_PORT=${SSH_PORT}
SSH_AUTH_METHOD=${SSH_AUTH_METHOD}
SSH_KEY_PATH=${SSH_KEY_PATH}
DOCKER_DB=${DOCKER_DB}
DB_NAME=${DB_NAME}
LOCAL_PATH=${LOCAL_PATH}
CONF

    echo ""
    echo -e "${GREEN}✓ Project '${PROJECT}' added successfully!${NC}"
    echo -e "${YELLOW}Run backup:${NC} $0 ${PROJECT}"
    exit 0
}

# ---- Helper: Read config value ----
get_config() {
    local project=$1
    local key=$2
    # อ่านค่าจาก section [project]
    awk -F'=' "/^\[${project}\]/{found=1} found && /^${key}=/{print \$2; exit}" "$CONFIG_FILE"
}

# ---- Helper: Load project config ----
load_config() {
    local project=$1

    # เช็คว่า Project มีอยู่ไหม
    if ! grep -q "^\[${project}\]" "$CONFIG_FILE"; then
        echo -e "${RED}Error: Project '${project}' not found in config!${NC}"
        echo ""
        list_projects
        exit 1
    fi

    SSH_USER=$(get_config "$project" "SSH_USER")
    SSH_HOST=$(get_config "$project" "SSH_HOST")
    SSH_PORT=$(get_config "$project" "SSH_PORT")
    SSH_AUTH_METHOD=$(get_config "$project" "SSH_AUTH_METHOD")
    SSH_KEY_PATH=$(get_config "$project" "SSH_KEY_PATH")
    DOCKER_DB=$(get_config "$project" "DOCKER_DB")
    DB_NAME=$(get_config "$project" "DB_NAME")
    LOCAL_PATH=$(get_config "$project" "LOCAL_PATH")
    
    # Default to password if not set
    SSH_AUTH_METHOD=${SSH_AUTH_METHOD:-password}
}

# ---- Helper: Build SSH options ----
build_ssh_opts() {
    local opts="-o StrictHostKeyChecking=no -p $SSH_PORT"
    if [ "$SSH_AUTH_METHOD" = "key" ]; then
        opts="$opts -i $SSH_KEY_PATH"
    fi
    echo "$opts"
}

# ---- Helper: Run SSH command ----
run_ssh() {
    if [ "$SSH_AUTH_METHOD" = "password" ]; then
        sshpass -p "$SSH_PASS" ssh $(build_ssh_opts) "$@"
    else
        ssh $(build_ssh_opts) "$@"
    fi
}

# ---- Helper: Run SCP command ----
run_scp() {
    if [ "$SSH_AUTH_METHOD" = "password" ]; then
        sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no -P "$SSH_PORT" "$@"
    else
        scp -o StrictHostKeyChecking=no -P "$SSH_PORT" -i "$SSH_KEY_PATH" "$@"
    fi
}

# ---- Helper: Cleanup password ----
cleanup() {
    SSH_PASS=""
    unset SSH_PASS
}

# ---- Main ----
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}      Odoo Database Backup Script       ${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check arguments
if [ $# -eq 0 ]; then
    usage
fi

case "$1" in
    --list|-l)
        if [ ! -f "$CONFIG_FILE" ]; then
            echo -e "${RED}Config file not found: ${CONFIG_FILE}${NC}"
            echo -e "Run: $0 --add to add a project"
            exit 1
        fi
        list_projects
        exit 0
        ;;
    --add)
        add_project
        ;;
    *)
        PROJECT=$1
        ;;
esac

# ---- Check config file ----
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Config file not found: ${CONFIG_FILE}${NC}"
    echo -e "Run: $0 --add to create your first project"
    exit 1
fi

# ---- Load config ----
load_config "$PROJECT"

# ---- Validate auth method and get password if needed ----
if [ "$SSH_AUTH_METHOD" = "password" ]; then
    # Check sshpass
    if ! command -v sshpass &> /dev/null; then
        echo -e "${RED}Error: sshpass is not installed!${NC}"
        echo -e "${YELLOW}Install with: sudo apt-get install sshpass${NC}"
        exit 1
    fi
    read -s -p "SSH Password for ${SSH_USER}@${SSH_HOST}: " SSH_PASS
    echo ""
    if [ -z "$SSH_PASS" ]; then
        echo -e "${RED}Error: Password cannot be empty!${NC}"
        exit 1
    fi
    trap cleanup EXIT
elif [ "$SSH_AUTH_METHOD" = "key" ]; then
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}Error: SSH key not found: ${SSH_KEY_PATH}${NC}"
        exit 1
    fi
else
    echo -e "${RED}Error: Invalid SSH_AUTH_METHOD: ${SSH_AUTH_METHOD}${NC}"
    echo -e "${YELLOW}Must be 'password' or 'key'${NC}"
    exit 1
fi

# ---- Generate filename ----
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REMOTE_FILE="/tmp/${DB_NAME}_${TIMESTAMP}.sql"
REMOTE_FILE_GZ="${REMOTE_FILE}.gz"
LOCAL_FILE="${LOCAL_PATH}/${DB_NAME}_${TIMESTAMP}.sql"
LOCAL_FILE_GZ="${LOCAL_FILE}.gz"

# ---- Create local directory ----
mkdir -p "$LOCAL_PATH"

# ---- Summary ----
echo -e "${YELLOW}----------------------------------------${NC}"
echo -e "${YELLOW}Project    : ${PROJECT}${NC}"
echo -e "SSH        : ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
echo -e "Auth       : ${SSH_AUTH_METHOD}"
echo -e "Container  : ${DOCKER_DB}"
echo -e "Database   : ${DB_NAME}"
echo -e "Local Path : ${LOCAL_PATH}"
echo -e "${YELLOW}----------------------------------------${NC}"
echo ""

# ---- Step 1: Dump + Gzip ----
echo -e "${GREEN}[1/3] Dumping database on remote server...${NC}"
run_ssh "${SSH_USER}@${SSH_HOST}" \
    "docker exec -t ${DOCKER_DB} pg_dump -U odoo -d ${DB_NAME} > ${REMOTE_FILE} && gzip ${REMOTE_FILE}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to dump database!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Dump completed${NC}"

# ---- Step 2: Download ----
echo ""
echo -e "${GREEN}[2/3] Downloading backup to local...${NC}"
run_scp "${SSH_USER}@${SSH_HOST}:${REMOTE_FILE_GZ}" "${LOCAL_FILE_GZ}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to download backup!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Downloaded: ${LOCAL_FILE_GZ}${NC}"

# ---- Step 3: Extract ----
echo ""
echo -e "${GREEN}[3/3] Extracting backup file...${NC}"
gunzip "${LOCAL_FILE_GZ}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to extract!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Extracted: ${LOCAL_FILE}${NC}"

# ---- Cleanup Remote ----
echo ""
echo -e "${YELLOW}Cleaning up remote temp files...${NC}"
run_ssh "${SSH_USER}@${SSH_HOST}" "rm -f ${REMOTE_FILE_GZ}"
echo -e "${GREEN}✓ Cleanup done${NC}"

# ---- Summary ----
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}         Backup Completed!              ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "  Project : ${PROJECT}"
echo -e "  File    : ${LOCAL_FILE}"
echo -e "  Size    : $(du -sh "${LOCAL_FILE}" | cut -f1)"
echo -e "${GREEN}========================================${NC}"