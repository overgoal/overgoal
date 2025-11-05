// Integration tests for Game Starter functionality
#[cfg(test)]
mod tests {
    // Dojo imports
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorageTrait;
    use dojo_cairo_test::{spawn_test_world, NamespaceDef, TestResource, ContractDefTrait, WorldStorageTestTrait};
    
    // System imports
    use overgoal::systems::game::{game, IGameDispatcher, IGameDispatcherTrait};
    
    // Models imports
    use overgoal::models::player::{Player, m_Player};
    use overgoal::models::user::{m_User};
    
    fn namespace_def() -> NamespaceDef {
        NamespaceDef {
            namespace: "overgoal",
            resources: [
                TestResource::Model(m_Player::TEST_CLASS_HASH),
                TestResource::Model(m_User::TEST_CLASS_HASH),
                TestResource::Contract(game::TEST_CLASS_HASH)
            ].span()
        }
    }
    
    fn contract_defs() -> Span<dojo_cairo_test::ContractDef> {
        [
            ContractDefTrait::new(@"overgoal", @"game")
                .with_writer_of([dojo::utils::bytearray_hash(@"overgoal")].span())
        ].span()
    }

    // Helper function to set up test environment
    fn setup() -> (dojo::world::WorldStorage, IGameDispatcher, starknet::ContractAddress) {
        // Initialize test environment
        let caller = starknet::contract_address_const::<0x123>();
        
        let ndef = namespace_def();
        let mut world = spawn_test_world(dojo::world::world::TEST_CLASS_HASH, array![ndef].span());
        
        // Ensures permissions and initializations are synced
        world.sync_perms_and_inits(contract_defs());
        
        // Get the game contract dispatcher
        let (contract_address, _) = world.dns(@"game").unwrap();
        let game_system = IGameDispatcher { contract_address };
        
        // Set caller address and block timestamp
        starknet::testing::set_contract_address(caller);
        starknet::testing::set_account_contract_address(caller);
        starknet::testing::set_block_timestamp(1736559000);
        
        (world, game_system, caller)
    }

    #[test]
    #[available_gas(30000000)]
    fn test_create_player() {
        // Setup test environment
        let (world, game_system, _caller) = setup();
        
        // Test creating a player with unique ID
        let player_id: felt252 = 0x123456789abcdef;
        
        // Check player doesn't exist before creation
        let player_before: Player = world.read_model(player_id);
        assert(player_before.user_id == 0, 'Player should not exist yet');
        
        game_system.create_player(player_id);
        
        // Verify player was created successfully
        let player: Player = world.read_model(player_id);
        
        // Assertions
        assert(player.id == player_id, 'Player ID mismatch');
        assert(player.user_id != 0, 'User ID should be set');
        assert(player.created_at > 0, 'Created timestamp set');
        assert(player.fame == 0, 'Fame starts at 0');
        assert(player.charisma == 0, 'Charisma starts at 0');
        assert(player.stamina == 0, 'Stamina starts at 0');
        assert(player.intelligence == 0, 'Intel starts at 0');
        assert(player.leadership == 0, 'Leadership starts at 0');
        assert(player.universe_currency == 0, 'Currency starts at 0');
    }
}