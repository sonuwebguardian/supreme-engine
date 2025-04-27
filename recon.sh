#!/bin/bash

DOMAIN=$1
if [ -z "$DOMAIN" ]; then
    echo "[ERROR] Please provide a domain as the first argument."
    exit 1
fi

bash main.sh -d "$DOMAIN"
