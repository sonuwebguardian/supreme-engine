#!/bin/bash

# Automated Recon Framework by Sonu (Sparerows Academy)
# Version: v0.2 (with error handling + filled placeholders)

set -euo pipefail

# === Colors for Output ===
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m"

CONFIG_FILE="config.yaml"

if [ ! -f "$CONFIG_FILE" ]; then
    error "Missing config.yaml! Please create one in the script directory."
    exit 1
fi

# Use yq to load paths from YAML
get_tool() {
    yq e ".tools.$1" "$CONFIG_FILE"
}

get_wordlist() {
    yq e ".wordlists.$1" "$CONFIG_FILE"
}


# === Input Validation ===
if [ -z "${1:-}" ]; then
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

error() {
    echo -e "${RED}[!] $1${NC}"
}

check_tool() {
    if ! command -v "$1" &> /dev/null; then
        error "$1 not found! Please install it first."
        exit 1
    fi
}

# === Check Required Tools ===
REQUIRED_TOOLS=(subfinder assetfinder amass httpx subjack naabu nuclei ffuf gowitness waybackurls linkfinder trufflehog)

for tool in "${REQUIRED_TOOLS[@]}"; do
    check_tool "$tool"
done

# === Recon Functions ===

subdomain_enum() {
    log "Running Subdomain Enumeration"
    mkdir -p "$OUTPUT_DIR/subdomains"

    {
        subfinder -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains/subfinder.txt"
        assetfinder --subs-only "$DOMAIN" > "$OUTPUT_DIR/subdomains/assetfinder.txt"
        amass enum -passive -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains/amass.txt"
    } || error "Subdomain Enumeration Failed"

    sort -u "$OUTPUT_DIR/subdomains/"*.txt > "$OUTPUT_DIR/subdomains/all_subdomains.txt"
    success "Subdomain Enumeration Done"
}

check_takeover() {
    log "Checking for Subdomain Takeovers"
    mkdir -p "$OUTPUT_DIR/takeovers"

    {
        subjack -w "$OUTPUT_DIR/subdomains/all_subdomains.txt" -t 100 -timeout 30 -ssl -c fingerprints.json -v -o "$OUTPUT_DIR/takeovers/takeovers.txt"
    } || error "Subdomain Takeover Check Failed"
    success "Takeover Check Complete"
}

live_hosts() {
    log "Probing Live Hosts"
    mkdir -p "$OUTPUT_DIR/live"

    {
        httpx -l "$OUTPUT_DIR/subdomains/all_subdomains.txt" -silent > "$OUTPUT_DIR/live/live_hosts.txt"
    } || error "Live Host Discovery Failed"
    success "Live Hosts Discovery Complete"
}

port_scan() {
    log "Running Port Scan"
    mkdir -p "$OUTPUT_DIR/ports"

    {
        naabu -list "$OUTPUT_DIR/live/live_hosts.txt" -o "$OUTPUT_DIR/ports/naabu.txt"
    } || error "Port Scan Failed"
    success "Port Scan Complete"
}

screenshotting() {
    log "Taking Screenshots"
    mkdir -p "$OUTPUT_DIR/screenshots"

    {
        gowitness file -f "$OUTPUT_DIR/live/live_hosts.txt" -P "$OUTPUT_DIR/screenshots"
    } || error "Screenshotting Failed"
    success "Screenshotting Complete"
}

dir_bruteforce() {
    log "Running Directory Bruteforce"
    mkdir -p "$OUTPUT_DIR/dirs"

    {
        while IFS= read -r url; do
            ffuf -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -u "$url/FUZZ" -of csv -o "$OUTPUT_DIR/dirs/$(echo "$url" | sed 's|https\?://||;s|/|_|g').csv"
        done < "$OUTPUT_DIR/live/live_hosts.txt"
    } || error "Directory Bruteforcing Failed"
    success "Directory Bruteforce Complete"
}

js_analysis() {
    log "Analyzing JavaScript Files"
    mkdir -p "$OUTPUT_DIR/js"

    {
        getJS() {
            for url in $(cat "$OUTPUT_DIR/live/live_hosts.txt"); do
                jslinks=$(curl -s "$url" | grep -Eo 'src="[^"]+\.js"' | cut -d'"' -f2)
                for js in $jslinks; do
                    full_url="$url$js"
                    echo "$full_url" >> "$OUTPUT_DIR/js/js_links.txt"
                    curl -s "$full_url" -o "$OUTPUT_DIR/js/$(basename "$js")"
                done
            done
        }
        getJS
        for jsfile in "$OUTPUT_DIR/js/"*.js; do
            python3 linkfinder.py -i "$jsfile" -o cli >> "$OUTPUT_DIR/js/linkfinder_results.txt"
        done
    } || error "JavaScript Analysis Failed"
    success "JS Analysis Done"
}

secret_discovery() {
    log "Finding Secrets in JS Files"
    mkdir -p "$OUTPUT_DIR/secrets"

    {
        trufflehog filesystem "$OUTPUT_DIR/js/" > "$OUTPUT_DIR/secrets/trufflehog.txt"
    } || error "Secret Discovery Failed"
    success "Secrets Discovery Complete"
}

wayback_and_params() {
    log "Fetching Wayback URLs & Parameters"
    mkdir -p "$OUTPUT_DIR/wayback"

    {
        waybackurls "$DOMAIN" > "$OUTPUT_DIR/wayback/urls.txt"
        cat "$OUTPUT_DIR/wayback/urls.txt" | grep '?' | cut -d '?' -f2 | cut -d '=' -f1 | sort -u > "$OUTPUT_DIR/wayback/params.txt"
    } || error "Wayback Collection Failed"
    success "Wayback + Params Extraction Done"
}

vulnerability_scan() {
    log "Running Nuclei Scans"
    mkdir -p "$OUTPUT_DIR/vulns"

    {
        nuclei -l "$OUTPUT_DIR/live/live_hosts.txt" -o "$OUTPUT_DIR/vulns/nuclei.txt" -silent
    } || error "Vulnerability Scan Failed"
    success "Vulnerability Scanning Done"
}

extra_checks() {
    log "Running Extra Vulnerability Checks"
    mkdir -p "$OUTPUT_DIR/extra"

    {
        echo "Run SSRFmap, Corsy, or Autorize manually from Burp Suite extensions or CLI"
    } || error "Extra Checks Failed"
    success "Extra Checks Logged (Manual Recommended)"
}

# === Main Execution ===

log "Starting Recon on $DOMAIN"

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

success "All Recon Steps Completed for $DOMAIN"
echo -e "${GREEN}[+] Output directory: $OUTPUT_DIR${NC}"
