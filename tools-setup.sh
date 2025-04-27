#!/bin/bash

GREEN='\\033[0;32m'
RED='\\033[0;31m'
NC='\\033[0m'

log() {
    echo -e "${GREEN}[+] $1${NC}"
}

error() {
    echo -e "${RED}[-] $1${NC}"
}

install_go_deps() {
    if ! command -v go &> /dev/null; then
        error "Go not installed! Please install Go before proceeding."
        exit 1
    fi

    export GOBIN=$HOME/go/bin
    mkdir -p "$GOBIN"
    export PATH=$PATH:$GOBIN
}

install_tool() {
    TOOL=$1
    INSTALL_CMD=$2
    CHECK_CMD=$3

    if command -v $CHECK_CMD &> /dev/null; then
        log "$TOOL already installed."
    else
        log "Installing $TOOL..."
        eval "$INSTALL_CMD"
        if command -v $CHECK_CMD &> /dev/null; then
            log "$TOOL installed successfully."
        else
            error "Failed to install $TOOL."
        fi
    fi
}

main() {
    sudo apt update

    install_go_deps

    # Basic dependencies
    sudo apt install -y git curl wget python3-pip chromium-driver

    # Tools
    install_tool "subfinder" "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest" "subfinder"
    install_tool "assetfinder" "go install github.com/tomnomnom/assetfinder@latest" "assetfinder"
    install_tool "amass" "go install -v github.com/owasp-amass/amass/v4/...@latest" "amass"
    install_tool "httpx" "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest" "httpx"
    install_tool "naabu" "go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest" "naabu"
    install_tool "nuclei" "go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" "nuclei"
    install_tool "subjack" "go install github.com/haccer/subjack@latest" "subjack"
    install_tool "ffuf" "go install github.com/ffuf/ffuf@latest" "ffuf"
    install_tool "gowitness" "go install github.com/sensepost/gowitness@latest" "gowitness"
    install_tool "waybackurls" "go install github.com/tomnomnom/waybackurls@latest" "waybackurls"
    install_tool "trufflehog" "pip3 install trufflehog" "trufflehog"
    
    # LinkFinder (manual clone)
    if [ ! -d "LinkFinder" ]; then
        log "Cloning LinkFinder..."
        git clone https://github.com/GerbenJavado/LinkFinder.git
        cd LinkFinder || exit
        pip3 install -r requirements.txt
        chmod +x linkfinder.py
        cd ..
        log "LinkFinder set up in ./LinkFinder directory."
    else
        log "LinkFinder already cloned."
    fi
}

main
