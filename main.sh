#!/bin/bash

# === Default Flags ===
SKIP_SUBDOMAIN=false
SKIP_PORTSCAN=false
SKIP_WAYBACK=false
SKIP_SCREENSHOTS=false
ONLY_SUBDOMAIN=false
ONLY_PORTSCAN=false
ONLY_WAYBACK=false
ONLY_SCREENSHOTS=false
ONLY_MODE=false
ONLY_COUNT=0

# === Parse Arguments ===
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--domain) DOMAIN="$2"; shift ;;
        --skip-subdomain) SKIP_SUBDOMAIN=true ;;
        --skip-portscan) SKIP_PORTSCAN=true ;;
        --skip-wayback) SKIP_WAYBACK=true ;;
        --skip-screenshots) SKIP_SCREENSHOTS=true ;;
        --only-subdomain) ONLY_SUBDOMAIN=true; ONLY_MODE=true; ((ONLY_COUNT++)) ;;
        --only-portscan) ONLY_PORTSCAN=true; ONLY_MODE=true; ((ONLY_COUNT++)) ;;
        --only-wayback) ONLY_WAYBACK=true; ONLY_MODE=true; ((ONLY_COUNT++)) ;;
        --only-screenshots) ONLY_SCREENSHOTS=true; ONLY_MODE=true; ((ONLY_COUNT++)) ;;
        *) echo "[ERROR] Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

if [ "$ONLY_COUNT" -gt 1 ]; then
    echo "[ERROR] You can only use one --only-* flag at a time."
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo "[ERROR] No domain provided. Use -d or --domain"
    exit 1
fi

# === Output Folder Setup ===
OUTPUT_DIR="output/$DOMAIN"
SUBDOMAIN_DIR="$OUTPUT_DIR/subdomains"
SCREENSHOT_DIR="$OUTPUT_DIR/screenshots"
PORTSCAN_DIR="$OUTPUT_DIR/portscan"
WAYBACK_DIR="$OUTPUT_DIR/wayback"
LOGS_DIR="$OUTPUT_DIR/logs"

mkdir -p "$SUBDOMAIN_DIR" "$SCREENSHOT_DIR" "$PORTSCAN_DIR" "$WAYBACK_DIR" "$LOGS_DIR" || {
    echo "[ERROR] Failed to create output directories for $DOMAIN"
    exit 1
}

echo "[+] Output directories created at: $OUTPUT_DIR"

if [ "$ONLY_MODE" = false ] || [ "$ONLY_SUBDOMAIN" = true ]; then
    if [ "$SKIP_SUBDOMAIN" = false ]; then
        echo "[*] Running Subdomain Enumeration..."
        bash modules/subdomain_enum.sh "$DOMAIN"
    else
        echo "[!] Skipping Subdomain Enumeration"
    fi
fi

if [ "$ONLY_MODE" = false ] || [ "$ONLY_PORTSCAN" = true ]; then
    if [ "$SKIP_PORTSCAN" = false ]; then
        echo "[*] Running Port Scanning..."
        bash modules/port_scan.sh "$DOMAIN"
    else
        echo "[!] Skipping Port Scanning"
    fi
fi

if [ "$ONLY_MODE" = false ] || [ "$ONLY_WAYBACK" = true ]; then
    if [ "$SKIP_WAYBACK" = false ]; then
        echo "[*] Running Wayback URL Collection..."
        bash modules/wayback_urls.sh "$DOMAIN"
    else
        echo "[!] Skipping Wayback URL Collection"
    fi
fi

if [ "$ONLY_MODE" = false ] || [ "$ONLY_SCREENSHOTS" = true ]; then
    if [ "$SKIP_SCREENSHOTS" = false ]; then
        echo "[*] Running Screenshot Capture..."
        bash modules/screenshots.sh "$DOMAIN"
    else
        echo "[!] Skipping Screenshot Capture"
    fi
fi

echo "[✓] Recon complete. Results saved in: $OUTPUT_DIR"
