#!/usr/bin/env python3
"""
Setup test data for assign_player_to_club testing:
- 3 users
- 3 players (Universe + Overgoal)
- 3 clubs (and season clubs)
- 1 season
"""

import json
import subprocess
import sys
from pathlib import Path

def get_contract_addresses():
    """Get contract addresses from manifests"""
    print("📍 Reading contract addresses...")
    
    # Overgoal
    with open('manifest_dev.json', 'r') as f:
        manifest = json.load(f)
    overgoal_world = manifest['world']['address']
    admin_address = None
    for contract in manifest['contracts']:
        if contract['tag'] == 'overgoal-admin':
            admin_address = contract['address']
            break
    
    # Universe
    universe_manifest_path = Path(__file__).parent.parent.parent / "universe" / "manifest_dev.json"
    with open(universe_manifest_path, 'r') as f:
        universe_manifest = json.load(f)
    universe_world = universe_manifest['world']['address']
    
    print(f"  Overgoal World: {overgoal_world}")
    print(f"  Admin Contract: {admin_address}")
    print(f"  Universe World: {universe_world}")
    
    return overgoal_world, admin_address, universe_world

def create_season():
    """Create Season 1"""
    print("\n🌱 Creating Season 1...")
    overgoal_world, admin_address, _ = get_contract_addresses()
    
    cmd = [
        'sozo', 'execute',
        '--world', overgoal_world,
        admin_address,
        'seed_season_1',
        '--wait'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("  ✅ Season 1 created (ID: 1)")
        print("  ✅ 4 Clubs created (IDs: 1, 2, 3, 4)")
        print("  ✅ 4 Season Clubs created (IDs: 101, 102, 103, 104)")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  ❌ Error creating season")
        print(f"     Stdout: {e.stdout}")
        print(f"     Stderr: {e.stderr}")
        print(f"     Command: {' '.join(cmd)}")
        return False

def create_player(player_id, user_id):
    """Create a player (Universe + Overgoal)"""
    overgoal_world, admin_address, _ = get_contract_addresses()
    
    # Player data
    calldata = [
        hex(player_id),
        hex(user_id),
        # Universe attributes
        hex(0),  # body_type
        hex(0),  # skin_color
        hex(1),  # beard_type
        hex(0),  # hair_type
        hex(0),  # hair_color
        # Overgoal attributes
        hex(50),  # energy
        hex(50),  # speed
        hex(50),  # leadership
        hex(50),  # pass
        hex(50),  # shoot
        hex(50),  # freekick
        hex(0),   # visor_type
        hex(0),   # visor_color
    ]
    
    cmd = [
        'sozo', 'execute',
        '--world', overgoal_world,
        admin_address,
        'seed_player',
        *calldata,
        '--wait'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"  ❌ Error creating player {player_id}")
        print(f"     Stdout: {e.stdout}")
        print(f"     Stderr: {e.stderr}")
        print(f"     Command: {' '.join(cmd)}")
        return False

def main():
    print("=" * 70)
    print("SETUP TEST DATA FOR assign_player_to_club")
    print("=" * 70)
    
    # Step 1: Create Season 1 (includes 4 clubs and 4 season clubs)
    if not create_season():
        print("\n❌ Failed to create season")
        sys.exit(1)
    
    # Step 2: Create 3 players
    print("\n🌱 Creating 3 players...")
    players = [
        (1, 1),  # Player 1, temporary user_id = 1
        (2, 2),  # Player 2, temporary user_id = 2
        (3, 3),  # Player 3, temporary user_id = 3
    ]
    
    for player_id, user_id in players:
        print(f"  Creating Player {player_id}...", end=" ")
        if create_player(player_id, user_id):
            print("✅")
        else:
            print("❌")
            sys.exit(1)
    
    # Summary
    print("\n" + "=" * 70)
    print("✅ TEST DATA SETUP COMPLETE!")
    print("=" * 70)
    print("\n📊 Created:")
    print("  • 1 Season (ID: 1)")
    print("  • 4 Clubs (IDs: 1=Cartridge Athletic, 2=Dojo United, 3=Nova United, 4=Drakon Core)")
    print("  • 4 Season Clubs (IDs: 101, 102, 103, 104)")
    print("  • 3 Players (IDs: 1, 2, 3) - Universe + Overgoal")
    print("\n📝 Players have temporary user_ids (1, 2, 3)")
    print("\n🎯 Next step: Use assign_player.py to assign players to clubs with real users")
    print("   Example: python3 scripts/assign_player.py --player-id 1 --user-id 100 --club-id 1")

if __name__ == '__main__':
    main()

