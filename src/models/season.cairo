use core::num::traits::zero::Zero;

// Season model representing a competitive season period
#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct Season {
    #[key]
    pub id: felt252,                    // Primary key - unique immutable identifier
    pub name: ByteArray,                // Season name
    pub start_date: u64,                // Unix timestamp when season begins
    pub end_date: u64,                  // Unix timestamp when season ends
    pub prize_pool: u128,               // Total prize pool in goal_currency
}

// Traits Implementations
#[generate_trait]
pub impl SeasonImpl of SeasonTrait {
    fn new(
        id: felt252, name: ByteArray, start_date: u64, end_date: u64, prize_pool: u128
    ) -> Season {
        // Validate inputs
        assert(id != 0, 'Season ID cannot be zero');
        assert(name.len() >= 3, 'Name must be at least 3 chars');
        assert(name.len() <= 100, 'Name must be at most 100 chars');
        assert(start_date > 0, 'Start date must be > 0');
        assert(end_date > start_date, 'End date must be > start date');

        Season { id, name, start_date, end_date, prize_pool }
    }

    fn extend_end_date(ref self: Season, new_end_date: u64) {
        assert(new_end_date > self.end_date, 'New end date must be later');
        self.end_date = new_end_date;
    }

    fn increase_prize_pool(ref self: Season, additional_amount: u128) {
        self.prize_pool += additional_amount;
    }

    fn is_active(self: @Season, current_time: u64) -> bool {
        current_time >= *self.start_date && current_time < *self.end_date
    }

    fn is_upcoming(self: @Season, current_time: u64) -> bool {
        current_time < *self.start_date
    }

    fn is_completed(self: @Season, current_time: u64) -> bool {
        current_time >= *self.end_date
    }
}

// Zeroable trait for Season
pub impl ZeroableSeasonTrait of Zero<Season> {
    fn zero() -> Season {
        Season { id: 0, name: "", start_date: 0, end_date: 0, prize_pool: 0 }
    }

    #[inline(always)]
    fn is_zero(self: @Season) -> bool {
        // Check non-key fields to determine if season exists
        self.name.len() == 0 && *self.start_date == 0 && *self.end_date == 0
    }

    #[inline(always)]
    fn is_non_zero(self: @Season) -> bool {
        !self.is_zero()
    }
}

// Assert trait for Season
#[generate_trait]
pub impl SeasonAssert of AssertSeasonTrait {
    #[inline(always)]
    fn assert_exists(self: @Season) {
        assert(self.is_non_zero(), 'Season does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: @Season) {
        assert(self.is_zero(), 'Season already exists');
    }

    #[inline(always)]
    fn assert_active(self: @Season, current_time: u64) {
        assert(self.is_active(current_time), 'Season is not active');
    }

    #[inline(always)]
    fn assert_not_started(self: @Season, current_time: u64) {
        assert(self.is_upcoming(current_time), 'Season already started');
    }
}

// ===============================================
// Unit Tests
// ===============================================

#[cfg(test)]
mod tests {
    use super::{Season, SeasonTrait, ZeroableSeasonTrait, AssertSeasonTrait};

    #[test]
    fn test_season_new_constructor() {
        let season = SeasonTrait::new(
            0x456, "Season 1: Genesis", 1704067200, 1711929600, 1000000000000000000000
        );

        assert(season.id == 0x456, 'ID should match');
        assert(season.name == "Season 1: Genesis", 'Name should match');
        assert(season.start_date == 1704067200, 'Start date should match');
        assert(season.end_date == 1711929600, 'End date should match');
        assert(season.prize_pool == 1000000000000000000000, 'Prize pool should match');
    }

    #[test]
    #[should_panic(expected: ('Season ID cannot be zero',))]
    fn test_season_creation_invalid_id() {
        SeasonTrait::new(0, "Test Season", 1000, 2000, 100);
    }

    #[test]
    #[should_panic(expected: ('Name must be at least 3 chars',))]
    fn test_season_creation_name_too_short() {
        SeasonTrait::new(0x456, "S1", 1000, 2000, 100);
    }

    #[test]
    #[should_panic(expected: ('Start date must be > 0',))]
    fn test_season_creation_invalid_start_date() {
        SeasonTrait::new(0x456, "Test Season", 0, 2000, 100);
    }

    #[test]
    #[should_panic(expected: ('End date must be > start date',))]
    fn test_season_creation_invalid_end_date() {
        SeasonTrait::new(0x456, "Test Season", 2000, 1000, 100);
    }

    #[test]
    fn test_season_extend_end_date() {
        let mut season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);
        season.extend_end_date(3000);

        assert(season.end_date == 3000, 'End date should be extended');
    }

    #[test]
    #[should_panic(expected: ('New end date must be later',))]
    fn test_season_extend_end_date_invalid() {
        let mut season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);
        season.extend_end_date(1500);
    }

    #[test]
    fn test_season_increase_prize_pool() {
        let mut season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);
        season.increase_prize_pool(50);

        assert(season.prize_pool == 150, 'Prize pool should increase');
    }

    #[test]
    fn test_season_is_active() {
        let season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);

        assert(season.is_active(1500), 'Should be active');
        assert(!season.is_active(500), 'Should not be active (before)');
        assert(!season.is_active(2500), 'Should not be active (after)');
    }

    #[test]
    fn test_season_is_upcoming() {
        let season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);

        assert(season.is_upcoming(500), 'Should be upcoming');
        assert(!season.is_upcoming(1500), 'Should not be upcoming');
    }

    #[test]
    fn test_season_is_completed() {
        let season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);

        assert(season.is_completed(2500), 'Should be completed');
        assert(!season.is_completed(1500), 'Should not be completed');
    }

    #[test]
    fn test_season_zero_values() {
        let zero_season = ZeroableSeasonTrait::zero();

        assert(zero_season.id == 0, 'Zero ID should be 0');
        assert(zero_season.name.len() == 0, 'Zero name should be empty');
        assert(zero_season.start_date == 0, 'Zero start should be 0');
        assert(zero_season.end_date == 0, 'Zero end should be 0');
        assert(zero_season.prize_pool == 0, 'Zero prize should be 0');
        assert(zero_season.is_zero(), 'Should be zero');
    }

    #[test]
    fn test_season_is_non_zero() {
        let season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);

        assert(season.is_non_zero(), 'Should be non-zero');
        assert(!season.is_zero(), 'Should not be zero');
    }

    #[test]
    fn test_season_assert_traits() {
        let season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);
        let zero_season = ZeroableSeasonTrait::zero();

        season.assert_exists();
        zero_season.assert_not_exists();
        season.assert_active(1500);
        season.assert_not_started(500);
    }

    #[test]
    #[should_panic(expected: ('Season does not exist',))]
    fn test_season_assert_exists_fails() {
        let zero_season = ZeroableSeasonTrait::zero();
        zero_season.assert_exists();
    }

    #[test]
    #[should_panic(expected: ('Season is not active',))]
    fn test_season_assert_active_fails() {
        let season = SeasonTrait::new(0x456, "Test Season", 1000, 2000, 100);
        season.assert_active(500);
    }
}

