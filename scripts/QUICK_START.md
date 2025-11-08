# Quick Start Guide - Testing assign_player_to_club

## 🚀 Start Fresh Every Time

To clear everything and start with a clean slate:

```bash
cd /Users/mg/Documents/Software/Overgoal/overgoal
./scripts/restart_fresh.sh
```

This will:
1. ✅ Kill Katana
2. ✅ Start Katana fresh
3. ✅ Deploy Universe
4. ✅ Deploy Overgoal (with updated Universe address)
5. ✅ Show all contract addresses

**Time**: ~30 seconds

---

## 📊 Check What Exists

To see what data is already in the system:

```bash
python3 scripts/check_existing_data.py
```

Shows:
- Season 1
- Clubs 1-4
- Season Clubs 101-104
- Players 1-3
- Season Players (assignments)

---

## 🌱 Setup Test Data

Create initial data (season, clubs, players):

```bash
python3 scripts/setup_test_data.py
```

Creates:
- 1 Season (ID: 1)
- 4 Clubs (IDs: 1-4)
- 4 Season Clubs (IDs: 101-104)
- 3 Players (IDs: 1-3) with NO user assigned

**Note**: If you get "Season already exists", the data is already there!

---

## 🎯 Assign Players to Clubs

Assign a player to a club with a user:

```bash
# Player 1 → Cartridge Athletic (Club 1) with User 100
python3 scripts/assign_player.py --player-id 1 --user-id 100 --club-id 1

# Player 2 → Dojo United (Club 2) with User 200
python3 scripts/assign_player.py --player-id 2 --user-id 200 --club-id 2

# Player 3 → Nova United (Club 3) with User 300
python3 scripts/assign_player.py --player-id 3 --user-id 300 --club-id 3
```

This calls `overgoal_game.assign_player_to_club()` which:
1. Updates Universe player's `user_id`
2. Creates a `SeasonPlayer` entry

---

## 👀 View Results

See all season players in human-readable format:

```bash
python3 scripts/show_season_players.py
```

Shows for each player:
- Season Player info (club, relationships, stats)
- Overgoal Player info (energy, speed, etc.)
- Universe Player info (user_id assignment)

---

## 🔄 Complete Workflow

```bash
# 1. Start fresh
./scripts/restart_fresh.sh

# 2. Setup data
python3 scripts/setup_test_data.py

# 3. Assign players
python3 scripts/assign_player.py --player-id 1 --user-id 100 --club-id 1
python3 scripts/assign_player.py --player-id 2 --user-id 200 --club-id 2
python3 scripts/assign_player.py --player-id 3 --user-id 300 --club-id 3

# 4. Verify
python3 scripts/show_season_players.py
```

---

## 📝 Available Scripts

| Script | Purpose |
|--------|---------|
| `restart_fresh.sh` | Kill Katana, redeploy everything fresh |
| `check_existing_data.py` | Check what data exists |
| `setup_test_data.py` | Create season, clubs, players |
| `assign_player.py` | Assign player to club with user |
| `show_season_players.py` | Display all season players |

---

## 🏆 Club IDs

- **1** = Cartridge Athletic
- **2** = Dojo United
- **3** = Nova United
- **4** = Drakon Core

Season Club IDs = 100 + Club ID (101, 102, 103, 104)

---

## 🐛 Troubleshooting

### "Season already exists"
✅ Data is already there! Skip `setup_test_data.py` and go to `assign_player.py`

### "Failed to assign user in Universe"
❌ Universe address is wrong. Run `./scripts/restart_fresh.sh` to fix.

### "Model not found"
❌ Data doesn't exist. Run `setup_test_data.py` first.

### Katana not responding
❌ Kill and restart: `pkill -f katana && ./scripts/restart_fresh.sh`

---

## 💡 Tips

- Always run scripts from `/Users/mg/Documents/Software/Overgoal/overgoal` directory
- Use `check_existing_data.py` before setup to avoid "already exists" errors
- `restart_fresh.sh` is your friend - use it liberally!
- Katana logs are in `/tmp/katana.log`

