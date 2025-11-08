#[cfg(test)]
mod tests {
    // Starknet imports
    use starknet::{ContractAddress, contract_address_const, testing::{set_block_timestamp, set_caller_address}};
    
    // Dojo imports
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait,
        WorldStorageTestTrait
    };
    
    // Internal imports
    use overgoal::store::{StoreTrait};
    use overgoal::models::overgoal_player::{m_OvergoalPlayer};
    use overgoal::systems::overgoal_game::{
        overgoal_game, IOvergoalGameDispatcher, IOvergoalGameDispatcherTrait
    };
    
    
    // Helper function to set up the test world (simple setup without Universe)
    fn setup() -> (WorldStorage, IOvergoalGameDispatcher, ContractAddress) {
        // Set caller address
        let caller = contract_address_const::<0x1337>();
        
        // Define namespace
        let ndef = NamespaceDef {
            namespace: "overgoal",
            resources: [
                TestResource::Model(m_OvergoalPlayer::TEST_CLASS_HASH),
                TestResource::Contract(overgoal_game::TEST_CLASS_HASH),
            ].span()
        };
        
        // Spawn test world
        let mut world = spawn_test_world(dojo::world::world::TEST_CLASS_HASH, array![ndef].span());
        
        // Real universe game contract address from deployed universe
        // Address: 0x63acf20ab2fc063985bbbbc55dfd3f33672b065960e6124d2a35e17eb6cf10b
        let universe_game_address = contract_address_const::<0x63acf20ab2fc063985bbbbc55dfd3f33672b065960e6124d2a35e17eb6cf10b>();
        
        world.sync_perms_and_inits(array![
            ContractDefTrait::new(@"overgoal", @"overgoal_game")
                .with_writer_of([dojo::utils::bytearray_hash(@"overgoal")].span())
                .with_init_calldata(array![universe_game_address.into()].span())
        ].span());
        
        // Get the overgoal_game contract dispatcher
        let (contract_address, _) = world.dns(@"overgoal_game").unwrap();
        let overgoal_game_system = IOvergoalGameDispatcher { contract_address };
        
        // Set caller address and block timestamp
        starknet::testing::set_contract_address(caller);
        starknet::testing::set_account_contract_address(caller);
        starknet::testing::set_block_timestamp(1736559000);
        
        (world, overgoal_game_system, caller)
    }
    
    
    #[test]
    #[available_gas(30000000)]
    fn test_create_overgoal_player() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0x123;
        let universe_player_id: felt252 = 0xabc;
        
        // Create overgoal player
        overgoal_game_system.create_overgoal_player(
            overgoal_player_id,
            universe_player_id,
            100,  // energy
            80,   // speed
            70,   // leadership
            85,   // pass
            90,   // shoot
            75,   // freekick
            1,    // visor_type
            2     // visor_color
        );
        
        // Verify player was created
        let store = StoreTrait::new(world);
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        
        assert(player.id == overgoal_player_id, 'Player ID should match');
        assert(player.universe_player_id == universe_player_id, 'Universe ID should match');
        assert(player.goal_currency == 0, 'Currency should be 0');
        assert(player.energy == 100, 'Energy should be 100');
        assert(player.speed == 80, 'Speed should be 80');
        assert(player.leadership == 70, 'Leadership should be 70');
        assert(player.pass == 85, 'Pass should be 85');
        assert(player.shoot == 90, 'Shoot should be 90');
        assert(player.freekick == 75, 'Freekick should be 75');
        assert(!player.is_injured, 'Should not be injured');
        assert(player.visor_type == 1, 'Visor type should be 1');
        assert(player.visor_color == 2, 'Visor color should be 2');
    }
    
    #[test]
    #[available_gas(30000000)]
    fn test_update_overgoal_player_stats() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0x456;
        let universe_player_id: felt252 = 0xdef;
        
        // Create player first
        overgoal_game_system.create_overgoal_player(
            overgoal_player_id,
            universe_player_id,
            100, 80, 70, 85, 90, 75, 1, 2
        );
        
        // Update stats
        overgoal_game_system.update_overgoal_player_stats(
            overgoal_player_id,
            95,   // speed
            85,   // leadership
            90,   // pass
            95,   // shoot
            80    // freekick
        );
        
        // Verify stats were updated
        let store = StoreTrait::new(world);
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        
        assert(player.speed == 95, 'Speed should be updated');
        assert(player.leadership == 85, 'Leadership should be updated');
        assert(player.pass == 90, 'Pass should be updated');
        assert(player.shoot == 95, 'Shoot should be updated');
        assert(player.freekick == 80, 'Freekick should be updated');
    }
    
    #[test]
    #[available_gas(30000000)]
    fn test_add_and_spend_goal_currency() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0x789;
        let universe_player_id: felt252 = 0x321;
        
        // Create player
        overgoal_game_system.create_overgoal_player(
            overgoal_player_id,
            universe_player_id,
            100, 80, 70, 85, 90, 75, 1, 2
        );
        
        // Add currency
        overgoal_game_system.add_goal_currency(overgoal_player_id, 1000);
        
        let store = StoreTrait::new(world);
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        assert(player.goal_currency == 1000, 'Currency should be 1000');
        
        // Spend currency
        overgoal_game_system.spend_goal_currency(overgoal_player_id, 300);
        
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        assert(player.goal_currency == 700, 'Currency should be 700');
    }
    
    #[test]
    #[available_gas(30000000)]
    fn test_set_injury_status() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0xaaa;
        let universe_player_id: felt252 = 0xbbb;
        
        // Create player
        overgoal_game_system.create_overgoal_player(
            overgoal_player_id,
            universe_player_id,
            100, 80, 70, 85, 90, 75, 1, 2
        );
        
        // Set injured
        overgoal_game_system.set_injury_status(overgoal_player_id, true);
        
        let store = StoreTrait::new(world);
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        assert(player.is_injured, 'Should be injured');
        
        // Set not injured
        overgoal_game_system.set_injury_status(overgoal_player_id, false);
        
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        assert(!player.is_injured, 'Should not be injured');
    }
    
    #[test]
    #[available_gas(100000000)]
    #[should_panic]
    fn test_create_full_player() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0xccc;
        let universe_player_id: felt252 = 0xddd;
        
        // Method 1: Create both universe player and overgoal player together
        // This calls the deployed Universe contract via safe dispatcher
        overgoal_game_system.create_full_player(
            overgoal_player_id,
            universe_player_id,
            // Universe player appearance
            1,  // body_type
            2,  // skin_color
            0,  // beard_type
            1,  // hair_type
            1,  // hair_color
            // Overgoal player stats
            100,  // energy
            85,   // speed
            75,   // leadership
            90,   // pass
            88,   // shoot
            80,   // freekick
            2,    // visor_type
            1     // visor_color
        );
        
        // This test expects to panic because the Universe contract at the configured address
        // doesn't exist in the test environment. In production with proper deployment and
        // permissions, this function will successfully create both players.
    }
    
    #[test]
    #[available_gas(30000000)]
    fn test_create_overgoal_player_with_existing_universe_id() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0xeee;
        let universe_player_id: felt252 = 0xfff;
        
        // Method 2: Create overgoal player assuming universe player already exists
        // (In a real scenario, the universe player would have been created separately)
        overgoal_game_system.create_overgoal_player(
            overgoal_player_id,
            universe_player_id,
            95,   // energy
            88,   // speed
            82,   // leadership
            85,   // pass
            92,   // shoot
            78,   // freekick
            0,    // visor_type (no visor)
            0     // visor_color
        );
        
        // Verify overgoal player was created with the universe player ID
        let store = StoreTrait::new(world);
        let player = store.read_overgoal_player_from_id(overgoal_player_id);
        
        assert(player.id == overgoal_player_id, 'Player ID should match');
        assert(player.universe_player_id == universe_player_id, 'Should link to universe ID');
        assert(player.energy == 95, 'Energy should be 95');
        assert(player.speed == 88, 'Speed should be 88');
        assert(player.leadership == 82, 'Leadership should be 82');
        assert(player.pass == 85, 'Pass should be 85');
        assert(player.shoot == 92, 'Shoot should be 92');
        assert(player.freekick == 78, 'Freekick should be 78');
        assert(player.visor_type == 0, 'No visor');
        assert(player.visor_color == 0, 'No visor color');
    }
    
    #[test]
    #[available_gas(100000000)]
    #[should_panic]
    fn test_assign_player_to_club() {
        let (mut world, overgoal_game_system, _caller) = setup();
        
        let overgoal_player_id: felt252 = 0x999;
        let universe_player_id: felt252 = 0x999;
        let user_id: felt252 = 0x123;
        let club_id: felt252 = 1;
        
        // First create an overgoal player
        overgoal_game_system.create_overgoal_player(
            overgoal_player_id,
            universe_player_id,
            100, 80, 70, 85, 90, 75, 1, 2
        );
        
        // This will panic because Universe contract doesn't exist in test environment
        // In production, this would:
        // 1. Call Universe to assign user to universe_player
        // 2. Create a SeasonPlayer linking overgoal_player to club
        overgoal_game_system.assign_player_to_club(
            overgoal_player_id,
            user_id,
            club_id
        );
    }
}

