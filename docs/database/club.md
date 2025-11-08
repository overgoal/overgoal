# Club Model

## Purpose

`Club` is a Dojo Model in an ECS world built with Cairo. It defines the storage layout for football club entities in the Overgoal game. Each club represents a team organization that can participate in seasons and competitions.

## Engine / Language

- **Engine**: Dojo (on Starknet)
- **Language**: Cairo
- **Storage types available**: `felt252`, `ByteArray`

## Field Specifications

### Primary Key
- **`id`** — Primary key. Stored as a `felt252`, representing a unique immutable identifier for this club entity. Generated either on-chain or off-chain and hashed to fit in a felt. Immutable after creation.

### Club Information
- **`name`** — Stored as a `ByteArray`. The club's display name (e.g., "Manchester United", "Real Madrid"). Can be longer than 31 characters. Should be unique across all clubs.

## Keys and Indexes

- **Primary key**: `id` (felt252)
- **Recommended index**: `name` for fast lookups
- **Uniqueness**: `id` must be unique, `name` should be unique across all clubs

## Encoding and Validation

- **`id`**: Represented as a single felt252. Do not store raw UUID bytes; use hash or integer form. Must be non-zero.
- **`name`**: ByteArray allows for club names of any reasonable length. Should be validated for appropriate characters and length limits (e.g., 3-50 characters).

## Invariants

- `id` never changes once set.
- `name` can be updated via a dedicated rename system but should remain unique.
- Club entity persists across multiple seasons.

## Dojo Implementation Details

- **Derives**: `Copy`, `Drop`, `Serde`, `IntrospectPacked`, `Debug`
- **Uses** `#[dojo::model]` attribute
- **Implements** `ZeroableClubTrait` for `Zero<Club>` trait with `zero()`, `is_zero()`, `is_non_zero()`
- **Implements** `ClubAssert` trait with `assert_exists()` and `assert_not_exists()`

## Typical Systems

### Club Management
- **`create_club(id, name)`**: Creates a new club with unique ID and name.
- **`rename_club(id, new_name)`**: Updates club name while preserving uniqueness.
- **`club_exists(id)`**: Checks if a club is registered using `is_non_zero()`.

### Queries
- **`read_club_from_id(id)`**: Reads club by primary key.
- **`get_clubs_in_season(season_id)`**: Gets all clubs participating in a specific season (via SeasonClub join).

## Store Operations

- **`read_club_from_id(id)`**: Reads club by primary key
- **`write_club(club)`**: Writes club to storage
- **`create_club(id, name)`**: Creates and stores new club with validation

## Relationships

- **One-to-Many with SeasonClub**: A club can participate in multiple seasons
- **Referenced by**: `SeasonClub.club_id`

## Example

A club entity with ID `0x123abc` might have a `Club` model with:

```
id = 0x123abc (felt252)
name = "Cyber Lions FC" (ByteArray)
```

## Reasoning Hints for Assistant

- Use `felt252` for the primary key (`id` field) to allow flexible identifier generation.
- Use `ByteArray` for name to support club names longer than 31 characters.
- Follow the Zero trait pattern for existence checking (`is_zero`/`is_non_zero`).
- Use `assert_exists()` and `assert_not_exists()` for validation in systems.
- Validate name uniqueness before creating or renaming clubs.

## Non-Goals

- No owner/management information (handled by SeasonClub with manager_id).
- No historical statistics (tracked per season in SeasonClub).
- No logo or visual assets (can be added as separate metadata).
- No location or stadium information (can be extended later).

