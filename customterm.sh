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
LOG="$USER_HOME/customterm.logs"
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
    echo -e "\n${YELLOW}Usage:${RESET} ${CYAN}$(basename "$0") [-h] [-a] [-p] [-r] [-R]${RESET}"
    echo -e "  ${GREEN}-h:${RESET} Display this help message."
    echo -e "  ${GREEN}-a:${RESET} Perform a non-interactive with all recommended settings."
    echo -e "  ${GREEN}-p:${RESET} Show important paths (e.g., .zshrc, plugin directory)."
    echo -e "  ${GREEN}-r:${RESET} Remove Oh-My-Zsh, plugins, theme, and clean .zshrc."
    echo -e "  ${GREEN}-R:${RESET} Also install for the root user (requires sudo)."
    echo ""
    echo -e "${YELLOW}Examples:${RESET}"
    echo -e "  ${CYAN}$(basename "$0") -h${RESET}"
    echo -e "  ${CYAN}sudo $(basename "$0") -a${RESET}"
    echo -e "  ${CYAN}$(basename "$0") -p${RESET}"
    echo -e "  ${CYAN}sudo $(basename "$0") -r${RESET}"
    echo -e "  ${CYAN}sudo $(basename "$0") -a -R${RESET}"
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
# Installation Function
# ===========================================================
install_zsh_config() {
    local target_user_home="$1"
    local target_username="$2"

    msg "\n${CYAN}--- Configuring Zsh for user: $target_username in $target_user_home ---${RESET}"

    local current_zshrc="$target_user_home/.zshrc"
    local current_backup="$target_user_home/.zshrc.bak"
    local current_zsh_custom="${target_user_home}/.oh-my-zsh/custom"

    # ===========================================================
    # Cleanup Phase (with prompts)
    # ===========================================================
    msg "🧹 Checking Existing Zsh Installation for $target_username..."

    # Backup
    if [[ -f "$current_zshrc" ]]; then
        if confirm "Create backup of $current_zshrc?"; then
            # Use sudo for cp if target_username is root
            if [[ "$target_username" == "root" ]]; then
                sudo cp "$current_zshrc" "$current_backup"
            else
                cp "$current_zshrc" "$current_backup"
            fi
            success "Backup saved to $current_backup"
        else
            warn "Skipping $current_zshrc backup."
        fi
    fi

    # Clean plugins
    msg "🔌 Checking for existing plugins for $target_username..."

    for plugin in "${plugins[@]}"; do
        plug_path="$current_zsh_custom/plugins/$plugin"

        if [[ -d "$plug_path" ]]; then
            warn "Existing plugin found: $plugin for $target_username"

            if confirm "Remove existing $plugin for $target_username?"; then
                # Use sudo for rm if target_username is root
                if [[ "$target_username" == "root" ]]; then
                    sudo rm -rf "$plug_path"
                else
                    rm -rf "$plug_path"
                fi
                success "Removed: $plugin for $target_username"
            else
                warn "Keeping existing: $plugin for $target_username"
            fi
        fi
    done

    # Clean theme
    theme_path="$current_zsh_custom/themes/$theme"

    if [[ -d "$theme_path" ]]; then
        warn "Existing Powerlevel10k found for $target_username."

        if confirm "Remove existing Powerlevel10k theme for $target_username?"; then
            # Use sudo for rm if target_username is root
            if [[ "$target_username" == "root" ]]; then
                sudo rm -rf "$theme_path"
            else
                rm -rf "$theme_path"
            fi
            success "Removed: Powerlevel10k for $target_username"
        else
            warn "Keeping existing Powerlevel10k theme for $target_username."
        fi
    fi

    # Clean .zshrc plugin entries
    if grep -Eq "zsh-autosuggestions|zsh-syntax-highlighting|fast-syntax-highlighting|zsh-autocomplete|powerlevel10k" "$current_zshrc" 2>/dev/null; then
        warn "Old plugin entries found in $current_zshrc"

        if confirm "Clean old plugin/theme lines from $current_zshrc?"; then
            # Use sudo for sed if target_username is root
            if [[ "$target_username" == "root" ]]; then
                sudo sed -i '/zsh-autosuggestions/d;/zsh-syntax-highlighting/d;/fast-syntax-highlighting/d;/zsh-autocomplete/d;/powerlevel10k/d' "$current_zshrc"
            else
                sed -i '/zsh-autosuggestions/d;/zsh-syntax-highlighting/d;/fast-syntax-highlighting/d;/zsh-autocomplete/d;/powerlevel10k/d' "$current_zshrc"
            fi
            success "Cleaned old entries in $current_zshrc."
        else
            warn "Keeping existing plugin entries in $current_zshrc."
        fi
    fi

    success "Cleanup Completed for $target_username."



    # ===========================================================
    # Plugin Installation (uses global selected_plugins)
    # ===========================================================
    # Define plugin repositories (uses global PLUGIN_REPOS)
    # Define theme repository (uses global THEME_REPO)

    for plugin in "${selected_plugins[@]}"; do
        plug_path="$current_zsh_custom/plugins/$plugin"
        repo="${PLUGIN_REPOS[$plugin]}" # Get repo URL from associative array

        if [[ -z "$repo" ]]; then
            warn "Repository URL not defined for plugin: $plugin. Skipping."
            continue
        fi

        if [[ -d "$plug_path" ]]; then
            warn "Plugin '$plugin' already exists for $target_username. Skipping installation."
        else
            # Use sudo -u for the target user if not root, otherwise just run as root
            if [[ "$target_username" == "root" ]]; then
                git clone --depth=1 "$repo" "$plug_path" || error "Failed installing $plugin for $target_username"
            else
                sudo -u "$target_username" git clone --depth=1 "$repo" "$plug_path" || error "Failed installing $plugin for $target_username"
            fi
            success "Installed plugin: $plugin for $target_username"
        fi
    done

    # ===========================================================
    # Install Theme
    # ===========================================================
    msg "🎨 Installing Powerlevel10k Theme for $target_username..."
    if [[ -d "$current_zsh_custom/themes/powerlevel10k" ]]; then
        warn "Powerlevel10k is already installed for $target_username. Skipping installation."
    else
        # Use sudo -u for the target user if not root, otherwise just run as root
        if [[ "$target_username" == "root" ]]; then
            git clone --depth=1 "$THEME_REPO" \
            "$current_zsh_custom/themes/powerlevel10k" || error "Failed installing Powerlevel10k for $target_username."
        else
            sudo -u "$target_username" git clone --depth=1 "$THEME_REPO" \
            "$current_zsh_custom/themes/powerlevel10k" || error "Failed installing Powerlevel10k for $target_username."
        fi
        success "Powerlevel10k Installed for $target_username."
    fi

    # ===========================================================
    # Modify .zshrc
    # ===========================================================
    msg "📝 Updating $current_zshrc..."

    # --- Restore original .zshrc if a backup exists ---
    if [[ -f "$current_backup" ]]; then
        msg "Restoring original $current_zshrc from backup to preserve custom settings..."
        # Use sudo for cp if target_username is root
        if [[ "$target_username" == "root" ]]; then
            sudo cp "$current_backup" "$current_zshrc"
        else
            cp "$current_backup" "$current_zshrc"
        fi
        success "Original $current_zshrc restored."
    fi

    # --- Ensure Oh-My-Zsh required lines are present ---

    # 1. Set ZSH environment variable
    OMZ_PATH_STR="export ZSH=\"$target_user_home/.oh-my-zsh\""
    if ! grep -qF 'export ZSH=' "$current_zshrc" 2>/dev/null; then
        msg "Adding ZSH environment variable to $current_zshrc..."
        # Prepend to the file safely, use sudo for tee if target_username is root
        if [[ "$target_username" == "root" ]]; then
            echo -e "$OMZ_PATH_STR\n" | sudo tee "${current_zshrc}.tmp" > /dev/null && sudo mv "${current_zshrc}.tmp" "$current_zshrc"
        else
            echo -e "$OMZ_PATH_STR\n" | cat - "$current_zshrc" > "${current_zshrc}.tmp" && mv "${current_zshrc}.tmp" "$current_zshrc"
        fi
        success "ZSH variable set in $current_zshrc."
    fi

    # 2. Set ZSH_THEME
    # Remove any existing ZSH_THEME definitions to avoid conflicts
    if [[ "$target_username" == "root" ]]; then
        sudo sed -i '/^ZSH_THEME=/d' "$current_zshrc"
    else
        sed -i '/^ZSH_THEME=/d' "$current_zshrc"
    fi
    # Add our theme, preferably before plugins are sourced
    THEME_STR="ZSH_THEME=\"powerlevel10k/powerlevel10k\""
    if grep -q "oh-my-zsh.sh" "$current_zshrc" 2>/dev/null; then
        # Insert before the source line for better organization
        if [[ "$target_username" == "root" ]]; then
            sudo sed -i "/oh-my-zsh.sh/i $THEME_STR" "$current_zshrc"
        else
            sed -i "/oh-my-zsh.sh/i $THEME_STR" "$current_zshrc"
        fi
    else
        # Append if source line not found (fallback)
        if [[ "$target_username" == "root" ]]; then
            echo "$THEME_STR" | sudo tee -a "$current_zshrc" > /dev/null
        else
            echo "$THEME_STR" >> "$current_zshrc"
        fi
    fi
    success "Powerlevel10k theme configured in $current_zshrc."


    # 3. Set plugins
    PLUGIN_STR="plugins=(${selected_plugins[*]})"

    # Remove any existing plugins=(...) lines to ensure a clean insertion
    if [[ "$target_username" == "root" ]]; then
        sudo sed -i '/^plugins=(.*)/d' "$current_zshrc"
    else
        sed -i '/^plugins=(.*)/d' "$current_zshrc"
    fi

    # Insert the new plugins line before the source line, or append if source not found
    if grep -q "oh-my-zsh.sh" "$current_zshrc" 2>/dev/null; then
        if [[ "$target_username" == "root" ]]; then
            sudo sed -i "/oh-my-zsh.sh/i $PLUGIN_STR" "$current_zshrc"
        else
            sed -i "/oh-my-zsh.sh/i $PLUGIN_STR" "$current_zshrc"
        fi
    else
        if [[ "$target_username" == "root" ]]; then
            echo "$PLUGIN_STR" | sudo tee -a "$current_zshrc" > /dev/null
        else
            echo "$PLUGIN_STR" >> "$current_zshrc"
        fi
    fi
    success "Updated plugin list in $current_zshrc."

    # 4. Source Oh-My-Zsh
    OMZ_SOURCE_STR="source \"\$ZSH/oh-my-zsh.sh\""
    if ! grep -q "oh-my-zsh.sh" "$current_zshrc" 2>/dev/null; then
        msg "Adding Oh-My-Zsh source line to $current_zshrc..."
        if [[ "$target_username" == "root" ]]; then
            echo -e "\n# Load Oh-My-Zsh\n$OMZ_SOURCE_STR" | sudo tee -a "$current_zshrc" > /dev/null
        else
            echo -e "\n# Load Oh-My-Zsh\n$OMZ_SOURCE_STR" >> "$current_zshrc"
        fi
        success "Oh-My-Zsh will be sourced in $current_zshrc."
    fi

    success "$current_zshrc Updated."

    # Set Zsh as default shell for the target user
    if confirm "Set Zsh as default shell for $target_username (requires password)?"; then
        if [[ "$target_username" == "root" ]]; then
            chsh -s "$(which zsh)" root || warn "Failed to set Zsh as default shell for root. You may need to do it manually."
        else
            chsh -s "$(which zsh)" "$target_username" || warn "Failed to set Zsh as default shell for $target_username. You may need to do it manually."
        fi
        success "Zsh set as default shell for $target_username."
    fi

}

