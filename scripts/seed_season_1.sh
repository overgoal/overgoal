#!/bin/bash

# Script to seed Season 1 data
# This script calls the admin system's seed_season_1 function

set -e

echo "🌱 Seeding Season 1 data..."
echo ""

# Get the world address from manifest
WORLD_ADDRESS=$(cat manifest_dev.json | jq -r '.world.address')
echo "📍 World Address: $WORLD_ADDRESS"

# Get the admin contract address
ADMIN_ADDRESS=$(cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "overgoal-admin") | .address')
echo "📍 Admin Contract: $ADMIN_ADDRESS"

# Get the account address from dojo config
ACCOUNT_ADDRESS=$(grep "account_address" dojo_dev.toml | head -1 | cut -d'"' -f2)
echo "👤 Account: $ACCOUNT_ADDRESS"

echo ""
echo "🚀 Calling seed_season_1..."
echo ""

# Call the seed_season_1 function
sozo execute $ADMIN_ADDRESS seed_season_1 \
    --world $WORLD_ADDRESS \
    --account-address $ACCOUNT_ADDRESS \
    --wait

echo ""
echo "✅ Season 1 data seeded successfully!"
echo ""
echo "📊 Seeded Data:"
echo "  - Season 1: 'Season 0: Where everything starts'"
echo "  - Start: November 19, 2024"
echo "  - End: December 7, 2024"
echo "  - Prize Pool: 0 (to be updated later)"
echo ""
echo "  - Club 1: Cartridge Athletic"
echo "  - Club 2: Dojo United"
echo "  - Club 3: Nova United"
echo "  - Club 4: Drakon Core"
echo ""
echo "  - 4 SeasonClub entries created (IDs: 101-104)"
echo ""
echo "💡 Run './scripts/verify_season_1.sh' to verify the data"

