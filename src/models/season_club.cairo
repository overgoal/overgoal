use core::num::traits::zero::Zero;

// SeasonClub model representing a club's participation in a specific season
#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct SeasonClub {
    #[key]
    pub id: felt252,                    // Primary key - unique immutable identifier
    pub season_id: felt252,             // Foreign key to Season
    pub club_id: felt252,               // Foreign key to Club
    pub manager_id: felt252,            // Foreign key to OvergoalPlayer (manager)
    pub coach_id: felt252,              // Foreign key to OvergoalPlayer (coach)
    pub season_points: u32,             // Total points accumulated
    pub offense: u16,                   // Team offensive rating
    pub defense: u16,                   // Team defensive rating
    pub intensity: u16,                 // Team intensity/aggression
    pub chemistry: u16,                 // Team chemistry rating
    pub matches_won: u16,               // Matches won
    pub matches_lost: u16,              // Matches lost
    pub matches_drawn: u16,             // Matches drawn
}

// Traits Implementations
#[generate_trait]
pub impl SeasonClubImpl of SeasonClubTrait {
    fn new(
        id: felt252,
        season_id: felt252,
        club_id: felt252,
        manager_id: felt252,
        coach_id: felt252,
        offense: u16,
        defense: u16,
        intensity: u16,
        chemistry: u16,
    ) -> SeasonClub {
        // Validate inputs
        assert(id != 0, 'SeasonClub ID cannot be zero');
        assert(season_id != 0, 'Season ID required');
        assert(club_id != 0, 'Club ID required');
        // Note: manager_id and coach_id can be 0 initially and assigned later

        SeasonClub {
            id,
            season_id,
            club_id,
            manager_id,
            coach_id,
            season_points: 0,
            offense,
            defense,
            intensity,
            chemistry,
            matches_won: 0,
            matches_lost: 0,
            matches_drawn: 0,
        }
    }

    fn change_manager(ref self: SeasonClub, new_manager_id: felt252) {
        assert(new_manager_id != 0, 'Manager ID required');
        self.manager_id = new_manager_id;
    }

    fn change_coach(ref self: SeasonClub, new_coach_id: felt252) {
        assert(new_coach_id != 0, 'Coach ID required');
        self.coach_id = new_coach_id;
    }

    fn update_team_attributes(
        ref self: SeasonClub, offense: u16, defense: u16, intensity: u16, chemistry: u16
    ) {
        self.offense = offense;
        self.defense = defense;
        self.intensity = intensity;
        self.chemistry = chemistry;
    }

    fn record_match_win(ref self: SeasonClub, points_earned: u32) {
        self.matches_won += 1;
        self.season_points += points_earned;
    }

    fn record_match_loss(ref self: SeasonClub) {
        self.matches_lost += 1;
    }

    fn record_match_draw(ref self: SeasonClub, points_earned: u32) {
        self.matches_drawn += 1;
        self.season_points += points_earned;
    }

    fn total_matches(self: @SeasonClub) -> u16 {
        *self.matches_won + *self.matches_lost + *self.matches_drawn
    }
}

// Zeroable trait for SeasonClub
pub impl ZeroableSeasonClubTrait of Zero<SeasonClub> {
    fn zero() -> SeasonClub {
        SeasonClub {
            id: 0,
            season_id: 0,
            club_id: 0,
            manager_id: 0,
            coach_id: 0,
            season_points: 0,
            offense: 0,
            defense: 0,
            intensity: 0,
            chemistry: 0,
            matches_won: 0,
            matches_lost: 0,
            matches_drawn: 0,
        }
    }

    #[inline(always)]
    fn is_zero(self: @SeasonClub) -> bool {
        // Check non-key fields to determine if season-club exists
        *self.season_id == 0 && *self.club_id == 0 && *self.manager_id == 0
    }

    #[inline(always)]
    fn is_non_zero(self: @SeasonClub) -> bool {
        !self.is_zero()
    }
}

// Assert trait for SeasonClub
#[generate_trait]
pub impl SeasonClubAssert of AssertSeasonClubTrait {
    #[inline(always)]
    fn assert_exists(self: @SeasonClub) {
        assert(self.is_non_zero(), 'SeasonClub does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: @SeasonClub) {
        assert(self.is_zero(), 'SeasonClub already exists');
    }
}

// ===============================================
// Unit Tests
// ===============================================

#[cfg(test)]
mod tests {
    use super::{SeasonClub, SeasonClubTrait, ZeroableSeasonClubTrait, AssertSeasonClubTrait};

