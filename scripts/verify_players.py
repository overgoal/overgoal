#!/usr/bin/env python3
"""
Script to verify all players were correctly seeded.
This script checks:
1. OvergoalPlayer exists in Overgoal contract
2. UniversePlayer exists in Universe contract
3. SeasonPlayer exists for players with teams
"""

import json
import subprocess
import sys
from pathlib import Path

# Configuration
PLAYERS_JSON_PATH = Path(__file__).parent.parent.parent / "docs" / "players.json"
SEASON_ID = 1
# Note: team_id in JSON (0-3) maps to season_club_id (101-104)
# team_id 0 -> club 1 (101), team_id 1 -> club 2 (102), etc.

def load_players():
    """Load players from players.json"""
    with open(PLAYERS_JSON_PATH, 'r') as f:
        return json.load(f)

def get_contract_addresses():
    """Get contract addresses from manifest"""
    try:
        with open('manifest_dev.json', 'r') as f:
            manifest = json.load(f)
        
        overgoal_world = manifest['world']['address']
        
        # Get Universe world address (from universe folder)
        universe_manifest_path = Path(__file__).parent.parent.parent / "universe" / "manifest_dev.json"
        with open(universe_manifest_path, 'r') as f:
            universe_manifest = json.load(f)
        universe_world = universe_manifest['world']['address']
        
        return overgoal_world, universe_world
    except Exception as e:
        print(f"❌ Error reading manifests: {e}")
        sys.exit(1)

def check_overgoal_player(world_address, player_id):
    """Check if OvergoalPlayer exists"""
    cmd = [
        'sozo', 'model', 'get', 'OvergoalPlayer', str(player_id),
        '--world', world_address
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        # Check if the output contains meaningful data
        return 'universe_player_id' in result.stdout and 'Model not found' not in result.stdout
    except:
        return False

def check_universe_player(world_address, player_id):
    """Check if UniversePlayer exists"""
    # Use manifest-path to query Universe from Overgoal repo
    universe_scarb = Path(__file__).parent.parent.parent / "universe" / "Scarb.toml"
    cmd = [
        'sozo', 'model', 'get', 'UniversePlayer', str(player_id),
        '--world', world_address,
        '--manifest-path', str(universe_scarb)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        # Check if the output contains meaningful data (ignore warnings)
        # Look for the actual model data, not "Model not found"
        return 'user_id' in result.stdout and 'Model not found' not in result.stdout
    except:
        return False

def check_season_player(world_address, season_player_id):
    """Check if SeasonPlayer exists"""
    cmd = [
        'sozo', 'model', 'get', 'SeasonPlayer', str(season_player_id),
        '--world', world_address
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        # Check if the output contains meaningful data
        return 'season_id' in result.stdout and result.stdout.count('0x0') < 5
    except:
        return False

def main():
    print("🔍 Starting player verification...")
    print("=" * 60)
    
    # Load players
    players = load_players()
    print(f"📖 Loaded {len(players)} players from JSON")
    
    # Get contract addresses
    overgoal_world, universe_world = get_contract_addresses()
    print(f"📍 Overgoal World: {overgoal_world}")
    print(f"📍 Universe World: {universe_world}")
    
    print("\n" + "=" * 60)
    print("Verifying Players...")
    print("=" * 60)
    
    overgoal_ok = 0
    overgoal_missing = []
    universe_ok = 0
    universe_missing = []
    season_ok = 0
    season_missing = []
    season_skipped = 0
    
    for i, player in enumerate(players, 1):
        player_id = player['user_id']
        player_name = player.get('player_name', f"Player {player_id}")
        team_id = player['team_id']
        
        print(f"[{i}/{len(players)}] {player_name} (ID: {player_id})...", end=" ")
        
        # Check OvergoalPlayer
        if check_overgoal_player(overgoal_world, player_id):
            overgoal_ok += 1
        else:
            overgoal_missing.append(player_id)
            print("❌ OvergoalPlayer missing", end=" ")
        
        # Check UniversePlayer
        if check_universe_player(universe_world, player_id):
            universe_ok += 1
        else:
            universe_missing.append(player_id)
            print("❌ UniversePlayer missing", end=" ")
        
        # Check SeasonPlayer (all players have teams now, team_id 0-3)
        if True:  # All players have season_players now
            season_player_id = 10000 + player_id
            if check_season_player(overgoal_world, season_player_id):
                season_ok += 1
            else:
                season_missing.append(player_id)
                print("❌ SeasonPlayer missing", end=" ")
        else:
            season_skipped += 1
        
        # Print OK if all checks passed
        if (player_id not in overgoal_missing and 
            player_id not in universe_missing and 
            player_id not in season_missing):
            print("✅")
        else:
            print()
    
    print("\n" + "=" * 60)
    print("VERIFICATION RESULTS")
    print("=" * 60)
    
    print(f"\n📊 OvergoalPlayer:")
    print(f"  ✅ Found: {overgoal_ok}/{len(players)}")
    if overgoal_missing:
        print(f"  ❌ Missing: {len(overgoal_missing)}")
        print(f"     IDs: {overgoal_missing[:10]}{'...' if len(overgoal_missing) > 10 else ''}")
    
    print(f"\n📊 UniversePlayer:")
    print(f"  ✅ Found: {universe_ok}/{len(players)}")
    if universe_missing:
        print(f"  ❌ Missing: {len(universe_missing)}")
        print(f"     IDs: {universe_missing[:10]}{'...' if len(universe_missing) > 10 else ''}")
    
    players_with_teams = len(players) - season_skipped
    print(f"\n📊 SeasonPlayer:")
    print(f"  ✅ Found: {season_ok}/{players_with_teams}")
    print(f"  ⏭️  Skipped (no team): {season_skipped}")
    if season_missing:
        print(f"  ❌ Missing: {len(season_missing)}")
        print(f"     IDs: {season_missing[:10]}{'...' if len(season_missing) > 10 else ''}")
    
    print("\n" + "=" * 60)
    
    if overgoal_missing or universe_missing or season_missing:
        print("❌ VERIFICATION FAILED - Some players are missing!")
        sys.exit(1)
    else:
        print("✅ VERIFICATION SUCCESSFUL - All players found!")
        sys.exit(0)

if __name__ == '__main__':
    main()

