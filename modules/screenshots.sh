#!/bin/bash
DOMAIN=$1
OUTPUT_DIR="output/$DOMAIN"
SUBDOMAIN_DIR="$OUTPUT_DIR/subdomains"
SCREENSHOT_DIR="$OUTPUT_DIR/screenshots"
LOGS_DIR="$OUTPUT_DIR/logs"

echo "[*] Taking screenshots..."
gowitness file -f "$SUBDOMAIN_DIR/subfinder.txt" -P "$SCREENSHOT_DIR" > "$LOGS_DIR/gowitness.log" 2>&1

echo "[*] Screenshot Capture Completed."
