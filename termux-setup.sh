#!/data/data/com.termux/files/usr/bin/sh

# Colours
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BASE_PACKAGES="git curl wget ranger nano htop tree"

print_status() {
    printf "${BLUE}==>${NC} %s\n" "$1"
}
print_ok() {
    printf "${GREEN}[OK]${NC} %s\n" "$1"
}
print_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$1"
}
print_error() {
    printf "${RED}[ERR]${NC} %s\n" "$1"
}

pause_enter() {
    printf "\n${YELLOW}Press Enter to continue...${NC}"
    read -r _
}

change_repo() {
    print_status "Configuring repositories..."
    termux-change-repo
}

setup_storage_access() {
    print_status "Requesting storage access..."
    termux-setup-storage
}

update_system() {
    print_status "Updating system packages..."
    pkg update && pkg upgrade -y
}

install_packages() {
    print_status "Installing base packages..."
    pkg install -y $BASE_PACKAGES
}

show_packages_list() {
    printf "\n${BLUE}The following packages will be installed:${NC}\n"
    for pkg in $BASE_PACKAGES; do
        printf "  ${GREEN}•${NC} %s\n" "$pkg"
    done
    printf "\n"
}

show_summary() {
    mode=$1
    printf "\n${GREEN}====================================${NC}\n"
    printf "${GREEN}    SETUP COMPLETED SUCCESSFULLY    ${NC}\n"
    printf "${GREEN}====================================${NC}\n"
    printf "Completed steps:\n"
    printf "  ${GREEN}✔${NC} Repositories configured\n"
    printf "  ${GREEN}✔${NC} Storage access granted\n"
    printf "  ${GREEN}✔${NC} System updated\n"

    if [ "$mode" = "full" ]; then
        printf "  ${GREEN}✔${NC} Base packages installed\n"
    fi
    printf "${GREEN}====================================${NC}\n"
}

clear_bashrc() {
    bashrc="$HOME/.bashrc"
    printf "${YELLOW}Clear ~/.bashrc? Backup will be saved as .bashrc.bak (y/N):${NC} "
    read -r confirm
    case "$confirm" in
        y|Y)
            if [ -f "$bashrc" ]; then
                cp "$bashrc" "$HOME/.bashrc.bak" || { print_error "Backup failed"; return 1; }
            fi
            : > "$bashrc"
            print_ok "~/.bashrc cleared"
            ;;
        *)
            print_warn "Action aborted"
            ;;
    esac
}

setup_only() {
    change_repo && setup_storage_access && update_system && show_summary "basic"
}

setup_and_install() {
    show_packages_list
    pause_enter
    change_repo && setup_storage_access && update_system && install_packages && show_summary "full"
}

menu() {
    while true; do
        clear
        printf "${BLUE}====================================${NC}\n"
        printf "${BLUE}       TERMUX INITIAL SETUP         ${NC}\n"
        printf "${BLUE}====================================${NC}\n"
        printf "${GREEN}1)${NC} Basic Setup Only\n"
        printf "${GREEN}2)${NC} Setup + Install Packages\n"
        printf "${GREEN}3)${NC} Clear ~/.bashrc\n"
        printf "${RED}4)${NC} Exit\n"
        printf "${BLUE}------------------------------------${NC}\n"
        printf "Select an option: "
        read -r choice

        case "$choice" in
            1) setup_only; pause_enter ;;
            2) setup_and_install; pause_enter ;;
            3) clear_bashrc; pause_enter ;;
            4) printf "Goodbye!\n"; exit 0 ;;
            *) print_error "Invalid selection"; sleep 1 ;;
        esac
    done
}

menu
