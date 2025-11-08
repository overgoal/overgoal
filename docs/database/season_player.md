# SeasonPlayer Model

## Purpose

`SeasonPlayer` is a Dojo Model in an ECS world built with Cairo. It defines the storage layout for player participation in a specific season with a specific club. This is a join table that tracks a player's performance, relationships, and achievements within a single season.

## Engine / Language

- **Engine**: Dojo (on Starknet)
- **Language**: Cairo
- **Storage types available**: `felt252`, `u16`, `u32`

## Field Specifications

### Primary Key
- **`id`** — Primary key. Stored as a `felt252`, representing a unique immutable identifier for this season-player participation entity. Generated either on-chain or off-chain and hashed to fit in a felt. Immutable after creation.

### Foreign Keys
- **`season_id`** — Foreign key to `Season.id`. Stored as a `felt252`. Links this participation record to a specific season. Immutable after creation.
- **`season_club_id`** — Foreign key to `SeasonClub.id`. Stored as a `felt252`. Links this player to a specific club's season participation. Can change if player transfers during season.
- **`overgoal_player_id`** — Foreign key to `OvergoalPlayer.id`. Stored as a `felt252`. Links this participation record to a specific player. Immutable after creation.

### Relationship Metrics
- **`team_relationship`** — Stored as a `u16` (0–65535). Player's relationship rating with their teammates. Affects team chemistry and performance.
- **`fans_relationship`** — Stored as a `u16` (0–65535). Player's relationship rating with the club's fans. Affects morale and marketability.

### Season Performance
- **`season_points`** — Stored as a `u32` (0–4,294,967,295). Total points contributed by this player during the season. Used for individual player rankings.

### Match Statistics
- **`matches_won`** — Stored as a `u16` (0–65535). Number of matches won while this player participated.
- **`matches_lost`** — Stored as a `u16` (0–65535). Number of matches lost while this player participated.

### Achievements
- **`trophies_won`** — Stored as a `u16` (0–65535). Number of trophies/awards won by this player during the season (e.g., Player of the Month, Golden Boot).

## Keys and Indexes

- **Primary key**: `id` (felt252)
- **Foreign keys**: 
  - `season_id` references `Season.id`
  - `season_club_id` references `SeasonClub.id`
  - `overgoal_player_id` references `OvergoalPlayer.id`
- **Composite uniqueness**: (`season_id`, `overgoal_player_id`) should be unique (a player can only participate once per season)
- **Recommended indexes**: `season_id`, `season_club_id`, `overgoal_player_id`, `season_points` (for leaderboard queries)

## Encoding and Validation

- **`id`**: Represented as a single felt252. Must be non-zero.
- **`season_id`**: Must reference a valid `Season.id`. Cannot be zero.
- **`season_club_id`**: Must reference a valid `SeasonClub.id`. Cannot be zero.
- **`overgoal_player_id`**: Must reference a valid `OvergoalPlayer.id`. Cannot be zero.
- **`team_relationship`**, **`fans_relationship`**: Valid range 0–65535 (u16 bounds). Typically 0-100 scale, but u16 allows for future expansion.
- **`season_points`**: Valid range 0–4,294,967,295 (u32 bounds).
- **`matches_won`**, **`matches_lost`**: Valid range 0–65535 (u16 bounds).
- **`trophies_won`**: Valid range 0–65535 (u16 bounds).

## Invariants

- `id` never changes once set.
- `season_id` never changes once set (player participation is locked to a season).
- `overgoal_player_id` never changes once set (participation record is for a specific player).
- `season_club_id` can change during the season (player transfers between clubs).
- `team_relationship` and `fans_relationship` can increase or decrease based on performance and events.
- `season_points` typically increases monotonically (good performances add points).
- `matches_won` and `matches_lost` increase monotonically.
- `trophies_won` increases monotonically (awards are cumulative).

## Dojo Implementation Details

- **Derives**: `Copy`, `Drop`, `Serde`, `IntrospectPacked`, `Debug`
- **Uses** `#[dojo::model]` attribute
- **Implements** `ZeroableSeasonPlayerTrait` for `Zero<SeasonPlayer>` trait with `zero()`, `is_zero()`, `is_non_zero()`
- **Implements** `SeasonPlayerAssert` trait with `assert_exists()` and `assert_not_exists()`

## Typical Systems

### Season Player Management
- **`register_player_for_season(season_id, season_club_id, overgoal_player_id)`**: Registers a player to participate in a season with a club.
- **`transfer_player(season_player_id, new_season_club_id)`**: Transfers player to a different club during the season.
- **`season_player_exists(id)`**: Checks if a season-player participation is registered.

