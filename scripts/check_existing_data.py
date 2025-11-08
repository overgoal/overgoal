#!/usr/bin/env python3
"""
Check what data already exists in the system
"""

import json
import subprocess
from pathlib import Path

def get_world_addresses():
    """Get world addresses from manifests"""
    with open('manifest_dev.json', 'r') as f:
        manifest = json.load(f)
    overgoal_world = manifest['world']['address']
    
    universe_manifest_path = Path(__file__).parent.parent.parent / "universe" / "manifest_dev.json"
    with open(universe_manifest_path, 'r') as f:
        universe_manifest = json.load(f)
    universe_world = universe_manifest['world']['address']
    
    return overgoal_world, universe_world

def check_model(world_address, model_name, entity_id, manifest_path=None):
    """Check if a model exists"""
    cmd = ['sozo', 'model', 'get', model_name, hex(entity_id), '--world', world_address]
    if manifest_path:
        cmd.extend(['--manifest-path', str(manifest_path)])
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    return 'Model not found' not in result.stdout

def main():
    print("=" * 70)
    print("CHECKING EXISTING DATA")
    print("=" * 70)
    
    overgoal_world, universe_world = get_world_addresses()
    universe_scarb = Path(__file__).parent.parent.parent / "universe" / "Scarb.toml"
    
    print(f"\n📍 Overgoal World: {overgoal_world}")
    print(f"📍 Universe World: {universe_world}")
    
    # Check Season
    print("\n🔍 Checking Season 1...")
    if check_model(overgoal_world, 'Season', 1):
        print("  ✅ Season 1 EXISTS")
    else:
        print("  ❌ Season 1 NOT FOUND")
    
    # Check Clubs
    print("\n🔍 Checking Clubs...")
    for club_id in range(1, 5):
        if check_model(overgoal_world, 'Club', club_id):
            print(f"  ✅ Club {club_id} EXISTS")
        else:
            print(f"  ❌ Club {club_id} NOT FOUND")
    
    # Check Season Clubs
    print("\n🔍 Checking Season Clubs...")
    for season_club_id in range(101, 105):
        if check_model(overgoal_world, 'SeasonClub', season_club_id):
            print(f"  ✅ SeasonClub {season_club_id} EXISTS")
        else:
            print(f"  ❌ SeasonClub {season_club_id} NOT FOUND")
    
    # Check Players (1-3)
    print("\n🔍 Checking Players...")
    for player_id in range(1, 4):
        overgoal_exists = check_model(overgoal_world, 'OvergoalPlayer', player_id)
        universe_exists = check_model(universe_world, 'UniversePlayer', player_id, universe_scarb)
        
        if overgoal_exists and universe_exists:
            print(f"  ✅ Player {player_id} EXISTS (Overgoal + Universe)")
        elif overgoal_exists:
            print(f"  ⚠️  Player {player_id} EXISTS in Overgoal only")
        elif universe_exists:
            print(f"  ⚠️  Player {player_id} EXISTS in Universe only")
        else:
            print(f"  ❌ Player {player_id} NOT FOUND")
    
    # Check Season Players
    print("\n🔍 Checking Season Players...")
    for player_id in range(1, 4):
        season_player_id = 10000 + player_id
        if check_model(overgoal_world, 'SeasonPlayer', season_player_id):
            print(f"  ✅ SeasonPlayer {season_player_id} EXISTS (Player {player_id} assigned)")
        else:
            print(f"  ❌ SeasonPlayer {season_player_id} NOT FOUND (Player {player_id} not assigned)")
    
    print("\n" + "=" * 70)
    print("💡 If Season/Clubs exist: Skip setup, go directly to assign_player.py")
    print("💡 If Players don't exist: You need to create them first")
    print("💡 If SeasonPlayers don't exist: Use assign_player.py to assign them")
    print("=" * 70)

if __name__ == '__main__':
    main()

