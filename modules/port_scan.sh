#!/bin/bash
DOMAIN=$1
OUTPUT_DIR="output/$DOMAIN"
PORTSCAN_DIR="$OUTPUT_DIR/portscan"
LOGS_DIR="$OUTPUT_DIR/logs"

echo "[*] Running naabu..."
naabu -host "$DOMAIN" > "$PORTSCAN_DIR/naabu.txt" 2> "$LOGS_DIR/naabu-error.log"

echo "[*] Port Scanning Completed."
