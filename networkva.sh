#!/bin/bash

# Security Tools Checker and Installer
# Checks for security assessment tools and installs missing ones
# Supports: Ubuntu/Debian, Kali Linux, Arch, Fedora/RHEL, macOS
# Version: 1.0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Global variables
INSTALL_DIR="$HOME/security-tools"
WORDLIST_DIR="/usr/share/wordlists"
PACKAGE_MANAGER=""
OS_TYPE=""
MISSING_TOOLS=()
INSTALLED_TOOLS=()
FAILED_TOOLS=()

# Banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║     Security Tools Checker & Installer                   ║"
    echo "║     Automated Setup for Penetration Testing Tools        ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Detect OS and package manager
detect_os() {
    echo -e "${CYAN}[*] Detecting operating system...${NC}"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_TYPE=$ID
            
            case $ID in
                ubuntu|debian|kali)
                    PACKAGE_MANAGER="apt"
                    echo -e "${GREEN}[+] Detected: $PRETTY_NAME${NC}"
                    ;;
                arch|manjaro)
                    PACKAGE_MANAGER="pacman"
                    echo -e "${GREEN}[+] Detected: $PRETTY_NAME${NC}"
                    ;;
                fedora|rhel|centos)
                    PACKAGE_MANAGER="dnf"
                    echo -e "${GREEN}[+] Detected: $PRETTY_NAME${NC}"
                    ;;
                *)
                    echo -e "${YELLOW}[!] Unknown Linux distribution: $ID${NC}"
                    echo -e "${YELLOW}[!] Attempting generic Linux installation...${NC}"
                    PACKAGE_MANAGER="apt"
                    ;;
            esac
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        PACKAGE_MANAGER="brew"
        echo -e "${GREEN}[+] Detected: macOS${NC}"
        
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo -e "${YELLOW}[!] Homebrew not found. Installing...${NC}"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
    else
        echo -e "${RED}[!] Unsupported operating system: $OSTYPE${NC}"
        exit 1
    fi
}

# Check if running as root (when needed)
check_privileges() {
    if [[ $EUID -ne 0 ]] && [[ "$PACKAGE_MANAGER" != "brew" ]]; then
        echo -e "${YELLOW}[!] Some installations require root privileges${NC}"
        echo -e "${YELLOW}[!] Please run with sudo for full functionality${NC}"
        read -p "Continue without root? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Exiting. Please run with: sudo $0${NC}"
            exit 1
        fi
    fi
}

# Update package manager
update_package_manager() {
    echo -e "${CYAN}[*] Updating package manager...${NC}"
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt update -y
            ;;
        pacman)
            sudo pacman -Sy
            ;;
        dnf)
            sudo dnf check-update
            ;;
        brew)
            brew update
            ;;
    esac
    
    echo -e "${GREEN}[+] Package manager updated${NC}"
}

# Install a package using the appropriate package manager
install_package() {
    local package=$1
    
    case $PACKAGE_MANAGER in
        apt)
            sudo apt install -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        brew)
            brew install "$package"
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Tool definitions with installation methods
declare -A TOOLS=(
    # Network scanning tools
    ["nmap"]="package:nmap"
    ["masscan"]="package:masscan"
    
    # Web application tools
    ["nikto"]="package:nikto"
    ["sqlmap"]="package:sqlmap"
    ["gobuster"]="package:gobuster"
    ["wfuzz"]="package:wfuzz"
    ["ffuf"]="github:ffuf/ffuf"
    ["nuclei"]="github:projectdiscovery/nuclei"
    ["wafw00f"]="pip:wafw00f"
    ["whatweb"]="package:whatweb"
    
    # SSL/TLS tools
    ["testssl.sh"]="github:drwetter/testssl.sh"
    ["sslyze"]="pip:sslyze"
    
    # Reconnaissance tools
    ["sublist3r"]="github:aboul3la/Sublist3r"
    ["amass"]="github:owasp-amass/amass"
    ["subfinder"]="github:projectdiscovery/subfinder"
    
    # Network analysis
    ["wireshark"]="package:wireshark"
    ["tcpdump"]="package:tcpdump"
    ["ncat"]="package:ncat"
    ["netcat"]="package:netcat"
    
    # Exploitation frameworks
    ["msfconsole"]="metasploit"
    
    # Password cracking
    ["john"]="package:john"
    ["hashcat"]="package:hashcat"
    ["hydra"]="package:hydra"
    
    # Wireless tools
    ["aircrack-ng"]="package:aircrack-ng"
    
    # General utilities
    ["curl"]="package:curl"
    ["wget"]="package:wget"
    ["git"]="package:git"
    ["python3"]="package:python3"
    ["pip3"]="package:python3-pip"
    ["go"]="package:golang-go"
)

