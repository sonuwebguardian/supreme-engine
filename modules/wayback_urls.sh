#!/bin/bash
DOMAIN=$1
OUTPUT_DIR="output/$DOMAIN"
WAYBACK_DIR="$OUTPUT_DIR/wayback"
LOGS_DIR="$OUTPUT_DIR/logs"

echo "[*] Collecting Wayback URLs..."
waybackurls "$DOMAIN" > "$WAYBACK_DIR/waybackurls.txt" 2> "$LOGS_DIR/waybackurls-error.log"

echo "[*] Wayback URL Collection Completed."
