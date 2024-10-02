#!/bin/bash

# Color codes for output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"  # No Color

# Define the escalation tool (sudo)
ESCALATION_TOOL="sudo"

echo -e "${YELLOW}Running script...${NC}"

# Define base directories
USER_HOME="$HOME"
CONFIG_DIR="$USER_HOME/.config"
SCRIPTS_DIR="$USER_HOME/debian-rahul/scripts"
DOTFILES_DIR="$USER_HOME/debian-rahul/dotfiles"
DESTINATION="$CONFIG_DIR"

# Ensure scripts directory exists and correct permissions
chown -R "$USER":"$USER" "$SCRIPTS_DIR"

echo -e "${GREEN}---------------------------------------------------"
echo -e "${GREEN}            Installing dependencies"
echo -e "${GREEN}---------------------------------------------------${NC}"

# Ensure required directories exist
mkdir -p "$CONFIG_DIR"
cd "$SCRIPTS_DIR" || { echo -e "${RED}Failed to change directory to $SCRIPTS_DIR${NC}"; exit 1; }

# Make sure all scripts are executable
chmod +x install_packages install_nala picom

# Execute the installation scripts
./install_packages

# Moving dotfiles to the correct location
echo -e "${GREEN}---------------------------------------------------"
echo -e "       Moving dotfiles to correct location"
echo -e "---------------------------------------------------${NC}"

if [ -d "$DOTFILES_DIR" ]; then
    # Check if each directory or file has already been copied before copying
    for dir in alacritty backgrounds fastfetch kitty picom rofi suckless; do
        if [ -d "$DOTFILES_DIR/$dir" ] && [ ! -d "$DESTINATION/$dir" ]; then
            echo -e "${YELLOW}Copying $dir...${NC}"
            cp -r "$DOTFILES_DIR/$dir" "$DESTINATION/" || { echo -e "${RED}Failed to copy $dir.${NC}"; exit 1; }
        else
            echo -e "${GREEN}$dir already exists in the destination. Skipping...${NC}"
        fi
    done

    # Check if the .bashrc file exists before copying
    if [ -f "$DOTFILES_DIR/.bashrc" ] && [ ! -f "$USER_HOME/.bashrc" ]; then
        echo -e "${YELLOW}Copying .bashrc...${NC}"
        cp "$DOTFILES_DIR/.bashrc" "$USER_HOME/" || { echo -e "${RED}Failed to copy .bashrc.${NC}"; exit 1; }
    else
        echo -e "${GREEN}.bashrc already exists in the destination. Skipping...${NC}"
    fi

    # Check if .local directory has already been copied
    if [ -d "$DOTFILES_DIR/.local" ] && [ ! -d "$USER_HOME/.local" ]; then
        echo -e "${YELLOW}Copying .local directory...${NC}"
        cp -r "$DOTFILES_DIR/.local" "$USER_HOME/" || { echo -e "${RED}Failed to copy .local directory.${NC}"; exit 1; }
    else
        echo -e "${GREEN}.local directory already exists. Skipping...${NC}"
    fi

    # Check if the .xinitrc file exists before copying
    if [ -f "$DOTFILES_DIR/.xinitrc" ] && [ ! -f "$USER_HOME/.xinitrc" ]; then
        echo -e "${YELLOW}Copying .xinitrc...${NC}"
        cp "$DOTFILES_DIR/.xinitrc" "$USER_HOME/" || { echo -e "${RED}Failed to copy .xinitrc.${NC}"; exit 1; }
    else
        echo -e "${GREEN}.xinitrc already exists in the destination. Skipping...${NC}"
    fi
else
    echo -e "${RED}Dotfiles directory does not exist.${NC}"
    exit 1
fi


echo -e "${GREEN}---------------------------------------------------"
echo -e "${GREEN}            Fixing Home dir permissions"
echo -e "${GREEN}---------------------------------------------------${NC}"

