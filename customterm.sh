#!/bin/bash
set -e

# ===========================================================
# Helper Functions (Defined before main logic)
# ===========================================================
log() { echo "$(date +"%F %T") - $1" >> "$LOG"; }
msg() { echo -e "${CYAN}$1${RESET}"; }
success() { echo -e "${GREEN}✔ $1${RESET}"; log "$1"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; log "WARN: $1"; }
error() { echo -e "${RED}❌ $1${RESET}"; log "ERROR: $1"; exit 1; }

# ===========================================================
# Title: Custom Terminal for All Linux Distros
# Description: Automated installer for Zsh, Oh-My-Zsh
# Author: l0n3m4n
# Version: v1.0.0 
# License: MIT
# ===========================================================

Version=v1.0.0

 
if [[ -n "$SUDO_USER" && "$UID" == "0" ]]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    msg "ℹ️ Running with sudo, configuring for user: $SUDO_USER in $USER_HOME"
else
    USER_HOME="$HOME"
fi

# Re-assign user-specific paths to use USER_HOME
BACKUP="$USER_HOME/.zshrc.bak"
LOG="$USER_HOME/custom_terminal_install.log"
ZSH_CUSTOM="${ZSH_CUSTOM:-$USER_HOME/.oh-my-zsh/custom}"
ZSHRC="$USER_HOME/.zshrc"

plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" \
"fast-syntax-highlighting" "zsh-autocomplete")

theme="powerlevel10k"

# -----------------------------------------------------------
# Colors & UI
# -----------------------------------------------------------
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# ===========================================================
# Helper Functions (Defined before main logic)
# ===========================================================

print_banner_func() {
local version_val="$1"
cat << EOF

             _             _                 
 ___ _ _ ___| |_ ___ _____| |_ ___ ___ _____ 
|  _| | |_ -|  _| . |     |  _| -_|  _|     |
|___|___|___|_| |___|_|_|_|_| |___|_| |_|_|_|
        author: l0n3m4n | version:${version_val}
EOF
}

usage() {
    echo -e "\n${YELLOW}Usage:${RESET} ${CYAN}$(basename "$0") [-h] [-all] [-p] [-r]${RESET}"
    echo -e "  ${GREEN}-h:${RESET} Display this help message."
    echo -e "  ${GREEN}-a:${RESET} Perform a non-interactive installation with all recommended settings."
    echo -e "  ${GREEN}-p:${RESET} Show important paths \(e.g., .zshrc, custom plugin directory\)."
    echo -e "  ${GREEN}-r:${RESET} Remove Oh-My-Zsh, plugins, theme, and clean .zshrc."
    echo ""
    echo -e "${YELLOW}Examples:${RESET}"
    echo -e "  ${CYAN}$(basename "$0") -h${RESET}"
    echo -e "  ${CYAN}sudo $(basename "$0") -a${RESET}"
    echo -e "  ${CYAN}$(basename "$0") -p${RESET}"
    echo -e "  ${CYAN}sudo $(basename "$0") -r${RESET}"
    exit 0
}



confirm() {
  if [[ "$ALL_INSTALL" == "true" ]]; then
    true
  else
    echo -n "$1 (y/n): "  
    read ans
    [[ "$ans" == "y" || "$ans" == "Y" ]]
  fi
}

get_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "macOS";;
        *)
            echo "UNKNOWN_OS";;
    esac
}

get_pkg_manager() {
    local OS_TYPE=$(get_os)
    if [[ "$OS_TYPE" == "macOS" ]]; then
        echo "brew"
    elif [[ -f "/etc/os-release" ]]; then
        source "/etc/os-release"
        case "$ID" in
            ubuntu|debian|linuxmint)
                echo "apt"
                ;;            fedora|centos|rhel)
                echo "dnf"
                ;;            arch|manjaro)
                echo "pacman"
                ;;            *)
                echo "unknown"
                ;;        esac
    else
        echo "unknown"
    fi
}

check_sudo() {
    msg "🔑 Checking sudo access..."
    if command -v sudo >/dev/null 2>&1; then
        if sudo -n true 2>/dev/null; then
            success "Sudo access confirmed."
        else
            error "Sudo command found, but you don't have password-less sudo access. Please configure it or run the script with sudo."
        fi
    else
        error "Sudo command not found. Please install sudo or run the script as root."
    fi
}

