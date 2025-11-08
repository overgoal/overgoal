# SeasonClub Model

## Purpose

`SeasonClub` is a Dojo Model in an ECS world built with Cairo. It defines the storage layout for club participation in a specific season. This is a join table that tracks a club's performance, management, and statistics within a single season.

## Engine / Language

- **Engine**: Dojo (on Starknet)
- **Language**: Cairo
- **Storage types available**: `felt252`, `u16`, `u32`

## Field Specifications

### Primary Key
- **`id`** — Primary key. Stored as a `felt252`, representing a unique immutable identifier for this season-club participation entity. Generated either on-chain or off-chain and hashed to fit in a felt. Immutable after creation.

### Foreign Keys
- **`season_id`** — Foreign key to `Season.id`. Stored as a `felt252`. Links this participation record to a specific season. Immutable after creation.
- **`club_id`** — Foreign key to `Club.id`. Stored as a `felt252`. Links this participation record to a specific club. Immutable after creation.

### Management
- **`manager_id`** — Foreign key to `OvergoalPlayer.id`. Stored as a `felt252`. The player acting as the club's manager for this season. Can be changed during the season.
- **`coach_id`** — Foreign key to `OvergoalPlayer.id`. Stored as a `felt252`. The player acting as the club's coach for this season. Can be changed during the season.

### Season Performance
- **`season_points`** — Stored as a `u32` (0–4,294,967,295). Total points accumulated during the season. Used for leaderboard ranking.

### Team Attributes
- **`offense`** — Stored as a `u16` (0–65535). Team's offensive rating, affects attacking performance.
- **`defense`** — Stored as a `u16` (0–65535). Team's defensive rating, affects defensive performance.
- **`intensity`** — Stored as a `u16` (0–65535). Team's intensity/aggression level, affects playstyle.
- **`chemistry`** — Stored as a `u16` (0–65535). Team chemistry rating, affects overall team coordination.

### Match Statistics
- **`matches_won`** — Stored as a `u16` (0–65535). Number of matches won during the season.
- **`matches_lost`** — Stored as a `u16` (0–65535). Number of matches lost during the season.
- **`matches_drawn`** — Stored as a `u16` (0–65535). Number of matches drawn during the season.

## Keys and Indexes

- **Primary key**: `id` (felt252)
- **Foreign keys**: 
  - `season_id` references `Season.id`
  - `club_id` references `Club.id`
  - `manager_id` references `OvergoalPlayer.id`
  - `coach_id` references `OvergoalPlayer.id`
- **Composite uniqueness**: (`season_id`, `club_id`) should be unique (a club can only participate once per season)
- **Recommended indexes**: `season_id`, `club_id`, `season_points` (for leaderboard queries)

## Encoding and Validation

- **`id`**: Represented as a single felt252. Must be non-zero.
- **`season_id`**: Must reference a valid `Season.id`. Cannot be zero.
- **`club_id`**: Must reference a valid `Club.id`. Cannot be zero.
- **`manager_id`**: Must reference a valid `OvergoalPlayer.id`. Cannot be zero.
- **`coach_id`**: Must reference a valid `OvergoalPlayer.id`. Cannot be zero.
- **`season_points`**: Valid range 0–4,294,967,295 (u32 bounds).
- **`offense`**, **`defense`**, **`intensity`**, **`chemistry`**: Valid range 0–65535 (u16 bounds).
- **`matches_won`**, **`matches_lost`**, **`matches_drawn`**: Valid range 0–65535 (u16 bounds).

## Invariants

- `id` never changes once set.
- `season_id` never changes once set (club participation is locked to a season).
- `club_id` never changes once set (participation record is for a specific club).
- `manager_id` and `coach_id` can be changed during the season (management changes).
- Total matches = `matches_won` + `matches_lost` + `matches_drawn`.
- `season_points` typically increases monotonically (wins/draws add points).
- Team attributes (`offense`, `defense`, `intensity`, `chemistry`) can be updated based on player roster and training.

## Dojo Implementation Details

