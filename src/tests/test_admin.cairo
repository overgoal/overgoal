#[cfg(test)]
mod tests {
    // Starknet imports
    use starknet::{ContractAddress, contract_address_const, testing::{set_block_timestamp, set_caller_address}};
    
    // Dojo imports
    use dojo::world::{WorldStorage, WorldStorageTrait};
    use dojo::model::ModelStorage;
    use dojo_cairo_test::{
        spawn_test_world, NamespaceDef, TestResource, ContractDefTrait,
        WorldStorageTestTrait
    };
    
    // Internal imports
    use overgoal::store::{StoreTrait};
    use overgoal::models::club::{m_Club, Club};
    use overgoal::models::season::{m_Season, Season};
    use overgoal::models::season_club::{m_SeasonClub, SeasonClub};
    use overgoal::systems::admin::{admin, IAdminDispatcher, IAdminDispatcherTrait};

    // Helper function to set up the test world
    fn setup() -> (WorldStorage, IAdminDispatcher, ContractAddress) {
        // Set caller address
        let caller = contract_address_const::<0x1337>();
        
        // Define namespace
        let ndef = NamespaceDef {
            namespace: "overgoal",
            resources: [
                TestResource::Model(m_Club::TEST_CLASS_HASH),
                TestResource::Model(m_Season::TEST_CLASS_HASH),
                TestResource::Model(m_SeasonClub::TEST_CLASS_HASH),
                TestResource::Contract(admin::TEST_CLASS_HASH),
            ].span()
        };
        
        // Spawn test world
        let mut world = spawn_test_world(dojo::world::world::TEST_CLASS_HASH, array![ndef].span());
        
        // Dummy Universe contract address for testing (admin won't actually call it in these tests)
        let dummy_universe_address = contract_address_const::<0x999>();
        
        world.sync_perms_and_inits(array![
            ContractDefTrait::new(@"overgoal", @"admin")
                .with_writer_of([dojo::utils::bytearray_hash(@"overgoal")].span())
                .with_init_calldata(array![dummy_universe_address.into()].span())
        ].span());
        
        // Get the admin contract dispatcher
        let (contract_address, _) = world.dns(@"admin").unwrap();
        let admin_system = IAdminDispatcher { contract_address };
        
        // Set caller address and block timestamp
        starknet::testing::set_contract_address(caller);
        starknet::testing::set_account_contract_address(caller);
        starknet::testing::set_block_timestamp(1736559000);
        
        (world, admin_system, caller)
    }

    #[test]
    #[available_gas(100000000)]
    fn test_seed_season_1() {
        let (mut world, admin_system, _caller) = setup();
        
        // Seed Season 1
        admin_system.seed_season_1();
        
        // Verify Season was created
        let store = StoreTrait::new(world);
        let season = store.read_season(1);
        
        assert(season.id == 1, 'Season ID should be 1');
        assert(season.name == "Season 0: Where everything starts", 'Season name mismatch');
        assert(season.start_date == 1700352000, 'Start date mismatch');
        assert(season.end_date == 1701993599, 'End date mismatch');
        assert(season.prize_pool == 0, 'Prize pool should be 0');
        
        // Verify Clubs were created
        let club_1 = store.read_club(1);
        assert(club_1.id == 1, 'Club 1 ID should be 1');
        assert(club_1.name == "Cartridge Athletic", 'Club 1 name mismatch');
        
        let club_2 = store.read_club(2);
        assert(club_2.id == 2, 'Club 2 ID should be 2');
        assert(club_2.name == "Dojo United", 'Club 2 name mismatch');
        
        let club_3 = store.read_club(3);
        assert(club_3.id == 3, 'Club 3 ID should be 3');
        assert(club_3.name == "Nova United", 'Club 3 name mismatch');
        
        let club_4 = store.read_club(4);
        assert(club_4.id == 4, 'Club 4 ID should be 4');
        assert(club_4.name == "Drakon Core", 'Club 4 name mismatch');
        
        // Verify SeasonClubs were created
        let season_club_1 = store.read_season_club(101);
        assert(season_club_1.id == 101, 'SeasonClub 1 ID mismatch');
        assert(season_club_1.season_id == 1, 'SeasonClub 1 season_id');
        assert(season_club_1.club_id == 1, 'SeasonClub 1 club_id');
        assert(season_club_1.manager_id == 0, 'Manager should be 0');
        assert(season_club_1.coach_id == 0, 'Coach should be 0');
        assert(season_club_1.season_points == 0, 'Points should be 0');
        assert(season_club_1.offense == 0, 'Offense should be 0');
        assert(season_club_1.defense == 0, 'Defense should be 0');
        assert(season_club_1.intensity == 0, 'Intensity should be 0');
        assert(season_club_1.chemistry == 0, 'Chemistry should be 0');
        
        let season_club_2 = store.read_season_club(102);
        assert(season_club_2.id == 102, 'SeasonClub 2 ID mismatch');
        assert(season_club_2.season_id == 1, 'SeasonClub 2 season_id');
        assert(season_club_2.club_id == 2, 'SeasonClub 2 club_id');
        
        let season_club_3 = store.read_season_club(103);
        assert(season_club_3.id == 103, 'SeasonClub 3 ID mismatch');
        assert(season_club_3.season_id == 1, 'SeasonClub 3 season_id');
        assert(season_club_3.club_id == 3, 'SeasonClub 3 club_id');
        
        let season_club_4 = store.read_season_club(104);
        assert(season_club_4.id == 104, 'SeasonClub 4 ID mismatch');
        assert(season_club_4.season_id == 1, 'SeasonClub 4 season_id');
        assert(season_club_4.club_id == 4, 'SeasonClub 4 club_id');
    }

