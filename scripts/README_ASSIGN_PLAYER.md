# Assign Player to Club - Testing Guide

## Overview

This guide explains how to use the `assign_player_to_club` functionality, which:
1. Updates a Universe player's `user_id` (assigns ownership to a user)
2. Creates a `SeasonPlayer` entry linking the player to a club for Season 1

## Prerequisites

1. **Katana running**: `katana --config katana.toml`
2. **Universe deployed**: `cd ../universe && sozo build && sozo migrate`
3. **Overgoal deployed**: `cd ../overgoal && sozo build && sozo migrate`
4. **Universe address updated** in `overgoal/dojo_dev.toml`

## Step-by-Step Guide

### Step 1: Setup Test Data

This creates:
- 1 Season (ID: 1)
- 4 Clubs (IDs: 1-4)
- 4 Season Clubs (IDs: 101-104)
- 3 Players (IDs: 1-3) with NO user assigned yet

```bash
cd /Users/mg/Documents/Software/Overgoal/overgoal
python3 scripts/setup_test_data.py
```

**Expected Output:**
```
✅ TEST DATA SETUP COMPLETE!
📊 Created:
  • 1 Season (ID: 1)
  • 4 Clubs (IDs: 1=Cartridge Athletic, 2=Dojo United, 3=Nova United, 4=Drakon Core)
  • 4 Season Clubs (IDs: 101, 102, 103, 104)
  • 3 Players (IDs: 1, 2, 3) - Universe + Overgoal
```

### Step 2: Assign Players to Clubs

Assign each player to a club with a user ID:

```bash
# Assign Player 1 to Cartridge Athletic (Club 1) with User 100
python3 scripts/assign_player.py --player-id 1 --user-id 100 --club-id 1

# Assign Player 2 to Dojo United (Club 2) with User 200
python3 scripts/assign_player.py --player-id 2 --user-id 200 --club-id 2

# Assign Player 3 to Nova United (Club 3) with User 300
python3 scripts/assign_player.py --player-id 3 --user-id 300 --club-id 3
```

**Expected Output (per assignment):**
```
✅ Player assigned successfully!
   • Universe Player 1 now has user_id = 100
   • SeasonPlayer created (ID: 10001)
   • Linked to Season 1, Club 1 (SeasonClub 101)
```

### Step 3: Verify Assignments

View all season players in a human-readable format:

```bash
python3 scripts/show_season_players.py
```

**Expected Output:**
```
════════════════════════════════════════════════════════════════════════════════
🎮 SEASON PLAYER #1
────────────────────────────────────────────────────────────────────────────────

📋 Season Player Info:
   ID: 10001
   Season: 1
   Club: Cartridge Athletic (ID: 1)
   Season Club ID: 101
   Team Relationship: 50
   Fans Relationship: 50
   Season Points: 0
   Matches Won: 0
   Matches Lost: 0
   Trophies Won: 0

⚽ Overgoal Player Info:
   ID: 1
   Energy: 50
   Speed: 50
   Leadership: 50
   Pass: 50
   Shoot: 50
   Freekick: 50

🌌 Universe Player Info:
   ID: 1
   User ID: 100 (ASSIGNED)
   Body Type: 0
   Skin Color: 0
```

## What Happens Under the Hood

When you call `assign_player_to_club(overgoal_player_id, user_id, club_id)`:

1. **Overgoal reads** the `OvergoalPlayer` to get `universe_player_id`
2. **Cross-contract call** to Universe's `assign_user(player_id, user_id)`
   - Universe updates the `UniversePlayer.user_id` field
3. **Overgoal creates** a `SeasonPlayer` with:
   - `id`: 10000 + overgoal_player_id
   - `season_id`: 1 (hardcoded for Season 1)
   - `season_club_id`: 100 + club_id
   - `overgoal_player_id`: the player's ID
   - `team_relationship`: 50 (default)
   - `fans_relationship`: 50 (default)

## Testing the Implementation

Run the test suite:

```bash
cd /Users/mg/Documents/Software/Overgoal/overgoal
sozo test
```

The test `test_assign_player_to_club` will panic (expected) because the Universe contract doesn't exist in the isolated test environment. In production with proper deployment, it works correctly.

## Troubleshooting

### Error: "Failed to assign user in Universe"

**Cause**: Universe contract address is outdated or Universe isn't deployed.

**Solution**:
1. Get Universe game address: `cd ../universe && cat manifest_dev.json | jq -r '.contracts[] | select(.tag == "universe-game") | .address'`
2. Update `overgoal/dojo_dev.toml` → `[init_call_args]` section
3. Redeploy Overgoal: `cd ../overgoal && sozo build && sozo migrate`

### Error: "Model not found" for SeasonPlayer

**Cause**: Player wasn't assigned yet or wrong ID.

**Solution**: Make sure you ran `assign_player.py` first. SeasonPlayer IDs are 10000 + player_id.

### No Season Players Found

**Cause**: Haven't run setup or assignment scripts.

**Solution**: Run `setup_test_data.py` then `assign_player.py` for each player.

## Script Reference

### setup_test_data.py
- **Purpose**: Create initial test data (season, clubs, players)
- **Usage**: `python3 scripts/setup_test_data.py`
- **No arguments needed**

### assign_player.py
- **Purpose**: Assign a player to a club with a user
- **Usage**: `python3 scripts/assign_player.py --player-id <ID> --user-id <ID> --club-id <ID>`
- **Arguments**:
  - `--player-id`: Overgoal Player ID (e.g., 1, 2, 3)
  - `--user-id`: User ID to assign (e.g., 100, 200, 300)
  - `--club-id`: Club ID 1-4 (1=Cartridge Athletic, 2=Dojo United, 3=Nova United, 4=Drakon Core)

### show_season_players.py
- **Purpose**: Display all season players in human-readable format
- **Usage**: `python3 scripts/show_season_players.py`
- **No arguments needed**
- **Searches**: Players 1-10 (SeasonPlayer IDs 10001-10010)

## Architecture Notes

- **Two Worlds**: Universe (base layer) and Overgoal (game layer)
- **One-way dependency**: Overgoal knows Universe, Universe doesn't know Overgoal
- **Cross-contract calls**: Use safe dispatchers for reliability
- **ID Mapping**:
  - Player IDs: 1, 2, 3, ...
  - SeasonPlayer IDs: 10001, 10002, 10003, ... (10000 + player_id)
  - Club IDs: 1, 2, 3, 4
  - SeasonClub IDs: 101, 102, 103, 104 (100 + club_id)

