use core::num::traits::zero::Zero;

// SeasonPlayer model representing a player's participation in a specific season
#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct SeasonPlayer {
    #[key]
    pub id: felt252,                    // Primary key - unique immutable identifier
    pub season_id: felt252,             // Foreign key to Season
    pub season_club_id: felt252,        // Foreign key to SeasonClub (can change on transfer)
    pub overgoal_player_id: felt252,    // Foreign key to OvergoalPlayer
    pub team_relationship: u16,         // Relationship with teammates (0-100)
    pub fans_relationship: u16,         // Relationship with fans (0-100)
    pub season_points: u32,             // Total points contributed
    pub matches_won: u16,               // Matches won while participating
    pub matches_lost: u16,              // Matches lost while participating
    pub trophies_won: u16,              // Trophies/awards won
}

// Traits Implementations
#[generate_trait]
pub impl SeasonPlayerImpl of SeasonPlayerTrait {
    fn new(
        id: felt252,
        season_id: felt252,
        season_club_id: felt252,
        overgoal_player_id: felt252,
        team_relationship: u16,
        fans_relationship: u16,
    ) -> SeasonPlayer {
        // Validate inputs
        assert(id != 0, 'SeasonPlayer ID cannot be 0');
        assert(season_id != 0, 'Season ID required');
        assert(season_club_id != 0, 'SeasonClub ID required');
        assert(overgoal_player_id != 0, 'Player ID required');

        SeasonPlayer {
            id,
            season_id,
            season_club_id,
            overgoal_player_id,
            team_relationship,
            fans_relationship,
            season_points: 0,
            matches_won: 0,
            matches_lost: 0,
            trophies_won: 0,
        }
    }

    fn transfer_to_club(ref self: SeasonPlayer, new_season_club_id: felt252) {
        assert(new_season_club_id != 0, 'SeasonClub ID required');
        self.season_club_id = new_season_club_id;
    }

    fn update_team_relationship(ref self: SeasonPlayer, change: i16) {
        // Apply change with bounds checking (0-100)
        let new_value = if change >= 0 {
            let increase: u16 = change.try_into().unwrap();
            if self.team_relationship + increase > 100 {
                100
            } else {
                self.team_relationship + increase
            }
        } else {
            let decrease: u16 = (-change).try_into().unwrap();
            if self.team_relationship < decrease {
                0
            } else {
                self.team_relationship - decrease
            }
        };
        self.team_relationship = new_value;
    }

    fn update_fans_relationship(ref self: SeasonPlayer, change: i16) {
        // Apply change with bounds checking (0-100)
        let new_value = if change >= 0 {
            let increase: u16 = change.try_into().unwrap();
            if self.fans_relationship + increase > 100 {
                100
            } else {
                self.fans_relationship + increase
            }
        } else {
            let decrease: u16 = (-change).try_into().unwrap();
            if self.fans_relationship < decrease {
                0
            } else {
                self.fans_relationship - decrease
            }
        };
        self.fans_relationship = new_value;
    }

    fn add_season_points(ref self: SeasonPlayer, points: u32) {
        self.season_points += points;
    }

    fn record_match_win(ref self: SeasonPlayer) {
        self.matches_won += 1;
    }

    fn record_match_loss(ref self: SeasonPlayer) {
        self.matches_lost += 1;
    }

    fn award_trophy(ref self: SeasonPlayer) {
        self.trophies_won += 1;
    }
}

// Zeroable trait for SeasonPlayer
pub impl ZeroableSeasonPlayerTrait of Zero<SeasonPlayer> {
    fn zero() -> SeasonPlayer {
        SeasonPlayer {
            id: 0,
            season_id: 0,
            season_club_id: 0,
            overgoal_player_id: 0,
            team_relationship: 0,
            fans_relationship: 0,
            season_points: 0,
            matches_won: 0,
            matches_lost: 0,
            trophies_won: 0,
        }
    }

    #[inline(always)]
    fn is_zero(self: @SeasonPlayer) -> bool {
        // Check non-key fields to determine if season-player exists
        *self.season_id == 0 && *self.season_club_id == 0 && *self.overgoal_player_id == 0
    }

    #[inline(always)]
    fn is_non_zero(self: @SeasonPlayer) -> bool {
        !self.is_zero()
    }
}

// Assert trait for SeasonPlayer
#[generate_trait]
pub impl SeasonPlayerAssert of AssertSeasonPlayerTrait {
    #[inline(always)]
    fn assert_exists(self: @SeasonPlayer) {
        assert(self.is_non_zero(), 'SeasonPlayer does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: @SeasonPlayer) {
        assert(self.is_zero(), 'SeasonPlayer already exists');
    }
}

// ===============================================
// Unit Tests
// ===============================================

#[cfg(test)]
mod tests {
    use super::{SeasonPlayer, SeasonPlayerTrait, ZeroableSeasonPlayerTrait, AssertSeasonPlayerTrait};