# ===========================================================
# Main Script Logic
# ===========================================================

print_banner_func "${Version}"

ALL_INSTALL=false
REMOVE_INSTALL=false
ROOT_INSTALL=false

while getopts "halprR" opt; do
    case "$opt" in
        h) 
            usage
            ;;        a) 
            ALL_INSTALL=true
            ;;        p) 
            show_paths_func
            ;;        r) 
            REMOVE_INSTALL=true
            ;;        R)
            ROOT_INSTALL=true
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

# Collect missing tools

declare -a MISSING_TOOLS

for tool in zsh curl git; do

    if ! command -v "$tool" >/dev/null 2>&1; then

        MISSING_TOOLS+=("$tool")

    fi

done



if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then

    warn "The following required tools are not installed: ${MISSING_TOOLS[*]}"

    if confirm "Install missing tools now?"; then

        msg "Attempting to install missing tools..."



        # Perform package manager update if necessary

        case "$PKG_MANAGER" in

            apt)

                msg "Updating apt package lists..."

                sudo apt update || warn "Failed to update apt package lists. Installation might fail."

                ;;

            pacman)

                msg "Synchronizing pacman databases..."

                sudo pacman -Sy --noconfirm || warn "Failed to synchronize pacman databases. Installation might fail."

                ;;

            brew)

                msg "Updating Homebrew..."

                brew update || warn "Failed to update Homebrew. Installation might fail."

                ;;

        esac



        # Attempt to install all missing tools

        INSTALL_COMMAND=""

        case "$PKG_MANAGER" in

            apt)

                INSTALL_COMMAND="sudo apt install -y ${MISSING_TOOLS[*]}"

                ;;

            dnf)

                INSTALL_COMMAND="sudo dnf install -y ${MISSING_TOOLS[*]}"

                ;;

            pacman)

                INSTALL_COMMAND="sudo pacman -S --noconfirm ${MISSING_TOOLS[*]}"

                ;;

            brew)

                INSTALL_COMMAND="brew install ${MISSING_TOOLS[*]}"

                ;;

            *)

                error "Unsupported distro or package manager. Please install: ${MISSING_TOOLS[*]} manually."

                ;;

        esac



        if [[ -n "$INSTALL_COMMAND" ]]; then

            if eval "$INSTALL_COMMAND"; then

                success "Successfully installed: ${MISSING_TOOLS[*]}"

            else

                error "Installation command failed for required tools: ${MISSING_TOOLS[*]}. Please check the output above for details or install them manually. Command attempted: '$INSTALL_COMMAND'"

            fi

        fi

    else

        error "Required tools (${MISSING_TOOLS[*]}) are not installed. Exiting."

    fi