# Check tool status
check_tool() {
    local tool=$1
    
    if command_exists "$tool"; then
        echo -e "${GREEN}  ✓ $tool${NC}"
        INSTALLED_TOOLS+=("$tool")
        return 0
    else
        echo -e "${RED}  ✗ $tool${NC}"
        MISSING_TOOLS+=("$tool")
        return 1
    fi
}

# Check all tools
check_all_tools() {
    echo -e "${CYAN}[*] Checking installed security tools...${NC}"
    echo ""
    
    echo -e "${BLUE}Network Scanning Tools:${NC}"
    check_tool "nmap"
    check_tool "masscan"
    
    echo ""
    echo -e "${BLUE}Web Application Tools:${NC}"
    check_tool "nikto"
    check_tool "sqlmap"
    check_tool "gobuster"
    check_tool "wfuzz"
    check_tool "ffuf"
    check_tool "nuclei"
    check_tool "wafw00f"
    check_tool "whatweb"
    
    echo ""
    echo -e "${BLUE}SSL/TLS Tools:${NC}"
    check_tool "testssl.sh"
    check_tool "sslyze"
    
    echo ""
    echo -e "${BLUE}Reconnaissance Tools:${NC}"
    check_tool "sublist3r"
    check_tool "amass"
    check_tool "subfinder"
    
    echo ""
    echo -e "${BLUE}Network Analysis:${NC}"
    check_tool "tcpdump"
    check_tool "ncat"
    
    echo ""
    echo -e "${BLUE}Password Tools:${NC}"
    check_tool "john"
    check_tool "hashcat"
    check_tool "hydra"
    
    echo ""
    echo -e "${BLUE}Wireless Tools:${NC}"
    check_tool "aircrack-ng"
    
    echo ""
    echo -e "${BLUE}General Utilities:${NC}"
    check_tool "curl"
    check_tool "wget"
    check_tool "git"
    check_tool "python3"
    check_tool "pip3"
    check_tool "go"
    
    echo ""
    echo -e "${CYAN}Summary:${NC}"
    echo -e "${GREEN}  Installed: ${#INSTALLED_TOOLS[@]}${NC}"
    echo -e "${RED}  Missing: ${#MISSING_TOOLS[@]}${NC}"
}

# Install from package manager
install_from_package() {
    local tool=$1
    local package=$2
    
    echo -e "${CYAN}[*] Installing $tool from package manager...${NC}"
    
    if install_package "$package"; then
        echo -e "${GREEN}[+] $tool installed successfully${NC}"
        return 0
    else
        echo -e "${RED}[-] Failed to install $tool${NC}"
        return 1
    fi
}

# Install from GitHub
install_from_github() {
    local tool=$1
    local repo=$2
    
    echo -e "${CYAN}[*] Installing $tool from GitHub...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || return 1
    
    # Clone repository
    if [ -d "$tool" ]; then
        echo -e "${YELLOW}[!] Directory exists, pulling latest changes...${NC}"
        cd "$tool" && git pull
    else
        git clone "https://github.com/$repo.git" "$tool"
        cd "$tool" || return 1
    fi
    
    # Tool-specific installation
    case $tool in
        ffuf)
            go build
            sudo cp ffuf /usr/local/bin/
            ;;
        nuclei)
            go build -o nuclei cmd/nuclei/main.go
            sudo cp nuclei /usr/local/bin/
            ;;
        testssl.sh)
            sudo ln -sf "$INSTALL_DIR/testssl.sh/testssl.sh" /usr/local/bin/testssl.sh
            chmod +x testssl.sh
            ;;
        Sublist3r)
            pip3 install -r requirements.txt
            sudo ln -sf "$INSTALL_DIR/Sublist3r/sublist3r.py" /usr/local/bin/sublist3r
            chmod +x sublist3r.py
            ;;
        amass)
            go install ./...
            ;;
        subfinder)
            go build -o subfinder cmd/subfinder/main.go
            sudo cp subfinder /usr/local/bin/
            ;;
        *)
            # Generic installation
            if [ -f "requirements.txt" ]; then
                pip3 install -r requirements.txt
            fi
            if [ -f "setup.py" ]; then
                sudo python3 setup.py install
            fi
            ;;
    esac
    
    if command_exists "$tool"; then
        echo -e "${GREEN}[+] $tool installed successfully${NC}"
        return 0
    else
        echo -e "${RED}[-] Failed to install $tool${NC}"
        return 1
    fi
}