    #[test]
    fn test_season_club_new_constructor() {
        let season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );

        assert(season_club.id == 0x789, 'ID should match');
        assert(season_club.season_id == 0x456, 'Season ID should match');
        assert(season_club.club_id == 0x123, 'Club ID should match');
        assert(season_club.manager_id == 0xaaa, 'Manager ID should match');
        assert(season_club.coach_id == 0xbbb, 'Coach ID should match');
        assert(season_club.offense == 85, 'Offense should match');
        assert(season_club.defense == 78, 'Defense should match');
        assert(season_club.intensity == 82, 'Intensity should match');
        assert(season_club.chemistry == 90, 'Chemistry should match');
        assert(season_club.season_points == 0, 'Points should start at 0');
        assert(season_club.matches_won == 0, 'Wins should start at 0');
        assert(season_club.matches_lost == 0, 'Losses should start at 0');
        assert(season_club.matches_drawn == 0, 'Draws should start at 0');
    }

    #[test]
    #[should_panic(expected: ('SeasonClub ID cannot be zero',))]
    fn test_season_club_creation_invalid_id() {
        SeasonClubTrait::new(0, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90);
    }

    #[test]
    #[should_panic(expected: ('Season ID required',))]
    fn test_season_club_creation_invalid_season_id() {
        SeasonClubTrait::new(0x789, 0, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90);
    }

    #[test]
    #[should_panic(expected: ('Club ID required',))]
    fn test_season_club_creation_invalid_club_id() {
        SeasonClubTrait::new(0x789, 0x456, 0, 0xaaa, 0xbbb, 85, 78, 82, 90);
    }

    #[test]
    fn test_season_club_change_manager() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.change_manager(0xccc);

        assert(season_club.manager_id == 0xccc, 'Manager should be changed');
    }

    #[test]
    fn test_season_club_change_coach() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.change_coach(0xddd);

        assert(season_club.coach_id == 0xddd, 'Coach should be changed');
    }

    #[test]
    fn test_season_club_update_team_attributes() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.update_team_attributes(90, 85, 88, 95);

        assert(season_club.offense == 90, 'Offense should be updated');
        assert(season_club.defense == 85, 'Defense should be updated');
        assert(season_club.intensity == 88, 'Intensity should be updated');
        assert(season_club.chemistry == 95, 'Chemistry should be updated');
    }

    #[test]
    fn test_season_club_record_match_win() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.record_match_win(3);

        assert(season_club.matches_won == 1, 'Wins should increment');
        assert(season_club.season_points == 3, 'Points should be added');
    }

    #[test]
    fn test_season_club_record_match_loss() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.record_match_loss();

        assert(season_club.matches_lost == 1, 'Losses should increment');
        assert(season_club.season_points == 0, 'Points should not change');
    }

    #[test]
    fn test_season_club_record_match_draw() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.record_match_draw(1);

        assert(season_club.matches_drawn == 1, 'Draws should increment');
        assert(season_club.season_points == 1, 'Points should be added');
    }

    #[test]
    fn test_season_club_total_matches() {
        let mut season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        season_club.record_match_win(3);
        season_club.record_match_loss();
        season_club.record_match_draw(1);

        assert(season_club.total_matches() == 3, 'Total should be 3');
    }

    #[test]
    fn test_season_club_zero_values() {
        let zero_season_club = ZeroableSeasonClubTrait::zero();

        assert(zero_season_club.id == 0, 'Zero ID should be 0');
        assert(zero_season_club.season_id == 0, 'Zero season should be 0');
        assert(zero_season_club.club_id == 0, 'Zero club should be 0');
        assert(zero_season_club.is_zero(), 'Should be zero');
    }

    #[test]
    fn test_season_club_is_non_zero() {
        let season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );

        assert(season_club.is_non_zero(), 'Should be non-zero');
        assert(!season_club.is_zero(), 'Should not be zero');
    }

    #[test]
    fn test_season_club_assert_traits() {
        let season_club = SeasonClubTrait::new(
            0x789, 0x456, 0x123, 0xaaa, 0xbbb, 85, 78, 82, 90
        );
        let zero_season_club = ZeroableSeasonClubTrait::zero();

        season_club.assert_exists();
        zero_season_club.assert_not_exists();
    }

    #[test]
    #[should_panic(expected: ('SeasonClub does not exist',))]
    fn test_season_club_assert_exists_fails() {
        let zero_season_club = ZeroableSeasonClubTrait::zero();
        zero_season_club.assert_exists();
    }
}

