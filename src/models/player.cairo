use core::num::traits::zero::Zero;

// Player model representing a game entity in the system
#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct Player {
    #[key]
    pub id: felt252,                    // Primary key - unique immutable identifier
    pub user_id: felt252,               // Foreign key to User.owner
    pub created_at: u64,                // Unix timestamp when created (UTC)
    pub last_updated_at: u64,           // Unix timestamp of last update
    pub last_login_at: u64,             // Unix timestamp of last login
    pub fame: u16,                      // Player reputation (0-65535)
    pub charisma: u16,                  // Social influence attribute (0-65535)
    pub stamina: u16,                   // Physical endurance attribute (0-65535)
    pub intelligence: u16,              // Mental capability attribute (0-65535)
    pub leadership: u16,                // Leadership ability attribute (0-65535)
    pub universe_currency: u128,        // In-game currency balance
}

// Traits Implementations
#[generate_trait]
pub impl PlayerImpl of PlayerTrait {
    fn new(
        id: felt252,
        user_id: felt252,
        created_at: u64,
        fame: u16,
        charisma: u16,
        stamina: u16,
        intelligence: u16,
        leadership: u16,
        universe_currency: u128,
    ) -> Player {
        // Validate inputs
        assert(id != 0, 'Player ID cannot be zero');
        assert(user_id != 0, 'User ID cannot be zero');
        assert(created_at > 0, 'Created timestamp must be > 0');

        Player {
            id,
            user_id,
            created_at,
            last_updated_at: created_at,
            last_login_at: created_at,
            fame,
            charisma,
            stamina,
            intelligence,
            leadership,
            universe_currency,
        }
    }

    fn add_currency(ref self: Player, amount: u128) { 
        self.universe_currency += amount;
        self.update_timestamp();
    }

    fn spend_currency(ref self: Player, amount: u128) {
        assert(self.universe_currency >= amount, 'Insufficient currency');
        self.universe_currency -= amount;
        self.update_timestamp();
    }

    fn add_fame(ref self: Player, amount: u16) { 
        self.fame = self.fame + amount;
        self.update_timestamp();
    }

    fn add_charisma(ref self: Player, amount: u16) { 
        self.charisma = self.charisma + amount;
        self.update_timestamp();
    }

    fn add_stamina(ref self: Player, amount: u16) { 
        self.stamina = self.stamina + amount;
        self.update_timestamp();
    }

    fn add_intelligence(ref self: Player, amount: u16) { 
        self.intelligence = self.intelligence + amount;
        self.update_timestamp();
    }

    fn add_leadership(ref self: Player, amount: u16) { 
        self.leadership = self.leadership + amount;
        self.update_timestamp();
    }

    fn update_login_time(ref self: Player, timestamp: u64) {
        self.last_login_at = timestamp;
        self.update_timestamp();
    }

    fn update_timestamp(ref self: Player) {
        // This would be set to current block timestamp in actual usage
        // For now, we increment to show it was updated
        self.last_updated_at += 1;
    }
}

#[generate_trait]
pub impl PlayerAssert of PlayerAssertTrait {
    #[inline(always)]
    fn assert_exists(self: Player) {
        assert(self.is_non_zero(), 'Player: Does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: Player) {
        assert(self.is_zero(), 'Player: Already exist');
    }
}

pub impl ZeroablePlayerTrait of Zero<Player> {
    #[inline(always)]
    fn zero() -> Player {
        Player {
            id: 0,
            user_id: 0,
            created_at: 0,
            last_updated_at: 0,
            last_login_at: 0,
            fame: 0,
            charisma: 0,
            stamina: 0,
            intelligence: 0,
            leadership: 0,
            universe_currency: 0,
        }
    }

    #[inline(always)]
    fn is_zero(self: @Player) -> bool {
       *self.user_id == 0 && *self.created_at == 0
    }

    #[inline(always)]
    fn is_non_zero(self: @Player) -> bool {
        !self.is_zero()
    }
}

// Tests
#[cfg(test)]
mod tests {
    use super::{Player, ZeroablePlayerTrait, PlayerImpl, PlayerTrait, PlayerAssert};

    #[test]
    #[available_gas(1000000)]
    fn test_player_new_constructor() {
        let player = PlayerTrait::new(
            0x123,      // id
            0xabc,      // user_id
            1736559000, // created_at
            100,        // fame
            150,        // charisma
            120,        // stamina
            200,        // intelligence
            175,        // leadership
            50000,      // universe_currency
        );

        assert_eq!(player.id, 0x123, "Player ID should match");
        assert_eq!(player.user_id, 0xabc, "User ID should match");
        assert_eq!(player.created_at, 1736559000, "Created timestamp should match");
        assert_eq!(player.last_updated_at, 1736559000, "Updated timestamp should match created");
        assert_eq!(player.last_login_at, 1736559000, "Login timestamp should match created");
        assert_eq!(player.fame, 100, "Fame should match");
        assert_eq!(player.charisma, 150, "Charisma should match");
        assert_eq!(player.stamina, 120, "Stamina should match");
        assert_eq!(player.intelligence, 200, "Intelligence should match");
        assert_eq!(player.leadership, 175, "Leadership should match");
        assert_eq!(player.universe_currency, 50000, "Currency should match");
    }