- **Derives**: `Copy`, `Drop`, `Serde`, `IntrospectPacked`, `Debug`
- **Uses** `#[dojo::model]` attribute
- **Implements** `ZeroableSeasonClubTrait` for `Zero<SeasonClub>` trait with `zero()`, `is_zero()`, `is_non_zero()`
- **Implements** `SeasonClubAssert` trait with `assert_exists()` and `assert_not_exists()`

## Typical Systems

### Season Club Management
- **`register_club_for_season(season_id, club_id, manager_id, coach_id)`**: Registers a club to participate in a season.
- **`change_manager(season_club_id, new_manager_id)`**: Changes the club's manager during the season.
- **`change_coach(season_club_id, new_coach_id)`**: Changes the club's coach during the season.
- **`season_club_exists(id)`**: Checks if a season-club participation is registered.

### Team Attribute Updates
- **`update_team_attributes(id, offense, defense, intensity, chemistry)`**: Updates team ratings based on roster/training.
- **`calculate_team_chemistry(season_club_id)`**: Recalculates chemistry based on player relationships.

### Match Result Recording
- **`record_match_win(season_club_id, points_earned)`**: Increments matches_won and adds points.
- **`record_match_loss(season_club_id)`**: Increments matches_lost.
- **`record_match_draw(season_club_id, points_earned)`**: Increments matches_drawn and adds points.

### Queries
- **`read_season_club_from_id(id)`**: Reads season-club participation by primary key.
- **`get_club_season_stats(club_id, season_id)`**: Gets a club's stats for a specific season.
- **`get_season_leaderboard(season_id)`**: Gets all clubs in a season ranked by season_points.
- **`get_club_roster(season_club_id)`**: Gets all players in this club for this season (via SeasonPlayer).

## Store Operations

- **`read_season_club_from_id(id)`**: Reads season-club participation by primary key
- **`write_season_club(season_club)`**: Writes season-club to storage
- **`create_season_club(...)`**: Creates and stores new participation with validation

## Relationships

- **Many-to-One with Season**: Multiple clubs participate in one season
- **Many-to-One with Club**: A club participates in multiple seasons
- **Many-to-One with OvergoalPlayer (manager)**: A player can manage multiple clubs across seasons
- **Many-to-One with OvergoalPlayer (coach)**: A player can coach multiple clubs across seasons
- **One-to-Many with SeasonPlayer**: A season-club has multiple players
- **Referenced by**: `SeasonPlayer.season_club_id`

## Example

A season-club participation entity with ID `0x789ghi` might have a `SeasonClub` model with:

```
id = 0x789ghi (felt252)
season_id = 0x456def (felt252) // References Season
club_id = 0x123abc (felt252)   // References Club
manager_id = 0xaaa111 (felt252) // References OvergoalPlayer
coach_id = 0xbbb222 (felt252)   // References OvergoalPlayer
season_points = 45 (u32)        // 15 wins * 3 points
offense = 85 (u16)
defense = 78 (u16)
intensity = 82 (u16)
chemistry = 90 (u16)
matches_won = 15 (u16)
matches_lost = 3 (u16)
matches_drawn = 2 (u16)
// Total matches: 20
```

## Leaderboard Calculation

Season rankings are determined by:
1. **Primary**: `season_points` (descending)
2. **Tiebreaker 1**: Goal difference (calculated from match data)
3. **Tiebreaker 2**: Goals scored (calculated from match data)
4. **Tiebreaker 3**: Head-to-head results

## Reasoning Hints for Assistant

- Use `felt252` for all ID fields to allow flexible identifier generation.
- Use `u32` for `season_points` to handle large point totals over many matches.
- Use `u16` for team attributes and match counts to balance range and storage efficiency.
- Follow the Zero trait pattern for existence checking (`is_zero`/`is_non_zero`).
- Use `assert_exists()` and `assert_not_exists()` for validation in systems.
- Validate that `season_id`, `club_id`, `manager_id`, and `coach_id` reference existing entities.
- Ensure (`season_id`, `club_id`) combination is unique when creating new participation.
- Update team attributes when roster changes (players join/leave).
- Recalculate chemistry when player relationships change.

## Non-Goals

- No detailed match history (handled by separate Match model).
- No player roster list (handled by SeasonPlayer join table).
- No financial data (handled by separate club finance system).
- No tactical formations (can be extended with additional fields).
- No training/facility levels (can be added as separate model).