remove_func() {
    msg "\n${YELLOW}Starting removal process...${RESET}"

    # Remove Oh-My-Zsh directory
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        msg "Removing Oh-My-Zsh..."
        rm -rf "$HOME/.oh-my-zsh" && success "Oh-My-Zsh removed." || warn "Failed to remove Oh-My-Zsh."
    else
        warn "Oh-My-Zsh not found."
    fi

    # Remove custom plugins and themes
    if [[ -d "$ZSH_CUSTOM" ]]; then
        msg "Removing custom plugins and themes..."
        rm -rf "$ZSH_CUSTOM" && success "Custom plugins and themes removed." || warn "Failed to remove custom plugins/themes."
    else
        warn "Custom plugin directory not found."
    fi

    # Restore .zshrc from backup or clean
    if [[ -f "$BACKUP" ]]; then
        msg "Restoring .zshrc from backup..."
        cp "$BACKUP" "$ZSHRC" && success ".zshrc restored from backup." || warn "Failed to restore .zshrc from backup."
        rm -f "$BACKUP" && success "Backup file removed."
    elif [[ -f "$ZSHRC" ]]; then
        msg "Cleaning .zshrc file..."
        # Remove the specific ZSH_THEME line added by this script
        sed -i '/^ZSH_THEME="powerlevel10k\/powerlevel10k"$/d' "$ZSHRC"
        # --- Plugin cleanup ---
        # Check if a plugins=(...) line exists
        if grep -q "^plugins=(" "$ZSHRC"; then
            current_plugins_line=$(grep "^plugins=(" "$ZSHRC")
            current_plugins_str=$(echo "$current_plugins_line" | sed -E 's/^plugins=\((.*)\)/\1/' | xargs) # xargs to trim whitespace
            
            declare -a filtered_plugins_array

            # Convert to array for easier manipulation
            IFS=' ' read -r -a current_plugins_array <<< "$current_plugins_str"

            # Filter out plugins installed by this script
            for p in "${current_plugins_array[@]}"; do
                is_installed_plugin=false
                for installed_p in "${plugins[@]}"; do
                    if [[ "$p" == "$installed_p" ]]; then
                        is_installed_plugin=true
                        break
                    fi
                    done
                if ! "$is_installed_plugin"; then
                    filtered_plugins_array+=("$p")
                fi
            done
            
            # Reconstruct the new plugins string
            filtered_plugins_str=$(IFS=' '; echo "${filtered_plugins_array[*]}")

            # Update the plugins line in .zshrc
            # If no plugins remain, delete the line; otherwise, update it.
            if [[ -z "$filtered_plugins_str" ]]; then
                sed -i '/^plugins=(.*)$/d' "$ZSHRC"
            else
                # This sed assumes there is only one plugins=(...) line.
                sed -i -E "s|^plugins=\(.*\)$|plugins=($filtered_plugins_str)|" "$ZSHRC"
            fi
        fi

        success ".zshrc cleaned."
    else
        warn ".zshrc not found, no cleanup needed."
    fi

    # Change default shell back to bash (optional, with confirmation)
    if [[ "$SHELL" == "$(which zsh)" ]]; then 
        if confirm "Zsh is your default shell. Change back to bash?"; then
            if chsh -s "$(which bash)"; then
                success "Default shell changed to bash. Please restart your terminal."
            else
                warn "Failed to change default shell to bash. You may need to do it manually."
            fi
        fi
    fi

    msg "${GREEN}Removal process completed.${RESET}"
    exit 0
}

show_paths_func() {
    msg "\n${YELLOW}Important Paths:${RESET}"
    msg "  ${CYAN}ZSHRC: ${ZSHRC}${RESET}"
    msg "  ${CYAN}BACKUP: ${BACKUP}${RESET}"
    msg "  ${CYAN}LOG: ${LOG}${RESET}"
    msg "  ${CYAN}ZSH_CUSTOM: ${ZSH_CUSTOM}${RESET}"
    exit 0
}

# ===========================================================
# Main Script Logic
# ===========================================================

print_banner_func "${Version}"

ALL_INSTALL=false
REMOVE_INSTALL=false

