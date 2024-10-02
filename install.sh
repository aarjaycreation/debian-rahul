#!/bin/bash

# Color codes for output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

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

# Prompt user to install dependencies that require sudo
echo -e "${YELLOW}Please ensure you have the following dependencies installed:${NC}"
echo -e "${YELLOW} - build-essential (for make and gcc)${NC}"
echo -e "${YELLOW} - libx11-dev, libxft-dev, libxinerama-dev (for DWM build)${NC}"
echo -e "${YELLOW} - picom, alacritty, rofi, kitty${NC}"
echo -e "${YELLOW}Run 'sudo apt install' for these if they are missing.${NC}"

# Create directories safely
mkdir -p "$CONFIG_DIR"
cd "$SCRIPTS_DIR" || { echo "Failed to change directory to $SCRIPTS_DIR"; exit 1; }

# Make sure all scripts are executable
chmod +x install_packages
chmod +x install_nala
chmod +x picom
./install_packages

# Moving dotfiles to the correct location
echo -e "${GREEN}---------------------------------------------------"
echo -e "       Moving dotfiles to correct location"
echo -e "---------------------------------------------------${NC}"

if [ -d "$DOTFILES_DIR" ]; then
    cp -r "$DOTFILES_DIR/alacritty" "$DOTFILES_DIR/backgrounds" "$DOTFILES_DIR/fastfetch" \
          "$DOTFILES_DIR/kitty" "$DOTFILES_DIR/picom" "$DOTFILES_DIR/rofi" \
          "$DOTFILES_DIR/suckless" "$DESTINATION/" || { echo -e "${RED}Failed to copy dotfiles.${NC}"; exit 1; }

    cp "$DOTFILES_DIR/.bashrc" "$USER_HOME/" || { echo -e "${RED}Failed to copy .bashrc.${NC}"; exit 1; }
    cp -r "$DOTFILES_DIR/.local" "$USER_HOME/" || { echo -e "${RED}Failed to copy .local directory.${NC}"; exit 1; }
    cp "$DOTFILES_DIR/.xinitrc" "$USER_HOME/" || { echo -e "${RED}Failed to copy .xinitrc.${NC}"; exit 1; }
else
    echo -e "${RED}Dotfiles directory does not exist.${NC}"
    exit 1
fi

echo -e "${GREEN}---------------------------------------------------"
echo -e "${GREEN}            Fixing Home dir permissions"
echo -e "${GREEN}---------------------------------------------------${NC}"

sudo chown -R "$USER":"$USER" "$USER_HOME/.config"
sudo chown -R "$USER":"$USER" "$USER_HOME/scripts"
sudo chown "$USER":"$USER" "$USER_HOME/.bashrc"
sudo chown -R "$USER":"$USER" "$USER_HOME/.local"
sudo chown "$USER":"$USER" "$USER_HOME/.xinitrc"

# echo -e "${GREEN}---------------------------------------------------"
# echo -e "${GREEN}                 Updating Timezone"
# echo -e "${GREEN}---------------------------------------------------${NC}"

# if command -v apt > /dev/null 2>&1; then
#     sudo dpkg-reconfigure tzdata
# else
#     echo -e "${YELLOW}Unable to detect APT. Skipping."
# fi

# echo -e "${GREEN}---------------------------------------------------"
# echo -e "${GREEN}            Building DWM and SLStatus"
# echo -e "${GREEN}---------------------------------------------------${NC}"

# cd "$HOME/.config/suckless/dwm"
# sudo make clean install 
# cd "$HOME/.config/suckless/slstatus"
# sudo make clean install 

# if [ $? -eq 0 ]; then
#     echo -e "${GREEN}Build completed successfully.${NC}"
# else
#     echo -e "${RED}Build failed. Check the log file for details: $LOG_FILE${NC}"
# fi

# echo -e "${GREEN}---------------------------------------------------"
# echo -e "${GREEN}Script finished successfully!${NC}"
# echo -e "${GREEN}It is recommended to log out and log back in for all changes to take effect.${NC}"
