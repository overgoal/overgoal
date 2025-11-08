# OvergoalPlayer Model

## Purpose

`OvergoalPlayer` is a Dojo Model in an ECS world built with Cairo. It defines the storage layout for football player entities in the Overgoal game. Each entity stores a unique identifier, a foreign key reference to a UniversePlayer, football-specific attributes (speed, passing, shooting, etc.), game currency, energy, injury status, and visual customization (visor).

This model is part of a two-tier player system:
- **UniversePlayer** (in the `universe` contract): Base player with appearance and core attributes
- **OvergoalPlayer** (in the `overgoal` contract): Football-specific player stats and game mechanics

## Engine / Language

- **Engine**: Dojo (on Starknet)
- **Language**: Cairo
- **Storage types available**: `felt252`, `u8`, `u16`, `u128`, `bool`

## Field Specifications

### Primary Key
- **`id`** — Primary key. Stored as a `felt252`, representing a unique immutable identifier for this Overgoal player entity. Generated either on-chain or off-chain and hashed to fit in a felt. Immutable after creation.

### Foreign Key
- **`universe_player_id`** — Foreign key to `UniversePlayer.id`. Stored as a `felt252`. Links this Overgoal player to their corresponding Universe player. Required and immutable.

### Game Currency
- **`goal_currency`** — Stored as a `u128` providing large on-chain balance headroom for Overgoal-specific in-game economy transactions. Separate from `universe_currency`.

### Football Attributes
- **`energy`** — Stored as a `u16` (0–65535). Player's current energy level, affects ability to play matches.
- **`speed`** — Stored as a `u16` (0–65535). Football attribute affecting player movement and positioning.
- **`leadership`** — Stored as a `u16` (0–65535). Football attribute affecting team morale and captain abilities.
- **`pass`** — Stored as a `u16` (0–65535). Passing skill, affects accuracy and power of passes.
- **`shoot`** — Stored as a `u16` (0–65535). Shooting skill, affects goal-scoring ability.
- **`freekick`** — Stored as a `u16` (0–65535). Free kick skill, affects set-piece effectiveness.

### Game State
- **`is_injured`** — Stored as a `bool`. Injury status flag, affects player availability.

### Visual Customization
- **`visor_type`** — Stored as a `u8`. Visor type for visual customization (can be 0 for none, or 1-2 for different types).
- **`visor_color`** — Stored as a `u8`. Visor color for visual customization (can be 0 for none, or 1-2 for different colors).

## Keys and Indexes

- **Primary key**: `id` (felt252)
- **Foreign key**: `universe_player_id` references `UniversePlayer.id` in the Universe contract
- **Uniqueness**: `id` must be unique, `universe_player_id` allows multiple Overgoal players per Universe player (future-proofing for multiple game modes)

## Encoding and Validation

- **`id`**: Represented as a single felt252. Do not store raw UUID bytes; use hash or integer form. Must be non-zero.
- **`universe_player_id`**: Must reference a valid `UniversePlayer.id`. Cannot be zero.
- **`goal_currency`**: Valid range 0–2^128-1, allowing for large economic values.
- **`energy`**, **`speed`**, **`leadership`**, **`pass`**, **`shoot`**, **`freekick`**: Valid range 0–65535 (u16 bounds).
- **`is_injured`**: Boolean value (true/false).
- **`visor_type`**, **`visor_color`**: Valid range 0–255 (u8 bounds), typically 0-2 for current implementation.

## Invariants

- `id` never changes once set.
- `universe_player_id` never changes once set (permanent link to Universe player).
- All attribute values (speed, pass, shoot, etc.) must stay within u16 bounds.
- `goal_currency` must stay within u128 bounds.
- Energy can be depleted and restored through gameplay.
- Injury status can toggle based on game events.

## Dojo Implementation Details

- **Derives**: `Copy`, `Drop`, `Serde`, `IntrospectPacked`, `Debug`
- **Uses** `#[dojo::model]` attribute
- **Implements** `ZeroableOvergoalPlayerTrait` for `Zero<OvergoalPlayer>` trait with `zero()`, `is_zero()`, `is_non_zero()`
- **Implements** `OvergoalPlayerAssert` trait with `assert_exists()` and `assert_not_exists()`
- **Zero check**: Uses non-key fields (`universe_player_id`, `goal_currency`, `energy`) to determine if player exists

## Typical Systems

