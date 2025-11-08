#!/usr/bin/env python3
"""Quick test to verify just the 3 missing players"""

import json
import subprocess
from pathlib import Path

# Get Overgoal world
with open('manifest_dev.json', 'r') as f:
    manifest = json.load(f)
overgoal_world = manifest['world']['address']

# Get Universe world
universe_manifest_path = Path(__file__).parent.parent.parent / "universe" / "manifest_dev.json"
with open(universe_manifest_path, 'r') as f:
    universe_manifest = json.load(f)
universe_world = universe_manifest['world']['address']

print(f"📍 Overgoal World: {overgoal_world}")
print(f"📍 Universe World: {universe_world}")

# The 3 missing player IDs
missing_ids = [51, 88, 103]

for player_id in missing_ids:
    player_id_hex = hex(player_id)
    print(f"\n{'='*60}")
    print(f"Checking Player ID {player_id} ({player_id_hex})")
    print('='*60)
    
    # Check OvergoalPlayer
    print(f"\n🔍 OvergoalPlayer...")
    cmd = ['sozo', 'model', 'get', 'OvergoalPlayer', player_id_hex, '--world', overgoal_world]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if "Model not found" in result.stdout:
        print("❌ NOT FOUND")
    elif "universe_player_id" in result.stdout:
        print("✅ FOUND")
    else:
        print("❓ UNKNOWN")
        print(result.stdout[:200])
    
    # Check UniversePlayer
    print(f"\n🔍 UniversePlayer...")
    universe_scarb = Path(__file__).parent.parent.parent / "universe" / "Scarb.toml"
    cmd = ['sozo', 'model', 'get', 'UniversePlayer', player_id_hex, '--world', universe_world, '--manifest-path', str(universe_scarb)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if "Model not found" in result.stdout:
        print("❌ NOT FOUND")
    elif "user_id" in result.stdout:
        print("✅ FOUND")
    else:
        print("❓ UNKNOWN")
        print(result.stdout[:200])
    
    # Check SeasonPlayer
    season_player_id = hex(10000 + player_id)
    print(f"\n🔍 SeasonPlayer (ID: {season_player_id})...")
    cmd = ['sozo', 'model', 'get', 'SeasonPlayer', season_player_id, '--world', overgoal_world]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if "Model not found" in result.stdout:
        print("❌ NOT FOUND")
    elif "season_id" in result.stdout:
        print("✅ FOUND")
    else:
        print("❓ UNKNOWN")
        print(result.stdout[:200])

print(f"\n{'='*60}")
print("✅ Verification complete!")
print('='*60)

