# Season Model

## Purpose

`Season` is a Dojo Model in an ECS world built with Cairo. It defines the storage layout for competitive season entities in the Overgoal game. Each season represents a time-bound competition period where clubs compete for prizes and rankings.

## Engine / Language

- **Engine**: Dojo (on Starknet)
- **Language**: Cairo
- **Storage types available**: `felt252`, `ByteArray`, `u64`, `u128`

## Field Specifications

### Primary Key
- **`id`** — Primary key. Stored as a `felt252`, representing a unique immutable identifier for this season entity. Generated either on-chain or off-chain and hashed to fit in a felt. Immutable after creation.

### Season Information
- **`name`** — Stored as a `ByteArray`. The season's display name (e.g., "Season 1: Genesis", "Winter Championship 2025"). Can be longer than 31 characters.

### Time Period
- **`start_date`** — Stored as a `u64` representing Unix epoch time in seconds (UTC). The timestamp when the season begins. Set once on creation.
- **`end_date`** — Stored as a `u64` representing Unix epoch time in seconds (UTC). The timestamp when the season ends. Must be greater than `start_date`.

### Prize Pool
- **`prize_pool`** — Stored as a `u128` providing large on-chain balance headroom for the total prize pool distributed to winners. Denominated in goal_currency.

## Keys and Indexes

- **Primary key**: `id` (felt252)
- **Recommended indexes**: `start_date`, `end_date` for querying active/past/future seasons
- **Uniqueness**: `id` must be unique, `name` should be unique across all seasons

## Encoding and Validation

- **`id`**: Represented as a single felt252. Do not store raw UUID bytes; use hash or integer form. Must be non-zero.
- **`name`**: ByteArray allows for season names of any reasonable length. Should be validated for appropriate characters and length limits (e.g., 3-100 characters).
- **`start_date`**: Must be greater than 0. Unix timestamp in seconds.
- **`end_date`**: Must be greater than `start_date`. Unix timestamp in seconds.
- **`prize_pool`**: Valid range 0–2^128-1. Must be non-negative.

## Invariants

- `id` never changes once set.
- `start_date` never changes once set.
- `end_date` must be greater than `start_date`.
- `end_date` can be extended but not shortened past current time.
- `prize_pool` can be increased but typically not decreased once set.
- Season state transitions: Upcoming → Active → Completed

## Dojo Implementation Details

- **Derives**: `Copy`, `Drop`, `Serde`, `IntrospectPacked`, `Debug`
- **Uses** `#[dojo::model]` attribute
- **Implements** `ZeroableSeasonTrait` for `Zero<Season>` trait with `zero()`, `is_zero()`, `is_non_zero()`
- **Implements** `SeasonAssert` trait with `assert_exists()` and `assert_not_exists()`

## Typical Systems

### Season Management
- **`create_season(id, name, start_date, end_date, prize_pool)`**: Creates a new season with time bounds and prize pool.
- **`extend_season(id, new_end_date)`**: Extends the end date of an active season.
- **`increase_prize_pool(id, additional_amount)`**: Adds to the season's prize pool.
- **`season_exists(id)`**: Checks if a season is registered using `is_non_zero()`.

### Season State Queries
- **`is_season_active(id)`**: Checks if current time is between start_date and end_date.
- **`is_season_upcoming(id)`**: Checks if start_date is in the future.
- **`is_season_completed(id)`**: Checks if end_date is in the past.
- **`get_active_seasons()`**: Returns all currently active seasons.

### Queries
- **`read_season_from_id(id)`**: Reads season by primary key.
- **`get_season_clubs(season_id)`**: Gets all clubs participating in this season (via SeasonClub).
- **`get_season_leaderboard(season_id)`**: Gets ranked clubs by season_points.

## Store Operations

- **`read_season_from_id(id)`**: Reads season by primary key
- **`write_season(season)`**: Writes season to storage
- **`create_season(...)`**: Creates and stores new season with validation

## Relationships

- **One-to-Many with SeasonClub**: A season has multiple participating clubs
- **One-to-Many with SeasonPlayer**: A season has multiple participating players (via SeasonClub)
- **Referenced by**: `SeasonClub.season_id`, `SeasonPlayer.season_id`

## Example

A season entity with ID `0x456def` might have a `Season` model with:

```
id = 0x456def (felt252)
name = "Season 1: Genesis Cup" (ByteArray)
start_date = 1704067200 (u64) // January 1, 2024 00:00:00 UTC
end_date = 1711929600 (u64)   // April 1, 2024 00:00:00 UTC
prize_pool = 1000000000000000000000 (u128) // 1M goal_currency
```

## Season Lifecycle

1. **Creation**: Season is created with future start_date
2. **Upcoming**: Current time < start_date (clubs can register)
3. **Active**: start_date ≤ current time < end_date (matches being played)
4. **Completed**: current time ≥ end_date (final rankings, prize distribution)

## Reasoning Hints for Assistant

- Use `felt252` for the primary key (`id` field) to allow flexible identifier generation.
- Use `ByteArray` for name to support descriptive season names.
- Use `u64` for timestamps to represent Unix epoch time in seconds.
- Use `u128` for prize_pool to handle large currency values without overflow.
- Follow the Zero trait pattern for existence checking (`is_zero`/`is_non_zero`).
- Use `assert_exists()` and `assert_not_exists()` for validation in systems.
- Always validate `end_date > start_date` when creating or updating seasons.
- Check season state (active/upcoming/completed) before allowing certain operations.

## Non-Goals

- No match scheduling details (handled by separate Match model).
- No real-time leaderboard updates (calculated from SeasonClub data).
- No prize distribution logic (handled by separate prize system).
- No season format/rules (can be extended with additional fields).
- No participant limits (enforced at application level or via separate config).

