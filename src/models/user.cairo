

// Starknet import
use starknet::ContractAddress;
use core::num::traits::zero::Zero;

// Constants imports
use overgoal::constants;

// User model representing a player account in the game
#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct User {
    #[key]
    pub owner: ContractAddress, // Primary key - contract address of the user
    pub username: felt252,      // Display username (≤31 chars, case-insensitive)
    pub created_at: u64,        // Unix epoch timestamp when user was created
}

// User trait for model operations and validation
#[generate_trait]
pub impl UserImpl of UserTrait {
    /// Create a new User with validation
    fn new(owner: ContractAddress, username: felt252, created_at: u64) -> User {
        // Validate inputs
        assert(!owner.is_zero(), 'User owner cannot be zero');
        assert(username != 0, 'Username cannot be empty');
        assert(created_at > 0, 'Created timestamp must be > 0');

        User {
            owner,
            username,
            created_at,
        }
    }

    /// Check if user is valid
    fn is_valid(self: @User) -> bool {
        self.is_non_zero() && *self.username != 0 && *self.created_at > 0
    }

    /// Get user display info as formatted string (for debugging)
    fn display_info(self: @User) -> (ContractAddress, felt252, u64) {
        (*self.owner, *self.username, *self.created_at)
    }
}

#[generate_trait]
pub impl UserAssert of UserAssertTrait {
    #[inline(always)]
    fn assert_exists(self: User) {
        assert(self.is_non_zero(), 'User: Does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: User) {
        assert(self.is_zero(), 'User: Already exist');
    }
}

pub impl ZeroableUserTrait of Zero<User> {
    #[inline(always)]
    fn zero() -> User {
        User {
            owner: constants::ZERO_ADDRESS(),
            username: 0,
            created_at: 0,
        }
    }

    #[inline(always)]
    fn is_zero(self: @User) -> bool {
       *self.owner == constants::ZERO_ADDRESS()
    }

    #[inline(always)]
    fn is_non_zero(self: @User) -> bool {
        !self.is_zero()
    }
}

// Helper functions for user operations
#[generate_trait]
pub impl UserHelpers of UserHelpersTrait {
    /// Check if two users are the same
    fn is_same_user(user1: @User, user2: @User) -> bool {
        *user1.owner == *user2.owner
    }

    /// Check if user was created after a certain timestamp
    fn created_after(self: @User, timestamp: u64) -> bool {
        *self.created_at > timestamp
    }

    /// Check if user was created before a certain timestamp
    fn created_before(self: @User, timestamp: u64) -> bool {
        *self.created_at < timestamp
    }
}

// Tests
#[cfg(test)]
mod tests {
    use super::{User, ZeroableUserTrait, UserImpl, UserTrait, UserAssert, UserHelpers, UserHelpersTrait};
    use overgoal::constants;
    use starknet::{ContractAddress, contract_address_const};

    #[test]
    fn test_user_creation() {
        let user_address = contract_address_const::<0x123>();
        let user = UserTrait::new(user_address, 'matias', 1736559000);
        
        assert(user.owner == user_address, 'Wrong user owner');
        assert(user.username == 'matias', 'Wrong username');
        assert(user.created_at == 1736559000, 'Wrong timestamp');
        assert(user.is_valid(), 'User should be valid');
    }

    #[test]
    #[should_panic(expected: ('User owner cannot be zero',))]
    fn test_user_creation_invalid_owner() {
        let zero_address = contract_address_const::<0x0>();
        UserTrait::new(zero_address, 'matias', 1736559000);
    }

    #[test]
    #[should_panic(expected: ('Username cannot be empty',))]
    fn test_user_creation_invalid_username() {
        let user_address = contract_address_const::<0x123>();
        UserTrait::new(user_address, 0, 1736559000);
    }

    #[test]
    #[should_panic(expected: ('Created timestamp must be > 0',))]
    fn test_user_creation_invalid_timestamp() {
        let user_address = contract_address_const::<0x123>();
        UserTrait::new(user_address, 'matias', 0);
    }

    #[test]
    #[available_gas(1000000)]
    fn test_user_zero_values() {
        let user: User = ZeroableUserTrait::zero();

        assert_eq!(
            user.owner, 
            constants::ZERO_ADDRESS(), 
            "User owner should match the zero address"
        );
        assert_eq!(
            user.username, 
            0, 
            "Zero user username should be 0"
        );
        assert_eq!(
            user.created_at, 
            0, 
            "Zero user created_at should be 0"
        );
    }

    #[test]
    #[available_gas(1000000)]
    fn test_user_assert_traits() {
        let mock_address: ContractAddress = contract_address_const::<0x456>();
        
        // Test with existing user
        let existing_user = UserTrait::new(
            mock_address,
            'matias',
            1736559000,
        );

        existing_user.assert_exists(); // Should not panic

        // Test with zero user
        let zero_user: User = ZeroableUserTrait::zero();
        zero_user.assert_not_exists(); // Should not panic
        
        assert!(zero_user.is_zero(), "Zero user should be zero");
        assert!(existing_user.is_non_zero(), "Existing user should be non-zero");
    }

    #[test]
    fn test_user_helpers() {
        let user_address_1 = contract_address_const::<0x123>();
        let user_address_2 = contract_address_const::<0x456>();
        
        let user1 = UserTrait::new(user_address_1, 'matias', 1736559000);
        let user2 = UserTrait::new(user_address_1, 'maria', 1736559100);
        let user3 = UserTrait::new(user_address_2, 'john', 1736559200);

        assert(UserHelpers::is_same_user(@user1, @user2), 'Same owner same user');
        assert(!UserHelpers::is_same_user(@user1, @user3), 'Diff owner diff user');
        
        assert(user2.created_after(1736559000), 'User2 created after user1');
        assert(user1.created_before(1736559100), 'User1 created before user2');
    }
}