### Player Creation
- **`create_full_player(overgoal_player_id, universe_player_id, appearance_attrs, football_attrs)`**: Creates both UniversePlayer and OvergoalPlayer via cross-contract call (Method 1).
- **`create_overgoal_player(overgoal_player_id, universe_player_id, football_attrs)`**: Creates only OvergoalPlayer linked to existing UniversePlayer (Method 2).

### Attribute Management
- **`update_overgoal_player_stats(id, speed, leadership, pass, shoot, freekick)`**: Updates football attributes.
- **`add_energy(id, amount)`**: Restores player energy.
- **`spend_energy(id, amount)`**: Depletes player energy (with validation).

### Currency Management
- **`add_goal_currency(id, amount)`**: Safely adds to goal_currency balance.
- **`spend_goal_currency(id, amount)`**: Safely deducts from goal_currency with balance checks.

### Game State
- **`set_injury_status(id, is_injured)`**: Updates injury status.
- **`update_visor(id, visor_type, visor_color)`**: Updates visual customization.

### Queries
- **`overgoal_player_exists(id)`**: Checks if an Overgoal player is registered using `is_non_zero()`.

## Store Operations

- **`read_overgoal_player_from_id(id)`**: Reads player by primary key
- **`write_overgoal_player(player)`**: Writes player to storage
- **`create_overgoal_player(...)`**: Creates and stores new player with validation

## Cross-Contract Architecture

### Universe → Overgoal Relationship
- **Universe** doesn't know about Overgoal (one-way dependency)
- **Overgoal** knows about Universe and can call it via safe dispatchers
- **OvergoalPlayer** links to **UniversePlayer** via `universe_player_id`
- Cross-contract calls use `IUniverseSafeDispatcher` for safe interaction

### Two Creation Methods

**Method 1: Create Both Players**
```cairo
create_full_player(
    overgoal_player_id,
    universe_player_id,
    body_type, skin_color, beard_type, hair_type, hair_color,  // Universe appearance
    energy, speed, leadership, pass, shoot, freekick, visor_type, visor_color  // Overgoal stats
)
```
- Creates UniversePlayer in Universe contract
- Creates OvergoalPlayer in Overgoal contract
- Links them via `universe_player_id`
- Requires write permissions on Universe world

**Method 2: Create Overgoal Player Only**
```cairo
create_overgoal_player(
    overgoal_player_id,
    universe_player_id,  // Must already exist in Universe
    energy, speed, leadership, pass, shoot, freekick, visor_type, visor_color
)
```
- Creates only OvergoalPlayer
- Links to existing UniversePlayer
- No cross-contract call needed

## Example

An Overgoal player entity with ID `0xabc123` might have an `OvergoalPlayer` model with:

```
id = 0xabc123 (felt252)
universe_player_id = 0xdef456 (felt252, references UniversePlayer.id)
goal_currency = 10000 (u128)
energy = 85 (u16)
speed = 90 (u16)
leadership = 75 (u16)
pass = 88 (u16)
shoot = 92 (u16)
freekick = 80 (u16)
is_injured = false (bool)
visor_type = 2 (u8)
visor_color = 1 (u8)
```

## Reasoning Hints for Assistant

- Use `felt252` for the primary key (`id` field) to allow flexible identifier generation.
- Use `felt252` for `universe_player_id` foreign key to reference `UniversePlayer.id`.
- Use `u16` for football attributes to provide good range while conserving storage.
- Use `u128` for currency to handle large economic values without overflow.
- Use `u8` for visual customization to save storage (small range of options).
- Follow the Zero trait pattern for existence checking (`is_zero`/`is_non_zero`).
- Use `assert_exists()` and `assert_not_exists()` for validation in systems.
- Always validate `universe_player_id` exists before creating OvergoalPlayer.
- Use safe dispatchers (`IUniverseSafeDispatcher`) for cross-contract calls.

## Non-Goals

- No authentication or key management (handled by Universe contract).
- No appearance attributes (handled by UniversePlayer in Universe contract).
- No personally identifiable information beyond game attributes.
- No lists, collections, or nested structures in this core model.
- No direct ContractAddress usage for primary key - use felt252 for flexibility.
- No timestamps (player creation time tracked in UniversePlayer).

## Testing

All 11 unit tests for OvergoalPlayer model pass:
- Constructor validation (ID, universe_player_id)
- Zero value checks
- Energy operations (add/spend with validation)
- Currency operations (add/spend with validation)
- Injury status toggling
- Visor updates
- Assert traits (exists/not exists)

Integration tests verify:
- Cross-contract player creation (Method 1)
- Standalone player creation (Method 2)
- Attribute updates
- Currency management
- Injury status changes

