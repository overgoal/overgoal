#!/usr/bin/env python3
"""
Script to seed all players from players.json into the Overgoal game.
This script:
1. Reads players from players.json
2. Creates UniversePlayer and OvergoalPlayer for each player via admin.seed_player()
3. Creates SeasonPlayer for each player via admin.seed_season_player()
"""

import json
import subprocess
import sys
from pathlib import Path

# Configuration
PLAYERS_JSON_PATH = Path(__file__).parent.parent.parent / "docs" / "players.json"
SEASON_ID = 1  # Season 1
def load_players():
    """Load players from players.json"""
    print(f"📖 Loading players from {PLAYERS_JSON_PATH}")
    with open(PLAYERS_JSON_PATH, 'r') as f:
        players = json.load(f)
    print(f"✅ Loaded {len(players)} players")
    return players

def get_contract_addresses():
    """Get contract addresses from manifest"""
    print("📍 Reading contract addresses from manifest...")
    try:
        with open('manifest_dev.json', 'r') as f:
            manifest = json.load(f)
        
        world_address = manifest['world']['address']
        admin_address = None
        
        for contract in manifest['contracts']:
            if contract['tag'] == 'overgoal-admin':
                admin_address = contract['address']
                break
        
        if not admin_address:
            print("❌ Admin contract not found in manifest!")
            sys.exit(1)
        
        print(f"✅ World: {world_address}")
        print(f"✅ Admin: {admin_address}")
        return world_address, admin_address
    except Exception as e:
        print(f"❌ Error reading manifest: {e}")
        sys.exit(1)

def seed_player(admin_address, world_address, player):
    """Seed a single player (creates both Universe and Overgoal players)"""
    player_id = player['user_id']
    
    # Prepare calldata for seed_player (all values must be in hex format)
    calldata = [
        hex(player_id),  # player_id
        hex(player['user_id']),  # user_id
        # Universe player attributes
        hex(player['body_type']),
        hex(player['skin_color']),
        hex(player['beard_type']),
        hex(player['hair_type']),
        hex(player['hair_color']),
        # Overgoal player attributes
        hex(player['energy']),
        hex(player['speed']),
        hex(player['leadership']),
        hex(player['pass']),
        hex(player['shoot']),
        hex(player['freekick']),
        hex(player['visor_type']),
        hex(player['visor_color']),
    ]
    
    # Call sozo execute
    # Format: sozo execute --world <WORLD> <CONTRACT> <ENTRYPOINT> <CALLDATA...>
    cmd = [
        'sozo', 'execute',
        '--world', world_address,
        admin_address,
        'seed_player',
        *calldata,
        '--wait'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n  ❌ Command: {' '.join(cmd)}")
        print(f"  ❌ Stdout: {e.stdout}")
        print(f"  ❌ Stderr: {e.stderr}")
        return False

def seed_season_player(admin_address, world_address, player):
    """Seed a single season player"""
    player_id = player['user_id']
    team_id = player['team_id']
    
    # Convert JSON team_id (0-3) to season_club_id (101-104)
    # JSON team_id 0 → club 1 (season_club_id 101)
    # JSON team_id 1 → club 2 (season_club_id 102)
    # JSON team_id 2 → club 3 (season_club_id 103)
    # JSON team_id 3 → club 4 (season_club_id 104)
    season_club_id = 101 + team_id  # 0→101, 1→102, 2→103, 3→104
    
    # All players have teams now (no skip needed)
    
    # season_player_id will be unique: 10000 + player_id
    season_player_id = 10000 + player_id
    
    # Prepare calldata for seed_season_player (all values must be in hex format)
    calldata = [
        hex(season_player_id),  # season_player_id
        hex(SEASON_ID),  # season_id
        hex(season_club_id),  # season_club_id
        hex(player_id),  # overgoal_player_id
    ]
    
    # Call sozo execute
    # Format: sozo execute --world <WORLD> <CONTRACT> <ENTRYPOINT> <CALLDATA...>
    cmd = [
        'sozo', 'execute',
        '--world', world_address,
        admin_address,
        'seed_season_player',
        *calldata,
        '--wait'
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n  ❌ Command: {' '.join(cmd)}")
        print(f"  ❌ Stdout: {e.stdout}")
        print(f"  ❌ Stderr: {e.stderr}")
        return False

def main():
    print("🌱 Starting player seeding process...")
    print("=" * 60)
    
    # Load players
    players = load_players()
    
    # Get contract addresses
    world_address, admin_address = get_contract_addresses()
    
    print("\n" + "=" * 60)
    print("STEP 1: Creating Universe and Overgoal Players")
    print("=" * 60)
    
    # Seed all players (creates both Universe and Overgoal players)
    success_count = 0
    fail_count = 0
    
    for i, player in enumerate(players, 1):
        player_name = player.get('player_name', f"Player {player['user_id']}")
        print(f"[{i}/{len(players)}] Seeding {player_name} (ID: {player['user_id']})...", end=" ")
        
        if seed_player(admin_address, world_address, player):
            print("✅")
            success_count += 1
        else:
            print("❌")
            fail_count += 1
    
    print(f"\n✅ Players created: {success_count}/{len(players)}")
    if fail_count > 0:
        print(f"❌ Failed: {fail_count}")
    
    print("\n" + "=" * 60)
    print("STEP 2: Creating Season Players")
    print("=" * 60)
    
    # Seed season players (only for players with team_id > 0)
    season_success = 0
    season_fail = 0
    season_skip = 0
    
    for i, player in enumerate(players, 1):
        player_name = player.get('player_name', f"Player {player['user_id']}")
        team_id = player['team_id']
        
        print(f"[{i}/{len(players)}] Seeding season player for {player_name} (Team {team_id})...", end=" ")
        
        if seed_season_player(admin_address, world_address, player):
            print("✅")
            season_success += 1
        else:
            print("❌")
            season_fail += 1
    
    print(f"\n✅ Season players created: {season_success}")
    if season_fail > 0:
        print(f"❌ Failed: {season_fail}")
    
    print("\n" + "=" * 60)
    print("🎉 SEEDING COMPLETE!")
    print("=" * 60)
    print(f"Total players: {len(players)}")
    print(f"Players created: {success_count}")
    print(f"Season players created: {season_success}")
    
    if fail_count > 0 or season_fail > 0:
        print(f"\n⚠️  Some operations failed. Check the errors above.")
        sys.exit(1)
    
    print(f"\n✅ All done! Run './scripts/verify_players.py' to verify the data.")

if __name__ == '__main__':
    main()

