#!/bin/bash

# Script to restart everything fresh for testing
# This will:
# 1. Kill Katana
# 2. Start Katana fresh
# 3. Deploy Universe
# 4. Deploy Overgoal (with updated Universe address)
# 5. Verify deployment

set -e  # Exit on any error

echo "========================================================================"
echo "🔄 RESTART FRESH - Clean Slate for Testing"
echo "========================================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Kill existing Katana
echo ""
echo -e "${YELLOW}Step 1: Stopping Katana...${NC}"
pkill -f "katana" || echo "  (No Katana process found)"
sleep 2
echo -e "${GREEN}  ✅ Katana stopped${NC}"

# Step 2: Start Katana in background
echo ""
echo -e "${YELLOW}Step 2: Starting Katana...${NC}"
cd /Users/mg/Documents/Software/Overgoal/universe
katana --config katana.toml > /tmp/katana.log 2>&1 &
KATANA_PID=$!
echo -e "${GREEN}  ✅ Katana started (PID: $KATANA_PID)${NC}"
echo "  📝 Logs: /tmp/katana.log"
sleep 3  # Give Katana time to start

# Step 3: Deploy Universe
echo ""
echo -e "${YELLOW}Step 3: Deploying Universe...${NC}"
cd /Users/mg/Documents/Software/Overgoal/universe
sozo clean || true
sozo build
sozo migrate
echo -e "${GREEN}  ✅ Universe deployed${NC}"

# Get Universe game contract address
UNIVERSE_GAME_ADDRESS=$(cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "universe-game") | .address')
echo "  📍 Universe Game Address: $UNIVERSE_GAME_ADDRESS"

# Step 4: Update Overgoal config with Universe address
echo ""
echo -e "${YELLOW}Step 4: Updating Overgoal config...${NC}"
cd /Users/mg/Documents/Software/Overgoal/overgoal

# Update dojo_dev.toml with new Universe address
sed -i.bak "s/\"overgoal-overgoal_game\" = \[\"0x[a-fA-F0-9]*\"\]/\"overgoal-overgoal_game\" = [\"$UNIVERSE_GAME_ADDRESS\"]/" dojo_dev.toml
sed -i.bak "s/\"overgoal-admin\" = \[\"0x[a-fA-F0-9]*\"\]/\"overgoal-admin\" = [\"$UNIVERSE_GAME_ADDRESS\"]/" dojo_dev.toml
rm dojo_dev.toml.bak

echo -e "${GREEN}  ✅ Config updated${NC}"

# Step 5: Deploy Overgoal
echo ""
echo -e "${YELLOW}Step 5: Deploying Overgoal...${NC}"
sozo clean || true
sozo build
sozo migrate
echo -e "${GREEN}  ✅ Overgoal deployed${NC}"

# Step 6: Verify deployment
echo ""
echo -e "${YELLOW}Step 6: Verifying deployment...${NC}"

OVERGOAL_WORLD=$(cat manifest_dev.json | jq -r '.world.address')
OVERGOAL_GAME_ADDRESS=$(cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "overgoal-overgoal_game") | .address')
ADMIN_ADDRESS=$(cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "overgoal-admin") | .address')

UNIVERSE_WORLD=$(cat ../universe/manifest_dev.json | jq -r '.world.address')

echo ""
echo "========================================================================"
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo "========================================================================"
echo ""
echo "📍 Contract Addresses:"
echo "  Universe World:        $UNIVERSE_WORLD"
echo "  Universe Game:         $UNIVERSE_GAME_ADDRESS"
echo "  Overgoal World:        $OVERGOAL_WORLD"
echo "  Overgoal Game:         $OVERGOAL_GAME_ADDRESS"
echo "  Admin:                 $ADMIN_ADDRESS"
echo ""
echo "🎯 Next Steps:"
echo "  1. Run: python3 scripts/setup_test_data.py"
echo "  2. Run: python3 scripts/assign_player.py --player-id 1 --user-id 100 --club-id 1"
echo "  3. Run: python3 scripts/show_season_players.py"
echo ""
echo "💡 Katana is running in background (PID: $KATANA_PID)"
echo "   To stop: kill $KATANA_PID"
echo "   Logs: /tmp/katana.log"
echo "========================================================================"