while getopts "halpr" opt; do
    case "$opt" in
        h) 
            usage
            ;;        a) 
            ALL_INSTALL=true
            ;;        p) 
            show_paths_func
            ;;        r) 
            REMOVE_INSTALL=true
            ;;        \?)
            msg "Invalid option: -$OPTARG" >&2
            usage
            ;;    esac
done
shift $((OPTIND-1))

# ===========================================================
# System Check
# ===========================================================
if [[ "$REMOVE_INSTALL" == "true" ]]; then
    remove_func
fi
msg "\n🔍 Checking System..."

check_sudo

CURRENT_OS=$(get_os)
if [[ "$CURRENT_OS" == "Linux" ]]; then
    [[ "$(uname -m)" != "x86_64" ]] && error "This script requires amd64 architecture on Linux."
elif [[ "$CURRENT_OS" == "macOS" ]]; then
    if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "arm64" ]]; then
        error "This script requires x86_64 or arm64 architecture on macOS."
    fi
fi

# Dependency install
CURRENT_OS=$(get_os)
PKG_MANAGER=$(get_pkg_manager)

if [[ "$CURRENT_OS" == "macOS" && "$PKG_MANAGER" == "brew" ]]; then
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew is not installed."
        if confirm "Install Homebrew now? (Requires sudo and internet connection)"; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Failed to install Homebrew."
            success "Homebrew installed."
        else
            error "Homebrew is required for macOS. Exiting."
        fi
    else
        success "Homebrew found."
    fi
fi

for tool in zsh curl git; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        warn "$tool is not installed."

        if confirm "Install $tool now?"; then
            case "$PKG_MANAGER" in
                apt)
                    sudo apt install -y "$tool" || error "Failed installing $tool."
                    ;;                dnf)
                    sudo dnf install -y "$tool" || error "Failed installing $tool."
                    ;;                pacman)
                    sudo pacman -Sy "$tool" --noconfirm || error "Failed installing $tool."
                    ;;                brew)
                    brew install "$tool" || error "Failed installing $tool."
                    ;;                *)
                    error "Unsupported distro or package manager. Install $tool manually."
                    ;;            esac

            success "$tool installed."
        else
            error "$tool required. Exiting."
        fi
    else
        success "$tool found."
    fi
done
# Internet Check
msg "🌐 Checking Internet..."
ping -c1 8.8.8.8 &>/dev/null || error "No Internet Connection."

# Write Check
[[ ! -w "$HOME" ]] && error "Home directory not writable."

success "System Check Passed."

# ===========================================================
# Cleanup Phase (with prompts)
# ===========================================================
msg "🧹 Checking Existing Zsh Installation..."

# Backup
if [[ -f "$ZSHRC" ]]; then
    if confirm "Create backup of .zshrc?"; then
        cp "$ZSHRC" "$BACKUP"
        success "Backup saved to ~/.zshrc.bak"
    else
        warn "Skipping .zshrc backup."
    fi
fi

# Clean plugins
msg "🔌 Checking for existing plugins..."

for plugin in "${plugins[@]}"; do
    plug_path="$ZSH_CUSTOM/plugins/$plugin"

    if [[ -d "$plug_path" ]]; then
        warn "Existing plugin found: $plugin"

        if confirm "Remove existing $plugin?"; then
            rm -rf "$plug_path"
            success "Removed: $plugin"
        else
            warn "Keeping existing: $plugin"
        fi
    fi
done

# Clean theme
theme_path="$ZSH_CUSTOM/themes/$theme"

if [[ -d "$theme_path" ]]; then
    warn "Existing Powerlevel10k found."

    if confirm "Remove existing Powerlevel10k theme?"; then
        rm -rf "$theme_path"
        success "Removed: Powerlevel10k"
    else
        warn "Keeping existing Powerlevel10k theme."
    fi
fi

# Clean .zshrc plugin entries
if grep -Eq "zsh-autosuggestions|zsh-syntax-highlighting|fast-syntax-highlighting|zsh-autocomplete|powerlevel10k" "$ZSHRC"; then
    warn "Old plugin entries found in .zshrc"

    if confirm "Clean old plugin/theme lines from .zshrc?"; then
        sed -i '/zsh-autosuggestions/d;/zsh-syntax-highlighting/d;/fast-syntax-highlighting/d;/zsh-autocomplete/d;/powerlevel10k/d' "$ZSHRC"
        success "Cleaned old entries."
    else
        warn "Keeping existing plugin entries."
    fi
