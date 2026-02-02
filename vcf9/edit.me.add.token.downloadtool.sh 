#!/bin/bash
# --- Configuration ---
TOKEN_VALUE="Us2MqrBCCkIqKYqgMARZy2SdPfsY5VQz" 
VCF_VERSION="9.0.2.0"
DEPOT_PATH="/depot"
TOKEN_FILE="/root/downloadtool/token.file"
TOOL_BIN="/root/downloadtool/bin/vcf-download-tool"

mkdir -p "$DEPOT_PATH"

echo "[1/4] Preparing token file..."
echo "$TOKEN_VALUE" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

echo "[2/4] Verifying VCF $VCF_VERSION availability..."
$TOOL_BIN releases list --depot-download-token-file "$TOKEN_FILE" --vcf-version "$VCF_VERSION"

echo "[3/4] Downloading metadata..."
$TOOL_BIN metadata download --depot-download-token-file "$TOKEN_FILE" --depot-store "$DEPOT_PATH"

echo "[4/4] Starting binary download..."
$TOOL_BIN binaries download --depot-download-token-file "$TOKEN_FILE" --vcf-version "$VCF_VERSION" --depot-store "$DEPOT_PATH" --type INSTALL