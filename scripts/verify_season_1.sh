#!/bin/bash

# Script to verify Season 1 data
# This script calls the admin system's get_season_1_data function

set -e

echo "🔍 Verifying Season 1 data..."
echo ""

# Get the world address from manifest
WORLD_ADDRESS=$(cat manifest_dev.json | jq -r '.world.address')
echo "📍 World Address: $WORLD_ADDRESS"

# Get the admin contract address
ADMIN_ADDRESS=$(cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "overgoal-admin") | .address')
echo "📍 Admin Contract: $ADMIN_ADDRESS"

echo ""
echo "📊 Fetching Season 1 data..."
echo ""

# Call the get_season_1_data function
sozo call $ADMIN_ADDRESS get_season_1_data \
    --world $WORLD_ADDRESS

echo ""
echo "✅ Data retrieval complete!"
echo ""
echo "💡 You can also query individual models using:"
echo "  sozo model get Season 1 --world $WORLD_ADDRESS"
echo "  sozo model get Club 1 --world $WORLD_ADDRESS"
echo "  sozo model get SeasonClub 101 --world $WORLD_ADDRESS"

