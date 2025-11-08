#!/usr/bin/env python3
"""
Show all season players in a human-readable format
"""

import json
import subprocess
from pathlib import Path

def get_world_addresses():
    """Get world addresses from manifests"""
    # Overgoal
    with open('manifest_dev.json', 'r') as f:
        manifest = json.load(f)
    overgoal_world = manifest['world']['address']
    
    # Universe
    universe_manifest_path = Path(__file__).parent.parent.parent / "universe" / "manifest_dev.json"
    with open(universe_manifest_path, 'r') as f:
        universe_manifest = json.load(f)
    universe_world = universe_manifest['world']['address']
    
    return overgoal_world, universe_world

def parse_model_output(output):
    """Parse sozo model output into a dict"""
    data = {}
    for line in output.split('\n'):
        if ':' in line:
            parts = line.split(':', 1)
            if len(parts) == 2:
                key = parts[0].strip()
                value = parts[1].strip().rstrip(',')
                data[key] = value
    return data

def get_season_player(world_address, season_player_id):
    """Get a season player by ID"""
    cmd = ['sozo', 'model', 'get', 'SeasonPlayer', hex(season_player_id), '--world', world_address]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if 'Model not found' in result.stdout:
        return None
    
    return parse_model_output(result.stdout)

def get_overgoal_player(world_address, player_id):
    """Get an overgoal player by ID"""
    cmd = ['sozo', 'model', 'get', 'OvergoalPlayer', hex(player_id), '--world', world_address]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if 'Model not found' in result.stdout:
        return None
    
    return parse_model_output(result.stdout)

def get_universe_player(world_address, player_id):
    """Get a universe player by ID"""
    universe_scarb = Path(__file__).parent.parent.parent / "universe" / "Scarb.toml"
    cmd = ['sozo', 'model', 'get', 'UniversePlayer', hex(player_id), '--world', world_address, '--manifest-path', str(universe_scarb)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if 'Model not found' in result.stdout:
        return None
    
    return parse_model_output(result.stdout)

def get_club_name(club_id):
    """Get club name from ID"""
    clubs = {
        1: "Cartridge Athletic",
        2: "Dojo United",
        3: "Nova United",
        4: "Drakon Core"
    }
    return clubs.get(club_id, f"Club {club_id}")

def main():
    print("=" * 80)
    print("SEASON PLAYERS REPORT")
    print("=" * 80)
    
    overgoal_world, universe_world = get_world_addresses()
    
    print(f"\n📍 Overgoal World: {overgoal_world}")
    print(f"📍 Universe World: {universe_world}")
    
    # Check season players for IDs 10001-10010 (covers players 1-10)
    print("\n" + "=" * 80)
    print("SEARCHING FOR SEASON PLAYERS...")
    print("=" * 80)
    
    found_count = 0
    
    for player_id in range(1, 11):  # Check players 1-10
        season_player_id = 10000 + player_id
        season_player = get_season_player(overgoal_world, season_player_id)
        
        if season_player:
            found_count += 1
            
            # Get related data
            overgoal_player_id = int(season_player.get('overgoal_player_id', '0x0'), 16)
            season_club_id = int(season_player.get('season_club_id', '0x0'), 16)
            club_id = season_club_id - 100 if season_club_id > 100 else 0
            
            overgoal_player = get_overgoal_player(overgoal_world, overgoal_player_id)
            universe_player = get_universe_player(universe_world, overgoal_player_id)
            
            print(f"\n{'─' * 80}")
            print(f"🎮 SEASON PLAYER #{found_count}")
            print(f"{'─' * 80}")
            
            # Season Player Info
            print(f"\n📋 Season Player Info:")
            print(f"   ID: {season_player_id}")
            print(f"   Season: {int(season_player.get('season_id', '0x0'), 16)}")
            print(f"   Club: {get_club_name(club_id)} (ID: {club_id})")
            print(f"   Season Club ID: {season_club_id}")
            print(f"   Team Relationship: {int(season_player.get('team_relationship', '0'), 16)}")
            print(f"   Fans Relationship: {int(season_player.get('fans_relationship', '0'), 16)}")
            print(f"   Season Points: {int(season_player.get('season_points', '0'), 16)}")
            print(f"   Matches Won: {int(season_player.get('matches_won', '0'), 16)}")
            print(f"   Matches Lost: {int(season_player.get('matches_lost', '0'), 16)}")
            print(f"   Trophies Won: {int(season_player.get('trophies_won', '0'), 16)}")
            
            # Overgoal Player Info
            if overgoal_player:
                print(f"\n⚽ Overgoal Player Info:")
                print(f"   ID: {overgoal_player_id}")
                print(f"   Energy: {int(overgoal_player.get('energy', '0'), 16)}")
                print(f"   Speed: {int(overgoal_player.get('speed', '0'), 16)}")
                print(f"   Leadership: {int(overgoal_player.get('leadership', '0'), 16)}")
                print(f"   Pass: {int(overgoal_player.get('pass', '0'), 16)}")
                print(f"   Shoot: {int(overgoal_player.get('shoot', '0'), 16)}")
                print(f"   Freekick: {int(overgoal_player.get('freekick', '0'), 16)}")
            
            # Universe Player Info
            if universe_player:
                user_id = int(universe_player.get('user_id', '0x0'), 16)
                print(f"\n🌌 Universe Player Info:")
                print(f"   ID: {overgoal_player_id}")
                print(f"   User ID: {user_id} {'(ASSIGNED)' if user_id != 0 else '(NOT ASSIGNED)'}")
                print(f"   Body Type: {int(universe_player.get('body_type', '0'), 16)}")
                print(f"   Skin Color: {int(universe_player.get('skin_color', '0'), 16)}")
    
    print(f"\n{'=' * 80}")
    print(f"SUMMARY: Found {found_count} Season Player(s)")
    print("=" * 80)
    
    if found_count == 0:
        print("\n💡 No season players found. Run setup_test_data.py and assign_player.py first.")

if __name__ == '__main__':
    main()

