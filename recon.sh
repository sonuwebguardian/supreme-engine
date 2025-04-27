#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[+] $1${NC}"
}

error() {
    echo -e "${RED}[-] $1${NC}"
}

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

DOMAIN=$1
SKIP_MODULES=("${@:2}")

if [ -z "$DOMAIN" ]; then
    error "Usage: $0 <domain> [--skip module1 module2 ...]"
    exit 1
fi

should_skip() {
    for skip in "${SKIP_MODULES[@]}"; do
        if [[ "$skip" == "$1" ]]; then
            return 0
        fi
    done
    return 1
}

OUTPUT_DIR=$(yq e ".config.output_base" "$CONFIG_FILE")/$DOMAIN
mkdir -p "$OUTPUT_DIR/subdomains"

subdomain_enum() {
    log "Running subdomain enumeration..."
    if ! "$(get_tool subfinder)" -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains/subfinder.txt"; then
        error "Subfinder failed!"
    fi

    if ! "$(get_tool assetfinder)" --subs-only "$DOMAIN" > "$OUTPUT_DIR/subdomains/assetfinder.txt"; then
        error "Assetfinder failed!"
    fi

    if ! "$(get_tool amass)" enum -passive -d "$DOMAIN" -o "$OUTPUT_DIR/subdomains/amass.txt"; then
        error "Amass failed!"
    fi

    sort -u "$OUTPUT_DIR"/subdomains/*.txt > "$OUTPUT_DIR/subdomains/all.txt"
    log "Subdomain enumeration completed."
}

probe_alive() {
    log "Probing for alive domains..."
    if ! cat "$OUTPUT_DIR/subdomains/all.txt" | "$(get_tool httpx)" -silent > "$OUTPUT_DIR/alive.txt"; then
        error "Httpx failed!"
    fi
    log "Alive probing completed."
}

take_screenshots() {
    log "Taking screenshots..."
    mkdir -p "$OUTPUT_DIR/screenshots"
    if ! "$(get_tool gowitness)" file -f "$OUTPUT_DIR/alive.txt" -P "$OUTPUT_DIR/screenshots"; then
        error "Gowitness failed!"
    fi
    log "Screenshotting completed."
}

port_scan() {
    log "Running port scan..."
    if ! "$(get_tool naabu)" -iL "$OUTPUT_DIR/alive.txt" -o "$OUTPUT_DIR/ports.txt"; then
        error "Naabu failed!"
    fi
    log "Port scanning completed."
}

subdomain_takeover() {
    log "Checking for subdomain takeover..."
    if ! "$(get_tool subjack)" -w "$OUTPUT_DIR/subdomains/all.txt" -t 100 -timeout 30 -ssl -v -c fingerprints.json -o "$OUTPUT_DIR/takeover.txt"; then
        error "Subjack failed!"
    fi
    log "Subdomain takeover scan completed."
}

run_nuclei() {
    log "Running nuclei..."
    if ! "$(get_tool nuclei)" -l "$OUTPUT_DIR/alive.txt" -t cves/ -o "$OUTPUT_DIR/nuclei.txt"; then
        error "Nuclei scan failed!"
    fi
    log "Nuclei scanning completed."
}

dir_enum() {
    log "Running directory enumeration..."
    wordlist=$(get_wordlist ffuf)
    mkdir -p "$OUTPUT_DIR/dirsearch"
    while read -r url; do
        if ! "$(get_tool ffuf)" -w "$wordlist" -u "$url/FUZZ" -mc 200 -of csv -o "$OUTPUT_DIR/dirsearch/$(echo $url | sed 's/https\?:\/\///').csv"; then
            error "FFUF failed on $url"
        fi
    done < "$OUTPUT_DIR/alive.txt"
    log "Directory enumeration completed."
}

wayback_enum() {
    log "Fetching Wayback URLs..."
    if ! cat "$OUTPUT_DIR/subdomains/all.txt" | "$(get_tool waybackurls)" > "$OUTPUT_DIR/wayback.txt"; then
        error "Waybackurls failed!"
    fi
    log "Wayback URLs fetched."
}

js_analysis() {
    log "Analyzing JavaScript files..."
    mkdir -p "$OUTPUT_DIR/js"
    if ! python3 "$(get_tool linkfinder)" -i "$OUTPUT_DIR/wayback.txt" -o cli > "$OUTPUT_DIR/js/js_links.txt"; then
        error "LinkFinder failed!"
    fi
    log "JavaScript analysis completed."
}

secrets_scan() {
    log "Scanning for secrets..."
    if ! "$(get_tool trufflehog)" filesystem "$OUTPUT_DIR" --json > "$OUTPUT_DIR/secrets.json"; then
        error "Trufflehog scan failed!"
    fi
    log "Secrets scan completed."
}

# Run modules conditionally
! should_skip "subdomain_enum" && subdomain_enum
! should_skip "probe_alive" && probe_alive
! should_skip "screenshotting" && take_screenshots
! should_skip "port_scan" && port_scan
! should_skip "subdomain_takeover" && subdomain_takeover
! should_skip "vuln_scan" && run_nuclei
! should_skip "dir_enum" && dir_enum
! should_skip "wayback" && wayback_enum
! should_skip "js_analysis" && js_analysis
! should_skip "secrets" && secrets_scan

log "Recon completed. All data saved to $OUTPUT_DIR"