fi

success "Cleanup Completed."

# ===========================================================
# Install Oh-My-Zsh
# ===========================================================
msg "🚀 Installing Oh-My-Zsh..."

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    warn "Oh-My-Zsh is already installed. Skipping installation."
else
    yes | CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Oh-My-Zsh install failed."
    success "Oh-My-Zsh Installed."
fi

# ===========================================================
# Plugin Selection
# ===========================================================
msg "🔧 Choose Plugin Setup:
1) Essentials (autosuggestions + syntax-highlighting)
2) All recommended plugins (default)
3) Skip plugin installation"

if [[ "$ALL_INSTALL" == "true" ]]; then
    msg "Automatically selecting all recommended plugins due to -all flag."
    choice="2"
else
    read -p "Enter choice (1/2/3): " choice
fi

case "$choice" in
    1) selected_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting") ;;
    3) selected_plugins=() ;;
    *) selected_plugins=("${plugins[@]}") ;;
esac

# ===========================================================
# Install Plugins
# ===========================================================
msg "📦 Installing Zsh Plugins..."

for plugin in "${selected_plugins[@]}"; do
    plug_path="$ZSH_CUSTOM/plugins/$plugin"
    repo=""
    case "$plugin" in
        zsh-autosuggestions)
            repo="https://github.com/zsh-users/zsh-autosuggestions" ;;
        zsh-syntax-highlighting)
            repo="https://github.com/zsh-users/zsh-syntax-highlighting" ;;
        fast-syntax-highlighting)
            repo="https://github.com/zdharma-continuum/fast-syntax-highlighting" ;;
        zsh-autocomplete)
            repo="https://github.com/marlonrichert/zsh-autocomplete" ;;
    esac

    if [[ -d "$plug_path" ]]; then
        warn "Plugin '$plugin' already exists. Skipping installation."
    else
        git clone --depth=1 "$repo" "$plug_path" || error "Failed installing $plugin"
        success "Installed plugin: $plugin"
    fi
done

# ===========================================================
# Install Theme
# ===========================================================
msg "🎨 Installing Powerlevel10k Theme..."
if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    warn "Powerlevel10k is already installed. Skipping installation."
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k" || error "Failed installing Powerlevel10k."
    success "Powerlevel10k Installed."
fi

# ===========================================================
# Modify .zshrc
# ===========================================================
msg "📝 Updating .zshrc..."

# Insert plugins
if grep -q "^plugins=(.*)" "$ZSHRC"; then
    sed -i -E "s/^(plugins=)\((.*)\)/\1(${selected_plugins[*]})/" "$ZSHRC"
else
    echo "plugins=(${selected_plugins[*]})" >> "$ZSHRC"
fi

# Remove any existing ZSH_THEME definitions
if grep -q "^ZSH_THEME=" "$ZSHRC"; then
    sed -i '/^ZSH_THEME=/d' "$ZSHRC"
fi

# Append the new ZSH_THEME definition
echo "ZSH_THEME=\"powerlevel10k/powerlevel10k\"" >> "$ZSHRC"


success ".zshrc Updated."

# ===========================================================
# Final Output
# ===========================================================
msg "🎉 Installation Complete!"

if [[ "$ALL_INSTALL" == "true" ]]; then
    msg "Powerlevel10k configuration skipped for non-interactive installation."
    msg "You can configure Powerlevel10k manually by running 'p10k configure' after restarting your shell."
else
    if confirm "Configure Powerlevel10k now?"; then
        msg "Starting Powerlevel10k configuration wizard..."
        p10k configure
        success "Powerlevel10k configured."
    fi
fi

echo -e "
${GREEN}✨ Your custom terminal setup is ready!${RESET}

📌 Backup: ~/.zshrc.bak  
📘 Log file: $LOG  
🎨 Theme: Powerlevel10k  
🔌 Plugins: ${selected_plugins[*]}

Restart your shell with:  ${CYAN}exec zsh${RESET}
"

if confirm "Set Zsh as your default shell (requires password)?"; then
    chsh -s "$(which zsh)" || warn "Failed to set Zsh as default shell. You may need to do it manually."
    success "Zsh set as default shell."
fi

if confirm "Restart shell now?"; then
    exec zsh
else
    msg "👍 Restart later to apply changes."
fi

exit 0
