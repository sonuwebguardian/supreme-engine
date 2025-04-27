#!/bin/bash

echo "[*] Installing required tools..."

tools=(subfinder naabu gowitness waybackurls)

for tool in "${tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "[+] Installing $tool..."
        go install github.com/projectdiscovery/$tool/v2/cmd/$tool@latest
    else
        echo "[✓] $tool already installed."
    fi
done

echo "[✓] Tools setup completed."