### Relationship Updates
- **`update_team_relationship(id, change)`**: Adjusts player's relationship with teammates (positive or negative).
- **`update_fans_relationship(id, change)`**: Adjusts player's relationship with fans (positive or negative).
- **`calculate_relationships(season_player_id)`**: Recalculates relationships based on recent performance and events.

### Performance Tracking
- **`add_season_points(id, points)`**: Adds points for good performance (goals, assists, clean sheets, etc.).
- **`record_match_result(season_player_id, won: bool)`**: Updates matches_won or matches_lost.
- **`award_trophy(season_player_id, trophy_type)`**: Increments trophies_won when player wins an award.

### Queries
- **`read_season_player_from_id(id)`**: Reads season-player participation by primary key.
- **`get_player_season_stats(overgoal_player_id, season_id)`**: Gets a player's stats for a specific season.
- **`get_season_player_leaderboard(season_id)`**: Gets all players in a season ranked by season_points.
- **`get_club_roster(season_club_id)`**: Gets all players in a specific club for a season.
- **`get_player_season_history(overgoal_player_id)`**: Gets all seasons a player has participated in.

## Store Operations

- **`read_season_player_from_id(id)`**: Reads season-player participation by primary key
- **`write_season_player(season_player)`**: Writes season-player to storage
- **`create_season_player(...)`**: Creates and stores new participation with validation

## Relationships

- **Many-to-One with Season**: Multiple players participate in one season
- **Many-to-One with SeasonClub**: Multiple players belong to one season-club
- **Many-to-One with OvergoalPlayer**: A player participates in multiple seasons
- **Player can change clubs**: `season_club_id` can be updated during season (transfer)

## Example

A season-player participation entity with ID `0xjkl456` might have a `SeasonPlayer` model with:

```
id = 0xjkl456 (felt252)
season_id = 0x456def (felt252)        // References Season
season_club_id = 0x789ghi (felt252)   // References SeasonClub
overgoal_player_id = 0xabc123 (felt252) // References OvergoalPlayer
team_relationship = 85 (u16)          // Good relationship with teammates
fans_relationship = 92 (u16)          // Very popular with fans
season_points = 1250 (u32)            // High-performing player
matches_won = 18 (u16)
matches_lost = 2 (u16)
trophies_won = 3 (u16)                // Player of the Month (x2), Golden Boot
```

## Relationship Dynamics

### Team Relationship (0-100 scale)
- **0-20**: Poor relationship, negative impact on team chemistry
- **21-40**: Strained relationship, minor negative impact
- **41-60**: Neutral relationship, no impact
- **61-80**: Good relationship, positive impact on chemistry
- **81-100**: Excellent relationship, strong positive impact

### Fans Relationship (0-100 scale)
- **0-20**: Disliked by fans, negative morale
- **21-40**: Unpopular, minor negative morale
- **41-60**: Neutral standing
- **61-80**: Popular, positive morale boost
- **81-100**: Fan favorite, strong morale boost

### Factors Affecting Relationships
- **Team Relationship**: Performance, assists, teamwork, training, conflicts
- **Fans Relationship**: Goals, match ratings, loyalty, social media, controversies

## Season Points Calculation

Points can be earned from:
- **Goals scored**: 10-20 points depending on importance
- **Assists**: 5-10 points
- **Clean sheets** (defenders/goalkeepers): 5-10 points
- **Match rating**: 1-10 points per match
- **Trophies/Awards**: 50-100 points
- **Special achievements**: Variable points

## Reasoning Hints for Assistant

- Use `felt252` for all ID fields to allow flexible identifier generation.
- Use `u32` for `season_points` to handle large point totals over many matches.
- Use `u16` for relationships, match counts, and trophies to balance range and storage efficiency.
- Follow the Zero trait pattern for existence checking (`is_zero`/`is_non_zero`).
- Use `assert_exists()` and `assert_not_exists()` for validation in systems.
- Validate that `season_id`, `season_club_id`, and `overgoal_player_id` reference existing entities.
- Ensure (`season_id`, `overgoal_player_id`) combination is unique when creating new participation.
- Update relationships dynamically based on performance and events.
- Allow `season_club_id` to change for mid-season transfers.
- Track matches_won/lost separately from club statistics (player may not play every match).

## Non-Goals

- No detailed match performance data (handled by separate MatchPlayer model).
- No individual statistics like goals/assists (can be added as separate fields).
- No contract/salary information (handled by separate finance system).
- No injury history (tracked in OvergoalPlayer.is_injured).
- No training progress (can be extended with additional fields).
- No social media metrics (can be added as separate model).

