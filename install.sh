#!/bin/bash

# Color codes for output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"  # No Color

# Function to ensure the script is run with sudo privileges
check_sudo() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}This script must be run as root or with sudo privileges.${NC}"
        exit 1
    fi
}

# Function to check if the user is in the sudoers list
check_sudo_user() {
    SUDO_USER=$(whoami)

    if sudo -l -U "$SUDO_USER" &> /dev/null; then
        echo -e "${GREEN}User $SUDO_USER has sudo privileges.${NC}"
    else
        echo -e "${RED}User $SUDO_USER does not have sudo privileges.${NC}"
        exit 1
    fi
}

# Function to prompt for a sudo user if needed
set_sudo_user() {
    echo -e "${YELLOW}The script needs to run with sudo privileges.${NC}"
    read -p "Enter the sudo user [default: $USER]: " sudo_user_input
    SUDO_USER=${sudo_user_input:-$USER}

    # Check if the entered user has sudo privileges
    if sudo -l -U "$SUDO_USER" &> /dev/null; then
        echo -e "${GREEN}User $SUDO_USER is a sudo user.${NC}"
    else
        echo -e "${RED}User $SUDO_USER does not have sudo privileges. Exiting.${NC}"
        exit 1
    fi
}

# Ensure the script is running with sudo privileges
check_sudo

# Prompt for and set sudo user if not already set
set_sudo_user

# Define the escalation tool (sudo)
ESCALATION_TOOL="sudo -u $SUDO_USER"

echo -e "${YELLOW}Running script as $SUDO_USER...${NC}"

# Define base directories
USER_HOME="/home/$SUDO_USER"
CONFIG_DIR="$USER_HOME/.config"
SCRIPTS_DIR="$USER_HOME/debian-rahul/scripts"
DOTFILES_DIR="$USER_HOME/debian-rahul/dotfiles"
DESTINATION="$CONFIG_DIR"

# Ensure scripts directory exists and correct permissions
sudo chown -R "$SUDO_USER":"$SUDO_USER" "$SCRIPTS_DIR"

echo -e "${GREEN}---------------------------------------------------"
echo -e "${GREEN}            Installing dependencies"
echo -e "${GREEN}---------------------------------------------------${NC}"

# Ensure required directories exist
sudo -u "$SUDO_USER" mkdir -p "$CONFIG_DIR"
cd "$SCRIPTS_DIR" || { echo -e "${RED}Failed to change directory to $SCRIPTS_DIR${NC}"; exit 1; }

# Make sure all scripts are executable
sudo chmod +x install_packages install_nala picom

# Execute the installation scripts
sudo -u "$SUDO_USER" ./install_packages

# Moving dotfiles to the correct location
echo -e "${GREEN}---------------------------------------------------"
echo -e "       Moving dotfiles to correct location"
echo -e "---------------------------------------------------${NC}"

if [ -d "$DOTFILES_DIR" ]; then
    sudo -u "$SUDO_USER" cp -r "$DOTFILES_DIR/alacritty" "$DOTFILES_DIR/backgrounds" "$DOTFILES_DIR/fastfetch" \
          "$DOTFILES_DIR/kitty" "$DOTFILES_DIR/picom" "$DOTFILES_DIR/rofi" \
          "$DOTFILES_DIR/suckless" "$DESTINATION/" || { echo -e "${RED}Failed to copy dotfiles.${NC}"; exit 1; }

    sudo -u "$SUDO_USER" cp "$DOTFILES_DIR/.bashrc" "$USER_HOME/" || { echo -e "${RED}Failed to copy .bashrc.${NC}"; exit 1; }
    sudo -u "$SUDO_USER" cp -r "$DOTFILES_DIR/.local" "$USER_HOME/" || { echo -e "${RED}Failed to copy .local directory.${NC}"; exit 1; }
    sudo -u "$SUDO_USER" cp "$DOTFILES_DIR/.xinitrc" "$USER_HOME/" || { echo -e "${RED}Failed to copy .xinitrc.${NC}"; exit 1; }
else
    echo -e "${RED}Dotfiles directory does not exist.${NC}"
    exit 1
fi

echo -e "${GREEN}---------------------------------------------------"
echo -e "${GREEN}            Fixing Home dir permissions"
echo -e "${GREEN}---------------------------------------------------${NC}"

sudo chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.config"
sudo chown "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.bashrc"
sudo chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.local"
sudo chown "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.xinitrc"


# Function to install Meslo Nerd Fonts
install_nerd_font() {
    FONT_DIR="$HOME/.local/share/fonts"
    FONT_ZIP="$FONT_DIR/Meslo.zip"
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    FONT_INSTALLED=$(fc-list | grep -i "Meslo")

    if [ -n "$FONT_INSTALLED" ]; then
        printf "%b\n" "${GREEN}Meslo Nerd-fonts are already installed.${NC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Meslo Nerd-fonts${NC}"

    mkdir -p "$FONT_DIR"
    curl -sSLo "$FONT_ZIP" "$FONT_URL" || { printf "%b\n" "${RED}Failed to download Meslo Nerd-fonts.${NC}"; return 1; }
    unzip "$FONT_ZIP" -d "$FONT_DIR" || { printf "%b\n" "${RED}Failed to unzip Meslo Nerd-fonts.${NC}"; return 1; }
    rm "$FONT_ZIP"
    fc-cache -fv || { printf "%b\n" "${RED}Failed to rebuild font cache.${NC}"; return 1; }

    printf "%b\n" "${GREEN}Meslo Nerd-fonts installed successfully${NC}"
}