    #[test]
    #[available_gas(100000000)]
    fn test_get_season_1_data() {
        let (mut world, admin_system, _caller) = setup();
        
        // Seed Season 1
        admin_system.seed_season_1();
        
        // Get Season 1 data
        let (
            season_id,
            season_name,
            start_date,
            end_date,
            prize_pool,
            clubs,
            season_clubs
        ) = admin_system.get_season_1_data();
        
        // Verify Season data
        assert(season_id == 1, 'Season ID should be 1');
        assert(season_name == "Season 0: Where everything starts", 'Season name mismatch');
        assert(start_date == 1700352000, 'Start date mismatch');
        assert(end_date == 1701993599, 'End date mismatch');
        assert(prize_pool == 0, 'Prize pool should be 0');
        
        // Verify Clubs data
        assert(clubs.len() == 4, 'Should have 4 clubs');
        
        let club_1 = clubs.at(0);
        let (club_1_id, _club_1_name) = club_1;
        assert(*club_1_id == 1, 'Club 1 ID mismatch');
        
        let club_2 = clubs.at(1);
        let (club_2_id, _club_2_name) = club_2;
        assert(*club_2_id == 2, 'Club 2 ID mismatch');
        
        let club_3 = clubs.at(2);
        let (club_3_id, _club_3_name) = club_3;
        assert(*club_3_id == 3, 'Club 3 ID mismatch');
        
        let club_4 = clubs.at(3);
        let (club_4_id, _club_4_name) = club_4;
        assert(*club_4_id == 4, 'Club 4 ID mismatch');
        
        // Verify SeasonClubs data
        assert(season_clubs.len() == 4, 'Should have 4 season_clubs');
        assert(*season_clubs.at(0) == 101, 'SeasonClub 1 ID mismatch');
        assert(*season_clubs.at(1) == 102, 'SeasonClub 2 ID mismatch');
        assert(*season_clubs.at(2) == 103, 'SeasonClub 3 ID mismatch');
        assert(*season_clubs.at(3) == 104, 'SeasonClub 4 ID mismatch');
    }

    #[test]
    #[available_gas(100000000)]
    fn test_season_clubs_all_start_at_zero() {
        let (mut world, admin_system, _caller) = setup();
        
        // Seed Season 1
        admin_system.seed_season_1();
        
        let store = StoreTrait::new(world);
        
        // Check all 4 season_clubs start with zero values
        let season_club_101 = store.read_season_club(101);
        assert(season_club_101.manager_id == 0, 'Manager should be 0');
        assert(season_club_101.coach_id == 0, 'Coach should be 0');
        assert(season_club_101.season_points == 0, 'Points should be 0');
        assert(season_club_101.offense == 0, 'Offense should be 0');
        assert(season_club_101.defense == 0, 'Defense should be 0');
        assert(season_club_101.intensity == 0, 'Intensity should be 0');
        assert(season_club_101.chemistry == 0, 'Chemistry should be 0');
        assert(season_club_101.matches_won == 0, 'Wins should be 0');
        assert(season_club_101.matches_lost == 0, 'Losses should be 0');
        assert(season_club_101.matches_drawn == 0, 'Draws should be 0');
        
        let season_club_102 = store.read_season_club(102);
        assert(season_club_102.manager_id == 0, 'Manager should be 0');
        assert(season_club_102.season_points == 0, 'Points should be 0');
        
        let season_club_103 = store.read_season_club(103);
        assert(season_club_103.manager_id == 0, 'Manager should be 0');
        assert(season_club_103.season_points == 0, 'Points should be 0');
        
        let season_club_104 = store.read_season_club(104);
        assert(season_club_104.manager_id == 0, 'Manager should be 0');
        assert(season_club_104.season_points == 0, 'Points should be 0');
    }
}

