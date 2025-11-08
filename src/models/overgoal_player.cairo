use core::num::traits::zero::Zero;

// OvergoalPlayer model representing a football player in the Overgoal game
// This model is linked to a universe player via universe_player_id
#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct OvergoalPlayer {
    #[key]
    pub id: felt252,                        // Primary key - unique immutable identifier
    pub universe_player_id: felt252,       // Foreign key to Universe Player
    pub goal_currency: u128,                // In-game currency for Overgoal
    pub energy: u16,                        // Energy level (0-65535)
    pub speed: u16,                         // Speed attribute (0-65535)
    pub leadership: u16,                    // Leadership ability (0-65535)
    pub pass: u16,                          // Passing skill (0-65535)
    pub shoot: u16,                         // Shooting skill (0-65535)
    pub freekick: u16,                      // Free kick skill (0-65535)
    pub is_injured: bool,                   // Injury status
    pub visor_type: u8,                     // Visor type (can be 0 for none)
    pub visor_color: u8,                    // Visor color (can be 0 for none)
}

// Traits Implementations
#[generate_trait]
pub impl OvergoalPlayerImpl of OvergoalPlayerTrait {
    fn new(
        id: felt252,
        universe_player_id: felt252,
        energy: u16,
        speed: u16,
        leadership: u16,
        pass: u16,
        shoot: u16,
        freekick: u16,
        visor_type: u8,
        visor_color: u8,
    ) -> OvergoalPlayer {
        // Validate inputs
        assert(id != 0, 'Player ID cannot be zero');
        assert(universe_player_id != 0, 'Universe player ID required');

        OvergoalPlayer {
            id,
            universe_player_id,
            goal_currency: 0,           // Start with 0 currency
            energy,
            speed,
            leadership,
            pass,
            shoot,
            freekick,
            is_injured: false,          // Start not injured
            visor_type,
            visor_color,
        }
    }

    fn add_currency(ref self: OvergoalPlayer, amount: u128) { 
        self.goal_currency += amount;
    }

    fn spend_currency(ref self: OvergoalPlayer, amount: u128) {
        assert(self.goal_currency >= amount, 'Insufficient currency');
        self.goal_currency -= amount;
    }

    fn add_energy(ref self: OvergoalPlayer, amount: u16) { 
        self.energy = self.energy + amount;
    }

    fn reduce_energy(ref self: OvergoalPlayer, amount: u16) {
        assert(self.energy >= amount, 'Insufficient energy');
        self.energy = self.energy - amount;
    }

    fn set_injured(ref self: OvergoalPlayer, injured: bool) {
        self.is_injured = injured;
    }

    fn update_visor(ref self: OvergoalPlayer, visor_type: u8, visor_color: u8) {
        self.visor_type = visor_type;
        self.visor_color = visor_color;
    }
}

#[generate_trait]
pub impl OvergoalPlayerAssert of OvergoalPlayerAssertTrait {
    #[inline(always)]
    fn assert_exists(self: OvergoalPlayer) {
        assert(self.is_non_zero(), 'OvergoalPlayer: Does not exist');
    }

    #[inline(always)]
    fn assert_not_exists(self: OvergoalPlayer) {
        assert(self.is_zero(), 'OvergoalPlayer: Already exist');
    }

    #[inline(always)]
    fn assert_not_injured(self: OvergoalPlayer) {
        assert(!self.is_injured, 'Player is injured');
    }

    #[inline(always)]
    fn assert_has_energy(self: OvergoalPlayer, required: u16) {
        assert(self.energy >= required, 'Insufficient energy');
    }
}

pub impl ZeroableOvergoalPlayerTrait of Zero<OvergoalPlayer> {
    #[inline(always)]
    fn zero() -> OvergoalPlayer {
        OvergoalPlayer {
            id: 0,
            universe_player_id: 0,
            goal_currency: 0,
            energy: 0,
            speed: 0,
            leadership: 0,
            pass: 0,
            shoot: 0,
            freekick: 0,
            is_injured: false,
            visor_type: 0,
            visor_color: 0,
        }
    }

    #[inline(always)]
    fn is_zero(self: @OvergoalPlayer) -> bool {
       // Check non-key fields to determine if player exists
       // id is a key field so it will always be set to the queried value
       *self.universe_player_id == 0 && *self.goal_currency == 0 && *self.energy == 0
    }

    #[inline(always)]
    fn is_non_zero(self: @OvergoalPlayer) -> bool {
        !self.is_zero()
    }
}

// Tests
#[cfg(test)]
mod tests {
    use super::{OvergoalPlayer, ZeroableOvergoalPlayerTrait, OvergoalPlayerImpl, OvergoalPlayerTrait, OvergoalPlayerAssert};

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_new_constructor() {
        let player = OvergoalPlayerTrait::new(
            0x123,      // id
            0xabc,      // universe_player_id
            100,        // energy
            80,         // speed
            70,         // leadership
            85,         // pass
            90,         // shoot
            75,         // freekick
            1,          // visor_type
            2,          // visor_color
        );

        assert_eq!(player.id, 0x123, "Player ID should match");
        assert_eq!(player.universe_player_id, 0xabc, "Universe player ID should match");
        assert_eq!(player.goal_currency, 0, "Currency should start at 0");
        assert_eq!(player.energy, 100, "Energy should match");
        assert_eq!(player.speed, 80, "Speed should match");
        assert_eq!(player.leadership, 70, "Leadership should match");
        assert_eq!(player.pass, 85, "Pass should match");
        assert_eq!(player.shoot, 90, "Shoot should match");
        assert_eq!(player.freekick, 75, "Freekick should match");
        assert!(!player.is_injured, "Should not be injured");
        assert_eq!(player.visor_type, 1, "Visor type should match");
        assert_eq!(player.visor_color, 2, "Visor color should match");
    }

