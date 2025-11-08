#!/usr/bin/env python3
"""Quick test to seed just ONE player"""

import json
import subprocess
import sys

# Get addresses
with open('manifest_dev.json', 'r') as f:
    manifest = json.load(f)
world_address = manifest['world']['address']
admin_address = None
for contract in manifest['contracts']:
    if contract['tag'] == 'overgoal-admin':
        admin_address = contract['address']
        break

print(f"World: {world_address}")
print(f"Admin: {admin_address}")

# Test player (Oliver Thompson - ID 1)
player_id = hex(1)
user_id = hex(1)
body_type = hex(0)
skin_color = hex(0)
beard_type = hex(1)
hair_type = hex(0)
hair_color = hex(0)
energy = hex(49)
speed = hex(51)
leadership = hex(46)
pass_stat = hex(49)
shoot = hex(49)
freekick = hex(49)
visor_type = hex(2)
visor_color = hex(0)

calldata = [
    player_id, user_id,
    body_type, skin_color, beard_type, hair_type, hair_color,
    energy, speed, leadership, pass_stat, shoot, freekick,
    visor_type, visor_color
]

print(f"\n🌱 Seeding player ID 1...")
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
    print("✅ Player seeded!")
    print(result.stdout)
except subprocess.CalledProcessError as e:
    print(f"❌ Error: {e}")
    print(f"Stdout: {e.stdout}")
    print(f"Stderr: {e.stderr}")
    sys.exit(1)