    #[test]
    #[should_panic(expected: ('Player ID cannot be zero',))]
    fn test_player_creation_invalid_id() {
        PlayerTrait::new(0, 0xabc, 1736559000, 100, 150, 120, 200, 175, 50000);
    }

    #[test]
    #[should_panic(expected: ('User ID cannot be zero',))]
    fn test_player_creation_invalid_user_id() {
        PlayerTrait::new(0x123, 0, 1736559000, 100, 150, 120, 200, 175, 50000);
    }

    #[test]
    #[should_panic(expected: ('Created timestamp must be > 0',))]
    fn test_player_creation_invalid_timestamp() {
        PlayerTrait::new(0x123, 0xabc, 0, 100, 150, 120, 200, 175, 50000);
    }

    #[test]
    #[available_gas(1000000)]
    fn test_player_zero_values() {
        let player: Player = ZeroablePlayerTrait::zero();

        assert_eq!(player.id, 0, "Zero player ID should be 0");
        assert_eq!(player.user_id, 0, "Zero player user_id should be 0");
        assert_eq!(player.created_at, 0, "Zero player created_at should be 0");
        assert_eq!(player.last_updated_at, 0, "Zero player last_updated_at should be 0");
        assert_eq!(player.last_login_at, 0, "Zero player last_login_at should be 0");
        assert_eq!(player.fame, 0, "Zero player fame should be 0");
        assert_eq!(player.charisma, 0, "Zero player charisma should be 0");
        assert_eq!(player.stamina, 0, "Zero player stamina should be 0");
        assert_eq!(player.intelligence, 0, "Zero player intelligence should be 0");
        assert_eq!(player.leadership, 0, "Zero player leadership should be 0");
        assert_eq!(player.universe_currency, 0, "Zero player currency should be 0");
    }

    #[test]
    #[available_gas(1000000)]
    fn test_player_currency_operations() {
        let mut player = PlayerTrait::new(
            0x123, 0xabc, 1736559000, 100, 150, 120, 200, 175, 1000
        );

        player.add_currency(500);
        assert_eq!(player.universe_currency, 1500, "Currency should be 1500 after adding 500");

        player.spend_currency(300);
        assert_eq!(player.universe_currency, 1200, "Currency should be 1200 after spending 300");
    }

    #[test]
    #[should_panic(expected: ('Insufficient currency',))]
    fn test_player_insufficient_currency() {
        let mut player = PlayerTrait::new(
            0x123, 0xabc, 1736559000, 100, 150, 120, 200, 175, 100
        );

        player.spend_currency(200); // Should panic
    }

    #[test]
    #[available_gas(1000000)]
    fn test_player_attribute_operations() {
        let mut player = PlayerTrait::new(
            0x123, 0xabc, 1736559000, 100, 150, 120, 200, 175, 1000
        );

        player.add_fame(50);
        assert_eq!(player.fame, 150, "Fame should increase by 50");

        player.add_charisma(25);
        assert_eq!(player.charisma, 175, "Charisma should increase by 25");

        player.add_stamina(30);
        assert_eq!(player.stamina, 150, "Stamina should increase by 30");

        player.add_intelligence(20);
        assert_eq!(player.intelligence, 220, "Intelligence should increase by 20");

        player.add_leadership(15);
        assert_eq!(player.leadership, 190, "Leadership should increase by 15");
    }

    #[test]
    #[available_gas(1000000)]
    fn test_player_assert_traits() {
        // Test with existing player
        let existing_player = PlayerTrait::new(
            0x456, 0xdef, 1736559000, 100, 150, 120, 200, 175, 1000
        );

        existing_player.assert_exists(); // Should not panic

        // Test with zero player
        let zero_player: Player = ZeroablePlayerTrait::zero();
        zero_player.assert_not_exists(); // Should not panic
        
        assert!(zero_player.is_zero(), "Zero player should be zero");
        assert!(existing_player.is_non_zero(), "Existing player should be non-zero");
    }

    #[test]
    #[available_gas(1000000)]
    fn test_player_timestamp_updates() {
        let mut player = PlayerTrait::new(
            0x123, 0xabc, 1736559000, 100, 150, 120, 200, 175, 1000
        );

        let initial_updated_at = player.last_updated_at;
        
        player.add_currency(100);
        assert!(player.last_updated_at > initial_updated_at, "Timestamp should update after currency change");

        player.update_login_time(1736559500);
        assert_eq!(player.last_login_at, 1736559500, "Login time should be updated");
    }
}