chown -R "$USER":"$USER" "$USER_HOME/.config"
chown "$USER":"$USER" "$USER_HOME/.bashrc"
chown -R "$USER":"$USER" "$USER_HOME/.local"
chown "$USER":"$USER" "$USER_HOME/.xinitrc"


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



# Helper function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

installFastfetch() {
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${NC}"

        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fastfetch
                ;;
            apt-get|apt|nala)
                # Download the latest Fastfetch .deb package
                curl -sSLo /tmp/fastfetch.deb https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
                
                # Install the .deb package using apt
                "$ESCALATION_TOOL" dpkg -i /tmp/fastfetch.deb || "$ESCALATION_TOOL" apt-get install -f -y
                
                # Remove the .deb package after installation
                rm /tmp/fastfetch.deb
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Fastfetch is already installed.${NC}"
    fi
}



setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Copying Fastfetch config files...${RC}"
    if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
        cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
}



installAlacritty() {
    if ! command_exists alacritty; then
        printf "%b\n" "${YELLOW}Installing Alacritty...${NC}"

        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm alacritty
                ;;
            apt-get|apt|nala)
                # Add Alacritty PPA if necessary for Debian-based systems
                if ! grep -q "^deb .*/ppa.launchpad.net/alacritty" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
                    sudo add-apt-repository ppa:aslatter/ppa -y
                    sudo apt-get update
                fi
                "$ESCALATION_TOOL" "$PACKAGER" install -y alacritty
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y alacritty
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Alacritty is already installed.${NC}"
    fi
}


setupAlacrittyConfig() {
    printf "%b\n" "${YELLOW}Copying alacritty config files...${RC}"
    if [ -d "${HOME}/.config/alacritty" ] && [ ! -d "${HOME}/.config/alacritty-bak" ]; then
        cp -r "${HOME}/.config/alacritty" "${HOME}/.config/alacritty-bak"
    fi
    mkdir -p "${HOME}/.config/alacritty/"
    curl -sSLo "${HOME}/.config/alacritty/alacritty.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/alacritty.toml"
    curl -sSLo "${HOME}/.config/alacritty/keybinds.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/keybinds.toml"
    curl -sSLo "${HOME}/.config/alacritty/nordic.toml" "https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/alacritty/nordic.toml"
    printf "%b\n" "${GREEN}Alacritty configuration files copied.${RC}"
}


installStarshipAndFzf() {
    if command_exists starship; then
        printf "%b\n" "${GREEN}Starship already installed${RC}"
        return
    fi

    if ! curl -sSL https://starship.rs/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during starship install!${RC}"
        exit 1
    fi
    if command_exists fzf; then
        printf "%b\n" "${GREEN}Fzf already installed${RC}"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        "$ESCALATION_TOOL" ~/.fzf/install
    fi
}

installZoxide() {
    if command_exists zoxide; then
        printf "%b\n" "${GREEN}Zoxide already installed${RC}"
        return
    fi

    if ! curl -sSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh; then
        printf "%b\n" "${RED}Something went wrong during zoxide install!${RC}"
        exit 1
    fi
}


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





# Function to detect package manager
detect_package_manager() {
    if command -v dnf >/dev/null 2>&1; then
        PACKAGER="dnf"
    elif command -v apt-get >/dev/null 2>&1; then
        PACKAGER="apt-get"
    elif command -v nala >/dev/null 2>&1; then
        PACKAGER="nala"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGER="pacman"
    else
        echo -e "${RED}Unsupported package manager. Please install Xorg manually.${NC}"
        exit 1
    fi
}

setupDisplayManager() {
    # Detect the package manager
    detect_package_manager

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







# Main script execution
# install_Dwm
# install_slstatus


installFastfetch
# setupFastfetchConfig

installAlacritty
# setupAlacrittyConfig

installStarshipAndFzf
installZoxide

install_nerd_font
picom_animations
# configure_backgrounds
# setupDisplayManager
