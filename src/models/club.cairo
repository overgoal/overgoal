use core::num::traits::zero::Zero;

// Club model representing a football club organization
#[derive(Drop, Serde, Debug)]
#[dojo::model]
pub struct Club {
    #[key]
    pub id: felt252,                    // Primary key - unique immutable identifier
    pub name: ByteArray,                // Club name (can be longer than 31 chars)
}

// Traits Implementations
#[generate_trait]
pub impl ClubImpl of ClubTrait {
    fn new(id: felt252, name: ByteArray) -> Club {
        // Validate inputs
        assert(id != 0, 'Club ID cannot be zero');
        assert(name.len() >= 3, 'Name must be at least 3 chars');
        assert(name.len() <= 50, 'Name must be at most 50 chars');

        Club { id, name }
    }

    fn update_name(ref self: Club, new_name: ByteArray) {
        assert(new_name.len() >= 3, 'Name must be at least 3 chars');
        assert(new_name.len() <= 50, 'Name must be at most 50 chars');
        self.name = new_name;
    }
}

// Zeroable trait for Club
pub impl ZeroableClubTrait of Zero<Club> {
    fn zero() -> Club {
        Club { id: 0, name: "" }
    }

    #[inline(always)]
    fn is_zero(self: @Club) -> bool {
        // Check non-key field to determine if club exists
        // id is a key field so it will always be set to the queried value
        self.name.len() == 0
    }

    #[inline(always)]
    fn is_non_zero(self: @Club) -> bool {
        !self.is_zero()
    }
}

// Assert trait for Club
#[generate_trait]
pub impl ClubAssert of AssertClubTrait {
    #[inline(always)]
    fn assert_exists(self: @Club) {
        assert(self.is_non_zero(), 'Club does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: @Club) {
        assert(self.is_zero(), 'Club already exists');
    }
}

// ===============================================
// Unit Tests
// ===============================================

#[cfg(test)]
mod tests {
    use super::{Club, ClubTrait, ZeroableClubTrait, AssertClubTrait};

    #[test]
    fn test_club_new_constructor() {
        let club = ClubTrait::new(0x123, "Cyber Lions FC");
        
        assert(club.id == 0x123, 'ID should match');
        assert(club.name == "Cyber Lions FC", 'Name should match');
    }

    #[test]
    #[should_panic(expected: ('Club ID cannot be zero',))]
    fn test_club_creation_invalid_id() {
        ClubTrait::new(0, "Test Club");
    }

    #[test]
    #[should_panic(expected: ('Name must be at least 3 chars',))]
    fn test_club_creation_name_too_short() {
        ClubTrait::new(0x123, "FC");
    }

    #[test]
    #[should_panic(expected: ('Name must be at most 50 chars',))]
    fn test_club_creation_name_too_long() {
        ClubTrait::new(
            0x123,
            "This is a very long club name that exceeds the maximum allowed length of fifty characters"
        );
    }

    #[test]
    fn test_club_update_name() {
        let mut club = ClubTrait::new(0x123, "Old Name FC");
        club.update_name("New Name United");
        
        assert(club.name == "New Name United", 'Name should be updated');
    }

    #[test]
    #[should_panic(expected: ('Name must be at least 3 chars',))]
    fn test_club_update_name_too_short() {
        let mut club = ClubTrait::new(0x123, "Test Club");
        club.update_name("FC");
    }

    #[test]
    fn test_club_zero_values() {
        let zero_club = ZeroableClubTrait::zero();
        
        assert(zero_club.id == 0, 'Zero ID should be 0');
        assert(zero_club.name.len() == 0, 'Zero name should be empty');
        assert(zero_club.is_zero(), 'Should be zero');
    }

    #[test]
    fn test_club_is_non_zero() {
        let club = ClubTrait::new(0x123, "Test Club");
        
        assert(club.is_non_zero(), 'Should be non-zero');
        assert(!club.is_zero(), 'Should not be zero');
    }

    #[test]
    fn test_club_assert_traits() {
        let club = ClubTrait::new(0x123, "Test Club");
        let zero_club = ZeroableClubTrait::zero();
        
        club.assert_exists();
        zero_club.assert_not_exists();
    }

    #[test]
    #[should_panic(expected: ('Club does not exist',))]
    fn test_club_assert_exists_fails() {
        let zero_club = ZeroableClubTrait::zero();
        zero_club.assert_exists();
    }

    #[test]
    #[should_panic(expected: ('Club already exists',))]
    fn test_club_assert_not_exists_fails() {
        let club = ClubTrait::new(0x123, "Test Club");
        club.assert_not_exists();
    }
}

