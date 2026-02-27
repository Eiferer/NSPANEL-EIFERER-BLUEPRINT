#!/usr/bin/env bash
# ============================================================================
# Eiferer Pre-flight Check
# ============================================================================
# Validates your ESPHome configuration before flashing.
# Usage: ./scripts/preflight.sh your_panel.yaml
# ============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  NSPanel Eiferer — Pre-flight Check${NC}"
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
echo ""

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <esphome_yaml_file>${NC}"
    exit 1
fi

YAML_FILE="$1"
ERRORS=0
WARNINGS=0

# ── Check file exists ──
if [ ! -f "$YAML_FILE" ]; then
    echo -e "${RED}✗ File not found: $YAML_FILE${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Config file: $YAML_FILE${NC}"

# ── Check ESPHome installed ──
if ! command -v esphome &> /dev/null; then
    echo -e "${RED}✗ ESPHome not found. Install with: pip install esphome${NC}"
    exit 1
fi

ESPHOME_VER=$(esphome version 2>/dev/null || echo "unknown")
echo -e "${GREEN}✓ ESPHome version: $ESPHOME_VER${NC}"

# ── Check minimum ESPHome version ──
MIN_VER="2025.11.0"
if python3 -c "
from packaging import version
import sys
current = '$ESPHOME_VER'.split(' ')[-1]
try:
    if version.parse(current) < version.parse('$MIN_VER'):
        sys.exit(1)
except:
    sys.exit(2)
" 2>/dev/null; then
    echo -e "${GREEN}✓ ESPHome version meets minimum ($MIN_VER)${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify ESPHome version >= $MIN_VER${NC}"
    ((WARNINGS++))
fi

# ── Validate YAML syntax ──
echo ""
echo -e "${CYAN}Validating YAML configuration...${NC}"
if esphome config "$YAML_FILE" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ YAML configuration valid${NC}"
else
    echo -e "${RED}✗ YAML configuration has errors:${NC}"
    esphome config "$YAML_FILE" 2>&1 | tail -20
    ((ERRORS++))
fi

# ── Check substitutions ──
echo ""
echo -e "${CYAN}Checking substitutions...${NC}"

if grep -q 'device_name:.*YOUR_NSPANEL_NAME\|device_name:.*"nspanel"$' "$YAML_FILE"; then
    echo -e "${YELLOW}⚠ device_name appears to be a default — make sure to customize it${NC}"
    ((WARNINGS++))
else
    echo -e "${GREEN}✓ device_name is customized${NC}"
fi

if grep -q 'wifi_ssid: !secret' "$YAML_FILE"; then
    echo -e "${GREEN}✓ Wi-Fi credentials use !secret (good)${NC}"
elif grep -q 'wifi_ssid:' "$YAML_FILE"; then
    echo -e "${YELLOW}⚠ Wi-Fi credentials may be in plaintext — consider using !secret${NC}"
    ((WARNINGS++))
fi

# ── Check add-ons for conflicts ──
echo ""
echo -e "${CYAN}Checking add-on compatibility...${NC}"

HEAT=$(grep -c 'eiferer_addon_climate_heat' "$YAML_FILE" 2>/dev/null || echo 0)
COOL=$(grep -c 'eiferer_addon_climate_cool' "$YAML_FILE" 2>/dev/null || echo 0)
DUAL=$(grep -c 'eiferer_addon_climate_dual' "$YAML_FILE" 2>/dev/null || echo 0)

# Filter out commented lines
HEAT_ACTIVE=$(grep -v '^\s*#' "$YAML_FILE" | grep -c 'eiferer_addon_climate_heat' || echo 0)
COOL_ACTIVE=$(grep -v '^\s*#' "$YAML_FILE" | grep -c 'eiferer_addon_climate_cool' || echo 0)
DUAL_ACTIVE=$(grep -v '^\s*#' "$YAML_FILE" | grep -c 'eiferer_addon_climate_dual' || echo 0)

CLIMATE_ACTIVE=$((HEAT_ACTIVE + COOL_ACTIVE + DUAL_ACTIVE))

if [ "$CLIMATE_ACTIVE" -gt 1 ]; then
    echo -e "${RED}✗ Multiple climate add-ons active — use only ONE of: heat, cool, or dual${NC}"
    ((ERRORS++))
elif [ "$CLIMATE_ACTIVE" -eq 1 ]; then
    echo -e "${GREEN}✓ Single climate add-on active${NC}"
else
    echo -e "${GREEN}✓ No climate add-on (OK if not needed)${NC}"
fi

BLE_ACTIVE=$(grep -v '^\s*#' "$YAML_FILE" | grep -c 'eiferer_addon_bluetooth' || echo 0)
if [ "$BLE_ACTIVE" -gt 0 ]; then
    echo -e "${YELLOW}⚠ Bluetooth proxy enabled — monitor memory after flashing (uses ~20KB heap)${NC}"
    ((WARNINGS++))
fi

# ── Try compile (optional) ──
echo ""
echo -e "${CYAN}Attempting test compile...${NC}"
if esphome compile "$YAML_FILE" 2>&1 | tail -5; then
    FW=$(find .esphome -name "firmware.bin" -type f 2>/dev/null | head -1)
    if [ -n "$FW" ]; then
        SIZE=$(stat -c%s "$FW")
        MAX=1900000
        PCT=$((SIZE * 100 / MAX))
        if [ "$SIZE" -gt "$MAX" ]; then
            echo -e "${RED}✗ Firmware too large: $SIZE bytes ($PCT% of max)${NC}"
            ((ERRORS++))
        elif [ "$PCT" -gt 90 ]; then
            echo -e "${YELLOW}⚠ Firmware size: $SIZE bytes ($PCT% of max) — getting close to limit${NC}"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✓ Firmware size: $SIZE bytes ($PCT% of max)${NC}"
        fi
    fi
else
    echo -e "${RED}✗ Compilation failed${NC}"
    ((ERRORS++))
fi

# ── Summary ──
echo ""
echo -e "${CYAN}══════════════════════════════════════════════════${NC}"
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}  FAILED: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo -e "${RED}  Fix errors before flashing.${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}  PASSED with $WARNINGS warning(s)${NC}"
    echo -e "${YELLOW}  Review warnings above. Safe to flash.${NC}"
    exit 0
else
    echo -e "${GREEN}  ALL CHECKS PASSED${NC}"
    echo -e "${GREEN}  Ready to flash!${NC}"
    exit 0
fi
