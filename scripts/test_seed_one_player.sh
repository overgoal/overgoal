#!/bin/bash
# Quick test script to seed just ONE player and verify it works

set -e

echo "🧪 Testing player seeding with ONE player..."
echo ""

# Get addresses from manifest
WORLD_ADDRESS=$(cat manifest_dev.json | jq -r '.world.address')
ADMIN_ADDRESS=$(cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "overgoal-admin") | .address')
UNIVERSE_WORLD=$(cat ../universe/manifest_dev.json | jq -r '.world.address')

echo "📍 Overgoal World: $WORLD_ADDRESS"
echo "📍 Admin Contract: $ADMIN_ADDRESS"
echo "📍 Universe World: $UNIVERSE_WORLD"
echo ""

# Test player data (Oliver Thompson - ID 1)
PLAYER_ID="0x1"
USER_ID="0x1"
BODY_TYPE="0x0"
SKIN_COLOR="0x0"
BEARD_TYPE="0x1"
HAIR_TYPE="0x0"
HAIR_COLOR="0x0"
ENERGY="0x31"      # 49
SPEED="0x33"       # 51
LEADERSHIP="0x2e"  # 46
PASS="0x31"        # 49
SHOOT="0x31"       # 49
FREEKICK="0x31"    # 49
VISOR_TYPE="0x2"
VISOR_COLOR="0x0"

echo "🌱 Seeding player ID 1 (Oliver Thompson)..."
sozo execute --world $WORLD_ADDRESS $ADMIN_ADDRESS seed_player \
    $PLAYER_ID $USER_ID \
    $BODY_TYPE $SKIN_COLOR $BEARD_TYPE $HAIR_TYPE $HAIR_COLOR \
    $ENERGY $SPEED $LEADERSHIP $PASS $SHOOT $FREEKICK \
    $VISOR_TYPE $VISOR_COLOR \
    --wait

echo ""
echo "✅ Player seeded! Now checking..."
echo ""

# Check OvergoalPlayer
echo "🔍 Checking OvergoalPlayer in Overgoal..."
sozo model get OvergoalPlayer $PLAYER_ID --world $WORLD_ADDRESS

echo ""
echo "🔍 Checking UniversePlayer in Universe..."
sozo model get UniversePlayer $PLAYER_ID --world $UNIVERSE_WORLD

echo ""
echo "✅ Test complete!"

