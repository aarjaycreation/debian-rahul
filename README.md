# Rahul's Debian Post Installation Scripts

### Overview
This repository contains my personal **post-installation scripts** and dotfiles designed to streamline the setup of a minimal Linux environment. These scripts are tailored for **Debian-based systems**, but they can be used on other Linux distributions with the inclusion of **Linutil**.

The setup includes configuring **DWM (Dynamic Window Manager)**, **SLStatus** for a customizable status bar, and essential utilities for a clean, efficient, and bloat-free environment. The entire process is automated and can be completed in **under 3 minutes**.

### Key Features:
- Fully automated installation and setup of **DWM**, **SLStatus**, and core utilities.
- Designed for Debian but adaptable to other Linux distributions.
- Customizable DWM status bar with useful modules (battery, time, network, etc.).
- Minimalist and efficient setup for developers and power users.

### Demo
Here is an example of the script’s output:


### Prerequisites
Before running the installation script, ensure that the necessary build dependencies are installed:

- **For Debian-based systems:**
  ```bash
  sudo apt update && sudo apt install gcc make libx11-dev libxft-dev libxinerama-dev



## Instructions

1. Clone the repository:

```bash
git clone https://github.com/aarjaycreation/debian-rahul
```
2. Navigate to the cloned directory:
```bash
cd debian-rahul

```

3. Run the installation script:
```bash
./install.sh
```


## Credit
- Inspired by various community-driven Linux automation projects.
- Special thanks to ChrisTitusTech for Linutil, which makes cross-distro compatibility easier.