    #[test]
    #[should_panic(expected: ('Player ID cannot be zero',))]
    fn test_overgoal_player_creation_invalid_id() {
        OvergoalPlayerTrait::new(0, 0xabc, 100, 80, 70, 85, 90, 75, 1, 2);
    }

    #[test]
    #[should_panic(expected: ('Universe player ID required',))]
    fn test_overgoal_player_creation_invalid_universe_id() {
        OvergoalPlayerTrait::new(0x123, 0, 100, 80, 70, 85, 90, 75, 1, 2);
    }

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_zero_values() {
        let player: OvergoalPlayer = ZeroableOvergoalPlayerTrait::zero();

        assert_eq!(player.id, 0, "Zero player ID should be 0");
        assert_eq!(player.universe_player_id, 0, "Zero universe_player_id should be 0");
        assert_eq!(player.goal_currency, 0, "Zero currency should be 0");
        assert_eq!(player.energy, 0, "Zero energy should be 0");
        assert_eq!(player.speed, 0, "Zero speed should be 0");
        assert_eq!(player.leadership, 0, "Zero leadership should be 0");
        assert_eq!(player.pass, 0, "Zero pass should be 0");
        assert_eq!(player.shoot, 0, "Zero shoot should be 0");
        assert_eq!(player.freekick, 0, "Zero freekick should be 0");
        assert!(!player.is_injured, "Zero player should not be injured");
        assert_eq!(player.visor_type, 0, "Zero visor_type should be 0");
        assert_eq!(player.visor_color, 0, "Zero visor_color should be 0");
    }

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_currency_operations() {
        let mut player = OvergoalPlayerTrait::new(
            0x123, 0xabc, 100, 80, 70, 85, 90, 75, 1, 2
        );

        player.add_currency(500);
        assert_eq!(player.goal_currency, 500, "Currency should be 500");

        player.spend_currency(300);
        assert_eq!(player.goal_currency, 200, "Currency should be 200");
    }

    #[test]
    #[should_panic(expected: ('Insufficient currency',))]
    fn test_overgoal_player_insufficient_currency() {
        let mut player = OvergoalPlayerTrait::new(
            0x123, 0xabc, 100, 80, 70, 85, 90, 75, 1, 2
        );

        player.add_currency(100);
        player.spend_currency(200); // Should panic
    }

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_energy_operations() {
        let mut player = OvergoalPlayerTrait::new(
            0x123, 0xabc, 100, 80, 70, 85, 90, 75, 1, 2
        );

        player.add_energy(50);
        assert_eq!(player.energy, 150, "Energy should be 150");

        player.reduce_energy(30);
        assert_eq!(player.energy, 120, "Energy should be 120");
    }

    #[test]
    #[should_panic(expected: ('Insufficient energy',))]
    fn test_overgoal_player_insufficient_energy() {
        let mut player = OvergoalPlayerTrait::new(
            0x123, 0xabc, 50, 80, 70, 85, 90, 75, 1, 2
        );

        player.reduce_energy(100); // Should panic
    }

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_injury_status() {
        let mut player = OvergoalPlayerTrait::new(
            0x123, 0xabc, 100, 80, 70, 85, 90, 75, 1, 2
        );

        assert!(!player.is_injured, "Should not be injured initially");

        player.set_injured(true);
        assert!(player.is_injured, "Should be injured");

        player.set_injured(false);
        assert!(!player.is_injured, "Should not be injured");
    }

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_visor_update() {
        let mut player = OvergoalPlayerTrait::new(
            0x123, 0xabc, 100, 80, 70, 85, 90, 75, 1, 2
        );

        player.update_visor(3, 4);
        assert_eq!(player.visor_type, 3, "Visor type should be updated");
        assert_eq!(player.visor_color, 4, "Visor color should be updated");
    }

    #[test]
    #[available_gas(1000000)]
    fn test_overgoal_player_assert_traits() {
        let existing_player = OvergoalPlayerTrait::new(
            0x456, 0xdef, 100, 80, 70, 85, 90, 75, 1, 2
        );

        existing_player.assert_exists(); // Should not panic
        existing_player.assert_not_injured(); // Should not panic
        existing_player.assert_has_energy(50); // Should not panic

        let zero_player: OvergoalPlayer = ZeroableOvergoalPlayerTrait::zero();
        zero_player.assert_not_exists(); // Should not panic
        
        assert!(zero_player.is_zero(), "Zero player should be zero");
        assert!(existing_player.is_non_zero(), "Existing player should be non-zero");
    }
}