# Function to install picom animations
picom_animations() {
    mkdir -p "$HOME/.local/share/"
    if [ ! -d "$HOME/.local/share/ftlabs-picom" ]; then
        git clone https://github.com/FT-Labs/picom.git "$HOME/.local/share/ftlabs-picom" || { printf "%b\n" "${RED}Failed to clone picom repository.${NC}"; return 1; }
    else
        printf "%b\n" "${GREEN}Picom repository already exists, skipping clone.${NC}"
    fi

    cd "$HOME/.local/share/ftlabs-picom" || { printf "%b\n" "${RED}Failed to change directory to picom${NC}"; return 1; }
    meson setup --buildtype=release build || { printf "%b\n" "${RED}Meson setup failed${NC}"; return 1; }
    ninja -C build || { printf "%b\n" "${RED}Ninja build failed${NC}"; return 1; }
    "$ESCALATION_TOOL" ninja -C build install || { printf "%b\n" "${RED}Failed to install picom${NC}"; return 1; }

    printf "%b\n" "${GREEN}Picom animations installed successfully${NC}"
}

# Function to configure backgrounds
configure_backgrounds() {
    PIC_DIR="$HOME/Pictures"
    BG_DIR="$PIC_DIR/backgrounds"

    mkdir -p "$PIC_DIR"

    if [ ! -d "$BG_DIR" ]; then
        git clone https://github.com/ChrisTitusTech/nord-background.git "$PIC_DIR/nord-background" || { printf "%b\n" "${RED}Failed to clone backgrounds repository${NC}"; return 1; }
        mv "$PIC_DIR/nord-background" "$BG_DIR"
    else
        printf "%b\n" "${GREEN}Backgrounds directory already exists, skipping download.${NC}"
    fi
}

# Function to set up the display manager
setupDisplayManager() {
    printf "%b\n" "${YELLOW}Setting up Xorg${NC}"
    case "$PACKAGER" in
        pacman) "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm xorg-xinit xorg-server ;;
        apt-get|apt|nala) "$ESCALATION_TOOL" "$PACKAGER" install -y xorg xinit ;;
        dnf) "$ESCALATION_TOOL" "$PACKAGER" install -y xorg-x11-xinit xorg-x11-server-Xorg ;;
        *) printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${NC}"; exit 1 ;;
    esac

    printf "%b\n" "${GREEN}Xorg installed successfully${NC}"
    printf "%b\n" "${YELLOW}Setting up Display Manager${NC}"
    currentdm="none"
    for dm in gdm sddm lightdm; do
        if systemctl is-active --quiet "$dm.service"; then
            currentdm="$dm"
            break
        fi
    done

    if [ "$currentdm" = "none" ]; then
        printf "%b\n" "${YELLOW}Pick your Display Manager${NC}"
        printf "%b\n" "${YELLOW}1. SDDM${NC}"
        printf "%b\n" "${YELLOW}2. LightDM${NC}"
        printf "%b\n" "${YELLOW}3. GDM${NC}"
        printf "%b\n" "${YELLOW}Please select one: ${NC}"
        read -r DM
        case "$DM" in
            1) DM="sddm" ;;
            2) DM="lightdm" ;;
            3) DM="gdm" ;;
            *) printf "%b\n" "${RED}Invalid option${NC}"; exit 1 ;;
        esac
        "$ESCALATION_TOOL" "$PACKAGER" install -y "$DM"
        systemctl enable "$DM"
    fi
}

# Function to install dwm
install_Dwm() {
    printf "Do you want to install dwm? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "%b\n" "${YELLOW}Installing dwm${NC}"
        cd "$HOME/.config/suckless/dwm" || { printf "%b\n" "${RED}Failed to change directory to dwm${NC}"; return 1; }
        "$ESCALATION_TOOL" make clean install || { printf "%b\n" "${RED}Failed to install dwm${NC}"; return 1; }
        printf "%b\n" "${GREEN}dwm installed successfully${NC}"
    else
        printf "%b\n" "${GREEN}Skipping dwm installation${NC}"
    fi
}

# Function to install slstatus
install_slstatus() {
    printf "Do you want to install slstatus? (y/N): "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "%b\n" "${YELLOW}Installing slstatus${NC}"
        cd "$HOME/.config/suckless/slstatus" || { printf "%b\n" "${RED}Failed to change directory to slstatus${NC}"; return 1; }
        "$ESCALATION_TOOL" make clean install || { printf "%b\n" "${RED}Failed to install slstatus${NC}"; return 1; }
        printf "%b\n" "${GREEN}slstatus installed successfully${NC}"
    else
        printf "%b\n" "${GREEN}Skipping slstatus installation${NC}"
    fi
}

# Main script execution
install_Dwm
install_slstatus
install_nerd_font
picom_animations
configure_backgrounds
setupDisplayManager