else

    success "All required tools (zsh, curl, git) found."

fi
# Internet Check
msg "🌐 Checking Internet..."
ping -c1 8.8.8.8 &>/dev/null || error "No Internet Connection."

# Write Check
[[ ! -w "$HOME" ]] && error "Home directory not writable."

success "System Check Passed."









# ===========================================================
# Plugin Selection
# ===========================================================
msg "🔧 Choose Plugin Setup:
1) Essentials (autosuggestions + syntax-highlighting)
2) All recommended plugins (default)
3) Skip plugin installation"

if [[ "$ALL_INSTALL" == "true" ]]; then
    msg "Automatically selecting all recommended plugins due to -a flag."
    choice="2"
else
    read -p "Enter choice (1/2/3): " choice
fi

case "$choice" in
    1) selected_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting") ;;
    3) selected_plugins=() ;;
    *) selected_plugins=("${plugins[@]}") ;;
esac

# Define plugin repositories
declare -A PLUGIN_REPOS
PLUGIN_REPOS["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
PLUGIN_REPOS["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
PLUGIN_REPOS["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
PLUGIN_REPOS["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete"

# Define theme repository
THEME_REPO="https://github.com/romkatv/powerlevel10k.git"

# ===========================================================
# Install Oh-My-Zsh and Configure for Primary User
# ===========================================================
msg "🚀 Installing Oh-My-Zsh for primary user..."
if [[ -d "$USER_HOME/.oh-my-zsh" ]]; then
    warn "Oh-My-Zsh is already installed for primary user. Skipping installation."
else
    if [[ -n "$SUDO_USER" && "$UID" == "0" ]]; then
        # Script run with sudo, install for SUDO_USER
        yes | CHSH=no RUNZSH=no sudo -u "$SUDO_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Oh-My-Zsh install failed for primary user."
    else
        # Script run directly by user
        yes | CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Oh-My-Zsh install failed for primary user."
    fi
    success "Oh-My-Zsh Installed for primary user."
fi
install_zsh_config "$USER_HOME" "$SUDO_USER"

# ===========================================================
# Install Oh-My-Zsh and Configure for Root User (if -R specified)
# ===========================================================
if [[ "$ROOT_INSTALL" == "true" ]]; then
    msg "🚀 Installing Oh-My-Zsh for root user..."
    if [[ -d "/root/.oh-my-zsh" ]]; then
        warn "Oh-My-Zsh is already installed for root user. Skipping installation."
    else
        # Always run as root for root's installation
        yes | CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || error "Oh-My-Zsh install failed for root user."
        success "Oh-My-Zsh Installed for root user."
    fi
    install_zsh_config "/root" "root"
fi

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
        # This needs to be run as the current user, not necessarily the target user of the install_zsh_config function
        # So we use the global ZSH_CUSTOM here.
        "$ZSH_CUSTOM/themes/powerlevel10k/gitstatus/bin/p10k" configure
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

if confirm "Restart shell now?"; then
    exec zsh
else
    msg "👍 Restart later to apply to changes."
fi

exit 0
