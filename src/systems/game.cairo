// Interface definition
#[starknet::interface]
pub trait IGame<T> {
    // --------- Core gameplay methods ---------
    fn create_player(ref self: T, player_id: felt252);
    fn update_attributes(ref self: T, player_id: felt252, fame: u16, charisma: u16, stamina: u16, intelligence: u16, leadership: u16);
    fn add_currency(ref self: T, player_id: felt252, amount: u128);
    fn spend_currency(ref self: T, player_id: felt252, amount: u128);
    fn record_login(ref self: T, player_id: felt252);
}

#[dojo::contract]
pub mod game {
    // Local import
    use super::{IGame};



    // Store import
    use overgoal::store::{StoreTrait};



    // Models import
    use overgoal::models::player::{PlayerAssert};
    use overgoal::models::user::{UserAssert};



    // Dojo Imports
    #[allow(unused_imports)]
    use dojo::model::{ModelStorage};
    #[allow(unused_imports)]
    use dojo::world::{WorldStorage, WorldStorageTrait};
    #[allow(unused_imports)]
    use dojo::event::EventStorage;



    #[storage]
    struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    // Constructor
    fn dojo_init(ref self: ContractState) {}

    // Implementation of the interface methods
    #[abi(embed_v0)]
    impl GameImpl of IGame<ContractState> {
        
        // Method to create a new player
        fn create_player(ref self: ContractState, player_id: felt252) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);

            // Get caller as user_id (assuming caller has a User account)
            let caller = starknet::get_caller_address();
            let user_id: felt252 = caller.into();

            // Create new player
            store.create_player(player_id, user_id);
        }

        // Method to update player attributes
        fn update_attributes(ref self: ContractState, player_id: felt252, fame: u16, charisma: u16, stamina: u16, intelligence: u16, leadership: u16) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);

            // Update player attributes
            store.update_player_attributes(player_id, fame, charisma, stamina, intelligence, leadership);
        }

        // Method to add currency to player
        fn add_currency(ref self: ContractState, player_id: felt252, amount: u128) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
           
            // Add currency
            store.add_player_currency(player_id, amount);
        }

        // Method to spend player currency
        fn spend_currency(ref self: ContractState, player_id: felt252, amount: u128) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);

            // Spend currency
            store.spend_player_currency(player_id, amount);
        }

        // Method to record player login
        fn record_login(ref self: ContractState, player_id: felt252) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);

            // Record login
            store.record_player_login(player_id);
        }

    }
}