    #[test]
    fn test_season_player_new_constructor() {
        let season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);

        assert(season_player.id == 0x111, 'ID should match');
        assert(season_player.season_id == 0x456, 'Season ID should match');
        assert(season_player.season_club_id == 0x789, 'SeasonClub ID should match');
        assert(season_player.overgoal_player_id == 0xabc, 'Player ID should match');
        assert(season_player.team_relationship == 85, 'Team rel should match');
        assert(season_player.fans_relationship == 92, 'Fans rel should match');
        assert(season_player.season_points == 0, 'Points should start at 0');
        assert(season_player.matches_won == 0, 'Wins should start at 0');
        assert(season_player.matches_lost == 0, 'Losses should start at 0');
        assert(season_player.trophies_won == 0, 'Trophies should start at 0');
    }

    #[test]
    #[should_panic(expected: ('SeasonPlayer ID cannot be 0',))]
    fn test_season_player_creation_invalid_id() {
        SeasonPlayerTrait::new(0, 0x456, 0x789, 0xabc, 85, 92);
    }

    #[test]
    #[should_panic(expected: ('Season ID required',))]
    fn test_season_player_creation_invalid_season_id() {
        SeasonPlayerTrait::new(0x111, 0, 0x789, 0xabc, 85, 92);
    }

    #[test]
    fn test_season_player_transfer_to_club() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);
        season_player.transfer_to_club(0x999);

        assert(season_player.season_club_id == 0x999, 'Club should be changed');
    }

    #[test]
    fn test_season_player_update_team_relationship_increase() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 50, 92);
        season_player.update_team_relationship(10);

        assert(season_player.team_relationship == 60, 'Should increase by 10');
    }

    #[test]
    fn test_season_player_update_team_relationship_decrease() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 50, 92);
        season_player.update_team_relationship(-10);

        assert(season_player.team_relationship == 40, 'Should decrease by 10');
    }

    #[test]
    fn test_season_player_update_team_relationship_cap_max() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 95, 92);
        season_player.update_team_relationship(10);

        assert(season_player.team_relationship == 100, 'Should cap at 100');
    }

    #[test]
    fn test_season_player_update_team_relationship_cap_min() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 5, 92);
        season_player.update_team_relationship(-10);

        assert(season_player.team_relationship == 0, 'Should cap at 0');
    }

    #[test]
    fn test_season_player_update_fans_relationship() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 50);
        season_player.update_fans_relationship(20);
        assert(season_player.fans_relationship == 70, 'Should increase by 20');

        season_player.update_fans_relationship(-10);
        assert(season_player.fans_relationship == 60, 'Should decrease by 10');
    }

    #[test]
    fn test_season_player_add_season_points() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);
        season_player.add_season_points(100);

        assert(season_player.season_points == 100, 'Points should be added');
    }

    #[test]
    fn test_season_player_record_match_win() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);
        season_player.record_match_win();

        assert(season_player.matches_won == 1, 'Wins should increment');
    }

    #[test]
    fn test_season_player_record_match_loss() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);
        season_player.record_match_loss();

        assert(season_player.matches_lost == 1, 'Losses should increment');
    }

    #[test]
    fn test_season_player_award_trophy() {
        let mut season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);
        season_player.award_trophy();
        season_player.award_trophy();

        assert(season_player.trophies_won == 2, 'Trophies should increment');
    }

    #[test]
    fn test_season_player_zero_values() {
        let zero_season_player = ZeroableSeasonPlayerTrait::zero();

        assert(zero_season_player.id == 0, 'Zero ID should be 0');
        assert(zero_season_player.season_id == 0, 'Zero season should be 0');
        assert(zero_season_player.is_zero(), 'Should be zero');
    }

    #[test]
    fn test_season_player_is_non_zero() {
        let season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);

        assert(season_player.is_non_zero(), 'Should be non-zero');
        assert(!season_player.is_zero(), 'Should not be zero');
    }

    #[test]
    fn test_season_player_assert_traits() {
        let season_player = SeasonPlayerTrait::new(0x111, 0x456, 0x789, 0xabc, 85, 92);
        let zero_season_player = ZeroableSeasonPlayerTrait::zero();

        season_player.assert_exists();
        zero_season_player.assert_not_exists();
    }

    #[test]
    #[should_panic(expected: ('SeasonPlayer does not exist',))]
    fn test_season_player_assert_exists_fails() {
        let zero_season_player = ZeroableSeasonPlayerTrait::zero();
        zero_season_player.assert_exists();
    }
}

