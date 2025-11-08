// Interface definition for Overgoal Game System
#[starknet::interface]
pub trait IOvergoalGame<T> {
    // Method 1: Create both universe player and overgoal player together
    fn create_full_player(
        ref self: T,
        overgoal_player_id: felt252,
        universe_player_id: felt252,
        // Universe player appearance attributes
        body_type: u8,
        skin_color: u8,
        beard_type: u8,
        hair_type: u8,
        hair_color: u8,
        // Overgoal player stats
        energy: u16,
        speed: u16,
        leadership: u16,
        pass: u16,
        shoot: u16,
        freekick: u16,
        visor_type: u8,
        visor_color: u8
    );
    
    // Method 2: Create an overgoal player linked to an existing universe player
    fn create_overgoal_player(
        ref self: T,
        overgoal_player_id: felt252,
        universe_player_id: felt252,
        energy: u16,
        speed: u16,
        leadership: u16,
        pass: u16,
        shoot: u16,
        freekick: u16,
        visor_type: u8,
        visor_color: u8
    );
    
    // Update overgoal player stats
    fn update_overgoal_player_stats(
        ref self: T,
        overgoal_player_id: felt252,
        speed: u16,
        leadership: u16,
        pass: u16,
        shoot: u16,
        freekick: u16
    );
    
    // Add currency to overgoal player
    fn add_goal_currency(ref self: T, overgoal_player_id: felt252, amount: u128);
    
    // Spend currency from overgoal player
    fn spend_goal_currency(ref self: T, overgoal_player_id: felt252, amount: u128);
    
    // Set injury status
    fn set_injury_status(ref self: T, overgoal_player_id: felt252, is_injured: bool);
}

// Interface for Universe contract (for safe cross-contract calls)
#[starknet::interface]
pub trait IUniverse<T> {
    fn create_player(
        ref self: T, 
        player_id: felt252,
        user_id: felt252,
        body_type: u8,
        skin_color: u8,
        beard_type: u8,
        hair_type: u8,
        hair_color: u8
    );
}

#[dojo::contract]
pub mod overgoal_game {
    use super::{IOvergoalGame};
    use super::{IUniverseSafeDispatcher, IUniverseSafeDispatcherTrait};
    
    // Store import
    use overgoal::store::{StoreTrait};
    
    // Models import
    use overgoal::models::overgoal_player::{OvergoalPlayerAssert};
    
    // Dojo Imports
    #[allow(unused_imports)]
    use dojo::model::{ModelStorage};
    #[allow(unused_imports)]
    use dojo::world::{WorldStorage, WorldStorageTrait};
    
    // Starknet imports
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    
    #[storage]
    struct Storage {
        universe_contract_address: starknet::ContractAddress,
    }
    
    // Events removed for simplicity - can be added later if needed
    
    // Constructor
    fn dojo_init(ref self: ContractState, universe_address: starknet::ContractAddress) {
        self.universe_contract_address.write(universe_address);
    }
    
    // Implementation of the interface methods
    #[abi(embed_v0)]
    impl OvergoalGameImpl of IOvergoalGame<ContractState> {
        
        // Method 1: Create both universe player and overgoal player
        #[feature("safe_dispatcher")]
        fn create_full_player(
            ref self: ContractState,
            overgoal_player_id: felt252,
            universe_player_id: felt252,
            // Universe player appearance attributes
            body_type: u8,
            skin_color: u8,
            beard_type: u8,
            hair_type: u8,
            hair_color: u8,
            // Overgoal player stats
            energy: u16,
            speed: u16,
            leadership: u16,
            pass: u16,
            shoot: u16,
            freekick: u16,
            visor_type: u8,
            visor_color: u8
        ) {
            let universe_address = self.universe_contract_address.read();
            
            // Use Safe Dispatcher to create universe player
            let universe_dispatcher = IUniverseSafeDispatcher { 
                contract_address: universe_address 
            };
            
            // Try to create player in Universe contract
            // Use universe_player_id as user_id as well (they're the same for now)
            let result = universe_dispatcher.create_player(
                universe_player_id,
                universe_player_id, // user_id
                body_type,
                skin_color,
                beard_type,
                hair_type,
                hair_color
            );
            
            // Handle result - panic if universe player creation failed
            match result {
                Result::Ok(_) => {
                    // Universe player created successfully, now create overgoal player
                    let mut world = self.world(@"overgoal");
                    let store = StoreTrait::new(world);
                    
                    store.create_overgoal_player(
                        overgoal_player_id,
                        universe_player_id,
                        energy,
                        speed,
                        leadership,
                        pass,
                        shoot,
                        freekick,
                        visor_type,
                        visor_color
                    );
                },
                Result::Err(_panic_data) => {
                    // Universe player creation failed
                    panic!("Failed to create universe player");
                },
            }
        }
        
        // Method 2: Create overgoal player with existing universe player ID
        fn create_overgoal_player(
            ref self: ContractState,
            overgoal_player_id: felt252,
            universe_player_id: felt252,
            energy: u16,
            speed: u16,
            leadership: u16,
            pass: u16,
            shoot: u16,
            freekick: u16,
            visor_type: u8,
            visor_color: u8
        ) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            // Create overgoal player
            store.create_overgoal_player(
                overgoal_player_id,
                universe_player_id,
                energy,
                speed,
                leadership,
                pass,
                shoot,
                freekick,
                visor_type,
                visor_color
            );
        }
        
        fn update_overgoal_player_stats(
            ref self: ContractState,
            overgoal_player_id: felt252,
            speed: u16,
            leadership: u16,
            pass: u16,
            shoot: u16,
            freekick: u16
        ) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            store.update_overgoal_player_stats(
                overgoal_player_id,
                speed,
                leadership,
                pass,
                shoot,
                freekick
            );
        }
        
        fn add_goal_currency(ref self: ContractState, overgoal_player_id: felt252, amount: u128) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            store.add_overgoal_player_currency(overgoal_player_id, amount);
        }
        
        fn spend_goal_currency(ref self: ContractState, overgoal_player_id: felt252, amount: u128) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            store.spend_overgoal_player_currency(overgoal_player_id, amount);
        }
        
        fn set_injury_status(ref self: ContractState, overgoal_player_id: felt252, is_injured: bool) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            store.set_overgoal_player_injury(overgoal_player_id, is_injured);
        }
    }
    
}

