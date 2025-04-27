#!/bin/bash
DOMAIN=$1
OUTPUT_DIR="output/$DOMAIN"
SUBDOMAIN_DIR="$OUTPUT_DIR/subdomains"
LOGS_DIR="$OUTPUT_DIR/logs"

echo "[*] Running subfinder..."
subfinder -d "$DOMAIN" -silent -all > "$SUBDOMAIN_DIR/subfinder.txt" 2> "$LOGS_DIR/subfinder-error.log"

echo "[*] Subdomain Enumeration Completed."