# Install from pip
install_from_pip() {
    local tool=$1
    local package=$2
    
    echo -e "${CYAN}[*] Installing $tool from pip...${NC}"
    
    if pip3 install "$package"; then
        echo -e "${GREEN}[+] $tool installed successfully${NC}"
        return 0
    else
        echo -e "${RED}[-] Failed to install $tool${NC}"
        return 1
    fi
}

# Install Metasploit Framework
install_metasploit() {
    echo -e "${CYAN}[*] Installing Metasploit Framework...${NC}"
    
    case $OS_TYPE in
        ubuntu|debian|kali)
            curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
            chmod 755 msfinstall
            sudo ./msfinstall
            rm msfinstall
            ;;
        arch|manjaro)
            sudo pacman -S metasploit
            ;;
        fedora|rhel|centos)
            curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
            chmod 755 msfinstall
            sudo ./msfinstall
            rm msfinstall
            ;;
        macos)
            brew install metasploit
            ;;
    esac
    
    if command_exists "msfconsole"; then
        echo -e "${GREEN}[+] Metasploit installed successfully${NC}"
        return 0
    else
        echo -e "${RED}[-] Failed to install Metasploit${NC}"
        return 1
    fi
}

# Install a specific tool
install_tool() {
    local tool=$1
    local install_method=${TOOLS[$tool]}
    
    if [ -z "$install_method" ]; then
        echo -e "${YELLOW}[!] No installation method defined for $tool${NC}"
        return 1
    fi
    
    # Parse installation method
    local method_type="${install_method%%:*}"
    local method_value="${install_method#*:}"
    
    case $method_type in
        package)
            install_from_package "$tool" "$method_value"
            ;;
        github)
            install_from_github "$tool" "$method_value"
            ;;
        pip)
            install_from_pip "$tool" "$method_value"
            ;;
        metasploit)
            install_metasploit
            ;;
        *)
            echo -e "${RED}[-] Unknown installation method: $method_type${NC}"
            return 1
            ;;
    esac
}

# Install all missing tools
install_missing_tools() {
    if [ ${#MISSING_TOOLS[@]} -eq 0 ]; then
        echo -e "${GREEN}[+] All tools are already installed!${NC}"
        return 0
    fi
    
    echo -e "${CYAN}[*] Installing ${#MISSING_TOOLS[@]} missing tools...${NC}"
    echo ""
    
    for tool in "${MISSING_TOOLS[@]}"; do
        echo -e "${YELLOW}Installing $tool...${NC}"
        if install_tool "$tool"; then
            echo -e "${GREEN}[+] $tool installed${NC}"
        else
            echo -e "${RED}[-] Failed to install $tool${NC}"
            FAILED_TOOLS+=("$tool")
        fi
        echo ""
    done
}

# Install wordlists
install_wordlists() {
    echo -e "${CYAN}[*] Installing wordlists...${NC}"
    
    case $OS_TYPE in
        kali)
            echo -e "${GREEN}[+] Kali Linux comes with wordlists pre-installed${NC}"
            ;;
        ubuntu|debian)
            sudo apt install -y seclists wordlists
            ;;
        arch|manjaro)
            sudo pacman -S seclists
            ;;
        fedora|rhel|centos)
            sudo dnf install -y seclists
            ;;
        macos)
            brew install seclists
            ;;
    esac
    
    # Download SecLists if not available
    if [ ! -d "/usr/share/seclists" ] && [ ! -d "/usr/share/wordlists/seclists" ]; then
        echo -e "${CYAN}[*] Downloading SecLists...${NC}"
        sudo mkdir -p /usr/share/wordlists
        cd /usr/share/wordlists || return
        sudo git clone https://github.com/danielmiessler/SecLists.git seclists
    fi
    
    echo -e "${GREEN}[+] Wordlists installation completed${NC}"
}

