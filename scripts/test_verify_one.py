#!/usr/bin/env python3
"""Quick test to verify just ONE player"""

import json
import subprocess
import sys
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

player_id = "0x1"

# Check OvergoalPlayer
print(f"\n🔍 Checking OvergoalPlayer...")
cmd = ['sozo', 'model', 'get', 'OvergoalPlayer', player_id, '--world', overgoal_world]
result = subprocess.run(cmd, capture_output=True, text=True)
print(result.stdout)
if "Model not found" in result.stdout:
    print("❌ OvergoalPlayer NOT FOUND")
else:
    print("✅ OvergoalPlayer found")

# Check UniversePlayer
print(f"\n🔍 Checking UniversePlayer...")
universe_scarb = Path(__file__).parent.parent.parent / "universe" / "Scarb.toml"
cmd = ['sozo', 'model', 'get', 'UniversePlayer', player_id, '--world', universe_world, '--manifest-path', str(universe_scarb)]
result = subprocess.run(cmd, capture_output=True, text=True)

# Check for model data
if "user_id" in result.stdout and "Model not found" not in result.stdout:
    # Print the model data
    lines = result.stdout.split('\n')
    for i, line in enumerate(lines):
        if line.strip().startswith('{'):
            print('\n'.join(lines[i:]))
            break
    print("✅ UniversePlayer found")
else:
    print("❌ UniversePlayer NOT FOUND")
    print(result.stdout)

# Check SeasonPlayer
season_player_id = hex(10000 + 1)
print(f"\n🔍 Checking SeasonPlayer (ID: {season_player_id})...")
cmd = ['sozo', 'model', 'get', 'SeasonPlayer', season_player_id, '--world', overgoal_world]
result = subprocess.run(cmd, capture_output=True, text=True)
print(result.stdout)
if "Model not found" in result.stdout:
    print("❌ SeasonPlayer NOT FOUND")
else:
    print("✅ SeasonPlayer found")

