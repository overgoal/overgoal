#!/usr/bin/env python3
"""
Assign a player to a club by calling overgoal_game.assign_player_to_club()
This will:
1. Update the Universe player's user_id
2. Create a SeasonPlayer entry
"""

import json
import subprocess
import sys
import argparse

def get_contract_addresses():
    """Get contract addresses from manifest"""
    with open('manifest_dev.json', 'r') as f:
        manifest = json.load(f)
    
    overgoal_world = manifest['world']['address']
    overgoal_game_address = None
    
    for contract in manifest['contracts']:
        if contract['tag'] == 'overgoal-overgoal_game':
            overgoal_game_address = contract['address']
            break
    
    if not overgoal_game_address:
        print("❌ overgoal_game contract not found!")
        sys.exit(1)
    
    return overgoal_world, overgoal_game_address

def assign_player(overgoal_player_id, user_id, club_id):
    """Assign a player to a club"""
    overgoal_world, overgoal_game_address = get_contract_addresses()
    
    print(f"\n🎯 Assigning Player {overgoal_player_id} to Club {club_id} with User {user_id}...")
    print(f"   World: {overgoal_world}")
    print(f"   Contract: {overgoal_game_address}")
    
    calldata = [
        hex(overgoal_player_id),
        hex(user_id),
        hex(club_id),
    ]
    
    cmd = [
        'sozo', 'execute',
        '--world', overgoal_world,
        overgoal_game_address,
        'assign_player_to_club',
        *calldata,
        '--wait'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("\n✅ Player assigned successfully!")
        print(f"   • Universe Player {overgoal_player_id} now has user_id = {user_id}")
        print(f"   • SeasonPlayer created (ID: {10000 + overgoal_player_id})")
        print(f"   • Linked to Season 1, Club {club_id} (SeasonClub {100 + club_id})")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n❌ Error: {e}")
        print(f"Stdout: {e.stdout}")
        print(f"Stderr: {e.stderr}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Assign a player to a club')
    parser.add_argument('--player-id', type=int, required=True, help='Overgoal Player ID')
    parser.add_argument('--user-id', type=int, required=True, help='User ID to assign')
    parser.add_argument('--club-id', type=int, required=True, help='Club ID (1-4)')
    
    args = parser.parse_args()
    
    print("=" * 70)
    print("ASSIGN PLAYER TO CLUB")
    print("=" * 70)
    
    if not assign_player(args.player_id, args.user_id, args.club_id):
        sys.exit(1)
    
    print("\n💡 Run show_season_players.py to verify the assignment")

if __name__ == '__main__':
    main()