# Setup Go environment
setup_go_environment() {
    echo -e "${CYAN}[*] Setting up Go environment...${NC}"
    
    if ! command_exists "go"; then
        echo -e "${YELLOW}[!] Go not installed, skipping Go setup${NC}"
        return
    fi
    
    # Add Go paths to shell profile
    local shell_profile=""
    if [ -n "$BASH_VERSION" ]; then
        shell_profile="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        shell_profile="$HOME/.zshrc"
    fi
    
    if [ -n "$shell_profile" ]; then
        if ! grep -q "GOPATH" "$shell_profile"; then
            {
                echo ""
                echo "# Go environment"
                echo 'export GOPATH=$HOME/go'
                echo 'export PATH=$PATH:$GOPATH/bin'
            } >> "$shell_profile"
            echo -e "${GREEN}[+] Go environment added to $shell_profile${NC}"
        fi
    fi
    
    # Create Go directories
    mkdir -p "$HOME/go/bin"
    mkdir -p "$HOME/go/src"
    mkdir -p "$HOME/go/pkg"
}

# Generate installation report
generate_report() {
    local report_file="$HOME/security-tools-installation-report.txt"
    
    {
        echo "=========================================="
        echo "SECURITY TOOLS INSTALLATION REPORT"
        echo "=========================================="
        echo "Date: $(date)"
        echo "OS: $OS_TYPE"
        echo "Package Manager: $PACKAGE_MANAGER"
        echo ""
        echo "=========================================="
        echo "INSTALLED TOOLS (${#INSTALLED_TOOLS[@]}):"
        echo "=========================================="
        printf '%s\n' "${INSTALLED_TOOLS[@]}"
        echo ""
        
        if [ ${#FAILED_TOOLS[@]} -gt 0 ]; then
            echo "=========================================="
            echo "FAILED INSTALLATIONS (${#FAILED_TOOLS[@]}):"
            echo "=========================================="
            printf '%s\n' "${FAILED_TOOLS[@]}"
            echo ""
        fi
        
        echo "=========================================="
        echo "INSTALLATION PATHS:"
        echo "=========================================="
        echo "GitHub tools: $INSTALL_DIR"
        echo "Wordlists: $WORDLIST_DIR"
        echo ""
        echo "=========================================="
        echo "POST-INSTALLATION STEPS:"
        echo "=========================================="
        echo "1. Restart your terminal or run: source ~/.bashrc"
        echo "2. Verify installations with: which <tool-name>"
        echo "3. Update tools regularly"
        echo "4. Read tool documentation before use"
        echo ""
        
    } > "$report_file"
    
    echo -e "${GREEN}[+] Installation report saved: $report_file${NC}"
    cat "$report_file"
}

# Interactive menu
show_menu() {
    echo ""
    echo -e "${YELLOW}What would you like to do?${NC}"
    echo "1) Check tool status only"
    echo "2) Install missing tools"
    echo "3) Install specific tool"
    echo "4) Install wordlists"
    echo "5) Setup Go environment"
    echo "6) Full installation (all missing tools + wordlists)"
    echo "7) Exit"
    echo ""
    read -p "Select option [1-7]: " choice
    
    case $choice in
        1)
            check_all_tools
            show_menu
            ;;
        2)
            install_missing_tools
            check_all_tools
            generate_report
            ;;
        3)
            echo -e "${CYAN}Available tools:${NC}"
            printf '%s\n' "${!TOOLS[@]}" | sort
            echo ""
            read -p "Enter tool name: " tool_name
            if install_tool "$tool_name"; then
                echo -e "${GREEN}[+] Installation completed${NC}"
            else
                echo -e "${RED}[-] Installation failed${NC}"
            fi
            show_menu
            ;;
        4)
            install_wordlists
            show_menu
            ;;
        5)
            setup_go_environment
            show_menu
            ;;
        6)
            update_package_manager
            install_missing_tools
            install_wordlists
            setup_go_environment
            check_all_tools
            generate_report
            ;;
        7)
            echo -e "${GREEN}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            show_menu
            ;;
    esac
}

# Main function
main() {
    show_banner
    detect_os
    check_privileges
    
    # Initial tool check
    check_all_tools
    
    # Show interactive menu
    show_menu
}

# Run main function
main "$@"
