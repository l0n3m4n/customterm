
<h1 align="center">
Customterm 
</h1>

<p align="center">
    <a href="https://visitorbadge.io/status?path=https%3A%2F%2Fgithub.com%2Fl0n3m4n%2Fcustom-terminal">
    <img src="https://api.visitorbadge.io/api/visitors?path=https%3A%2F%2Fgithub.com%2Fl0n3m4n%2Fcustom-terminal&label=Visitors&countColor=%2337d67a" />
    </a>
    <a href="https://www.facebook.com/l0n3m4n">
        <img src="https://img.shields.io/badge/Facebook-%231877F2.svg?style=for-the-badge&logo=Facebook&logoColor=white" alt="Facebook">
    </a>
      <a href="https://www.twitter.com/l0n3m4n">
        <img src="https://img.shields.io/badge/Twitter-%23000000.svg?style=for-the-badge&logo=X&logoColor=white" alt="X">
    </a>
    <a href="https://medium.com/@l0n3m4n">
        <img src="https://img.shields.io/badge/Medium-12100E?style=for-the-badge&logo=medium&logoColor=white" alt="Medium">
    </a>
    <a href="https://www.kali.org/">
    <img src="https://img.shields.io/badge/Kali-268BEE?style=for-the-badge&logo=kalilinux&logoColor=white" alt="Kali">      
    </a>
</p>

This script automates the setup of a custom Zsh terminal environment for both Linux and macOS...

## Features

*   Automated installation of Zsh, curl, and git (if not already present).
*   Checks for amd64 architecture.
*   Checks for internet connectivity and home directory writability.
*   Automated installation of Oh-My-Zsh.
*   Installs Powerlevel10k theme.
*   Installs selected Zsh plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fast-syntax-highlighting`, and `zsh-autocomplete`.
*   Manages `.zshrc` configuration, including backup options.
*   Idempotent installations: gracefully handles existing installations of Oh-My-Zsh and plugins.
*   Sudo access check for dependency installation.

## Getting Started
![logo](assets/banner.png)
### Prerequisites

*   A Linux distribution (tested on Debian/Ubuntu, Fedora, Arch-based systems) or macOS.
*   `sudo` privileges for installing system dependencies (Linux only).
*   Homebrew (for macOS users): The script will prompt to install it if not found.
*   An active internet connection.
### Installation

1.  **Clone the repository (or download the script):**
    ```bash
    git clone https://github.com/l0n3m4n/customterm.git
    cd customterm
    ```
    or simply download the `customterm.sh` script:
    ```bash
    curl -o customterm.sh https://raw.githubusercontent.com/l0n3m4n/customterm/refs/heads/main/customterm.sh
    chmod +x customterm.sh
    ```

2.  **Run the script:**
```bash
# run script
➜  customterm ./customterm.sh -a

             _             _                 
 ___ _ _ ___| |_ ___ _____| |_ ___ ___ _____ 
|  _| | |_ -|  _| . |     |  _| -_|  _|     |
|___|___|___|_| |___|_|_|_|_| |___|_| |_|_|_|
        author: l0n3m4n | version:v1.0.0

🔍 Checking System...
🔑 Checking sudo access...
✔ Sudo access confirmed.
✔ zsh found.
✔ curl found.
✔ git found.
🌐 Checking Internet...
```
```bash
# help menu
➜  customterm ./customterm.sh -h 

             _             _                 
 ___ _ _ ___| |_ ___ _____| |_ ___ ___ _____ 
|  _| | |_ -|  _| . |     |  _| -_|  _|     |
|___|___|___|_| |___|_|_|_|_| |___|_| |_|_|_|
        author: l0n3m4n | version:v1.0.0

Usage: customterm.sh [-h] [-all] [-p] [-r]
  -h: Display this help message.
  -a: Perform a non-interactive installation with all recommended settings.
  -p: Show important paths \(e.g., .zshrc, custom plugin directory\).
  -r: Remove Oh-My-Zsh, plugins, theme, and clean .zshrc.

Examples:
  customterm.sh -h
  sudo customterm.sh -a
  customterm.sh -p
  sudo customterm.sh -r
```
```bash
# check path
➜  customterm ./customterm.sh -p

             _             _                 
 ___ _ _ ___| |_ ___ _____| |_ ___ ___ _____ 
|  _| | |_ -|  _| . |     |  _| -_|  _|     |
|___|___|___|_| |___|_|_|_|_| |___|_| |_|_|_|
        author: l0n3m4n | version:v1.0.0

Important Paths:
  ZSHRC: /home/advtool/.zshrc
  BACKUP: /home/advtool/.zshrc.bak
  LOG: /home/advtool/custom_terminal_install.log
  ZSH_CUSTOM: /home/advtool/.oh-my-zsh/custom

```
### Post-Installation

After the script completes, it will prompt you to restart your shell. You can do this by typing `exec zsh` or by closing and reopening your terminal.

You may then need to configure Powerlevel10k by running `p10k configure` in your new Zsh terminal.


## License

This project is licensed under the MIT License - see the `LICENSE` file for details.
