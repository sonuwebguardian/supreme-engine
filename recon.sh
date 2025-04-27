#!/bin/bash

# Automated Recon Framework by Sonu (Sparerows Academy)
# Version: v0.1
# Description: Provide a target domain, and this script runs all recon steps

set -e

# === Colors for Output ===
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# === Input Validation ===
if [ -z "$1" ]; then
    echo -e "${RED}[!] Please provide a domain. Usage: ./recon.sh target.com${NC}"
    exit 1
fi

DOMAIN=$1
OUTPUT_DIR=recon-output/$DOMAIN
mkdir -p "$OUTPUT_DIR"

log() {
    echo -e "${YELLOW}[*] $1${NC}"
}

success() {
    echo -e "${GREEN}[+] $1${NC}"
}

# === Recon Functions ===

subdomain_enum() {
    log "Running Subdomain Enumeration on $DOMAIN"
    mkdir -p "$OUTPUT_DIR/subdomains"

    subfinder -d $DOMAIN -o "$OUTPUT_DIR/subdomains/subfinder.txt"
    assetfinder --subs-only $DOMAIN > "$OUTPUT_DIR/subdomains/assetfinder.txt"
    amass enum -d $DOMAIN -o "$OUTPUT_DIR/subdomains/amass.txt"

    sort -u "$OUTPUT_DIR/subdomains/"*.txt > "$OUTPUT_DIR/subdomains/all_subdomains.txt"
    success "Subdomain Enumeration Complete"
}

check_takeover() {
    log "Checking for Subdomain Takeovers"
    mkdir -p "$OUTPUT_DIR/takeovers"

    # Example with subjack (adjust binary paths/configs as needed)
    subjack -w "$OUTPUT_DIR/subdomains/all_subdomains.txt" -t 100 -timeout 30 -ssl -c fingerprints.json -v -o "$OUTPUT_DIR/takeovers/takeovers.txt"
    success "Subdomain Takeover Check Complete"
}

live_hosts() {
    log "Probing for Live Hosts"
    mkdir -p "$OUTPUT_DIR/live"

    cat "$OUTPUT_DIR/subdomains/all_subdomains.txt" | httpx -silent > "$OUTPUT_DIR/live/live_hosts.txt"
    success "Live Host Discovery Complete"
}

port_scan() {
    log "Running Port Scan"
    mkdir -p "$OUTPUT_DIR/ports"

    naabu -list "$OUTPUT_DIR/live/live_hosts.txt" -o "$OUTPUT_DIR/ports/naabu.txt"
    success "Port Scan Complete"
}

screenshotting() {
    log "Taking Screenshots"
    mkdir -p "$OUTPUT_DIR/screenshots"

    gowitness file -f "$OUTPUT_DIR/live/live_hosts.txt" -P "$OUTPUT_DIR/screenshots"
    success "Screenshotting Complete"
}

dir_bruteforce() {
    log "Running Directory Bruteforce"
    mkdir -p "$OUTPUT_DIR/dirs"

    ffuf -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u FUZZ -of csv -o "$OUTPUT_DIR/dirs/ffuf.csv"
    success "Directory Bruteforcing Complete"
}

js_analysis() {
    log "Analyzing JavaScript Files"
    mkdir -p "$OUTPUT_DIR/js"

    # Placeholders — integrate linkfinder, JSParser, etc.
    success "JS File Analysis Done (Placeholder)"
}

secret_discovery() {
    log "Scanning for Secrets & Tokens"
    mkdir -p "$OUTPUT_DIR/secrets"

    # Placeholder — integrate truffleHog, secretfinder, gf
    success "Secret Discovery Done (Placeholder)"
}

wayback_and_params() {
    log "Fetching URLs & Parameters"
    mkdir -p "$OUTPUT_DIR/wayback"

    waybackurls $DOMAIN > "$OUTPUT_DIR/wayback/urls.txt"
    cat "$OUTPUT_DIR/wayback/urls.txt" | grep '?'> "$OUTPUT_DIR/wayback/params.txt"
    success "Wayback + Param Discovery Done"
}

vulnerability_scan() {
    log "Running Vulnerability Scanners"
    mkdir -p "$OUTPUT_DIR/vulns"

    nuclei -l "$OUTPUT_DIR/live/live_hosts.txt" -o "$OUTPUT_DIR/vulns/nuclei.txt"
    success "Vulnerability Scan Done"
}

extra_checks() {
    log "Running SSRF, IDOR, CORS Checks (manual/customizable)"
    mkdir -p "$OUTPUT_DIR/extra"

    # Placeholder — integrate Corsy, SSRFmap, Autorize as needed
    success "Extra Checks Done (Placeholder)"
}

# === Main Execution ===

log "Starting Recon for $DOMAIN"

subdomain_enum
check_takeover
live_hosts
port_scan
screenshotting
dir_bruteforce
js_analysis
secret_discovery
wayback_and_params
vulnerability_scan
extra_checks

success "Recon Completed for $DOMAIN"
echo -e "${GREEN}[+] Results saved in $OUTPUT_DIR${NC}"
