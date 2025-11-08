// Admin system for seeding and managing game data

#[starknet::interface]
pub trait IAdmin<T> {
    // Seed Season 1 with initial data
    fn seed_season_1(ref self: T);
    
    // Seed a single player (creates both UniversePlayer and OvergoalPlayer)
    fn seed_player(
        ref self: T,
        player_id: felt252,
        user_id: felt252,
        // Universe player attributes
        body_type: u8,
        skin_color: u8,
        beard_type: u8,
        hair_type: u8,
        hair_color: u8,
        // Overgoal player attributes
        energy: u16,
        speed: u16,
        leadership: u16,
        pass: u16,
        shoot: u16,
        freekick: u16,
        visor_type: u8,
        visor_color: u8
    );
    
    // Seed a single season player
    fn seed_season_player(
        ref self: T,
        season_player_id: felt252,
        season_id: felt252,
        season_club_id: felt252,
        overgoal_player_id: felt252
    );
    
    // Get all Season 1 data for verification
    fn get_season_1_data(self: @T) -> (
        // Season data
        felt252, // season_id
        ByteArray, // season_name
        u64, // start_date
        u64, // end_date
        u128, // prize_pool
        // Clubs data (4 clubs)
        Span<(felt252, ByteArray)>, // (club_id, club_name)
        // SeasonClubs data (4 season_clubs)
        Span<felt252>, // season_club_ids
    );
}

#[dojo::contract]
pub mod admin {
    use super::IAdmin;
    
    // Dojo imports
    use dojo::model::ModelStorage;
    use dojo::world::WorldStorage;
    use dojo::world::{WorldStorageTrait};
    
    // Store import
    use overgoal::store::{StoreTrait};
    
    // Models imports
    use overgoal::models::club::{Club};
    use overgoal::models::season::{Season};
    use overgoal::models::season_club::{SeasonClub};
    use overgoal::models::season_player::{SeasonPlayer};
    use overgoal::models::overgoal_player::{OvergoalPlayer};
    
    // Universe contract interaction
    use overgoal::systems::overgoal_game::{IUniverseSafeDispatcher, IUniverseSafeDispatcherTrait};
    
    // Starknet imports
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    
    #[storage]
    struct Storage {
        universe_contract_address: starknet::ContractAddress,
    }
    
    // Constructor
    fn dojo_init(ref self: ContractState, universe_address: starknet::ContractAddress) {
        self.universe_contract_address.write(universe_address);
    }

    #[abi(embed_v0)]
    impl AdminImpl of IAdmin<ContractState> {
        fn seed_season_1(ref self: ContractState) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            // Season 1 details
            let season_id: felt252 = 1;
            let season_name = "Season 0: Where everything starts";
            // November 19, 2024 00:00:00 UTC = 1700352000
            // December 7, 2024 23:59:59 UTC = 1701993599
            let start_date: u64 = 1700352000;
            let end_date: u64 = 1701993599;
            let prize_pool: u128 = 0;
            
            // Create Season 1
            store.create_season(season_id, season_name, start_date, end_date, prize_pool);
            
            // Create Clubs
            let club_1_id: felt252 = 1;
            let club_1_name = "Cartridge Athletic";
            store.create_club(club_1_id, club_1_name);
            
            let club_2_id: felt252 = 2;
            let club_2_name = "Dojo United";
            store.create_club(club_2_id, club_2_name);
            
            let club_3_id: felt252 = 3;
            let club_3_name = "Nova United";
            store.create_club(club_3_id, club_3_name);
            
            let club_4_id: felt252 = 4;
            let club_4_name = "Drakon Core";
            store.create_club(club_4_id, club_4_name);
            
            // Create SeasonClubs (linking clubs to season 1)
            // We'll use sequential IDs for season_clubs: 101, 102, 103, 104
            // Manager and coach IDs are set to 0 (to be assigned later)
            let season_club_1_id: felt252 = 101;
            store.create_season_club(
                season_club_1_id,
                season_id,
                club_1_id,
                0, // manager_id (to be assigned)
                0, // coach_id (to be assigned)
                0, // offense
                0, // defense
                0, // intensity
                0  // chemistry
            );
            
            let season_club_2_id: felt252 = 102;
            store.create_season_club(
                season_club_2_id,
                season_id,
                club_2_id,
                0, // manager_id
                0, // coach_id
                0, // offense
                0, // defense
                0, // intensity
                0  // chemistry
            );
            
            let season_club_3_id: felt252 = 103;
            store.create_season_club(
                season_club_3_id,
                season_id,
                club_3_id,
                0, // manager_id
                0, // coach_id
                0, // offense
                0, // defense
                0, // intensity
                0  // chemistry
            );
            
            let season_club_4_id: felt252 = 104;
            store.create_season_club(
                season_club_4_id,
                season_id,
                club_4_id,
                0, // manager_id
                0, // coach_id
                0, // offense
                0, // defense
                0, // intensity
                0  // chemistry
            );
        }
        
        fn get_season_1_data(self: @ContractState) -> (
            felt252, // season_id
            ByteArray, // season_name
            u64, // start_date
            u64, // end_date
            u128, // prize_pool
            Span<(felt252, ByteArray)>, // clubs
            Span<felt252>, // season_club_ids
        ) {
            let world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            // Read Season 1
            let season_id: felt252 = 1;
            let season = store.read_season(season_id);
            
            // Read Clubs
            let club_1 = store.read_club(1);
            let club_2 = store.read_club(2);
            let club_3 = store.read_club(3);
            let club_4 = store.read_club(4);
            
            let mut clubs_array = array![
                (club_1.id, club_1.name),
                (club_2.id, club_2.name),
                (club_3.id, club_3.name),
                (club_4.id, club_4.name),
            ];
            
            // Read SeasonClubs
            let mut season_clubs_array = array![
                101, // season_club_1_id
                102, // season_club_2_id
                103, // season_club_3_id
                104, // season_club_4_id
            ];
            
            (
                season.id,
                season.name,
                season.start_date,
                season.end_date,
                season.prize_pool,
                clubs_array.span(),
                season_clubs_array.span(),
            )
        }
        
        #[feature("safe_dispatcher")]
        fn seed_player(
            ref self: ContractState,
            player_id: felt252,
            user_id: felt252,
            // Universe player attributes
            body_type: u8,
            skin_color: u8,
            beard_type: u8,
            hair_type: u8,
            hair_color: u8,
            // Overgoal player attributes
            energy: u16,
            speed: u16,
            leadership: u16,
            pass: u16,
            shoot: u16,
            freekick: u16,
            visor_type: u8,
            visor_color: u8
        ) {
            // Get the Universe contract address from storage
            let universe_address = self.universe_contract_address.read();
            
            // Create safe dispatcher for Universe contract
            let universe_dispatcher = IUniverseSafeDispatcher { 
                contract_address: universe_address 
            };
            
            // Create player in Universe contract
            let result = universe_dispatcher.create_player(
                player_id,
                user_id,
                body_type,
                skin_color,
                beard_type,
                hair_type,
                hair_color
            );
            
            // Handle result
            match result {
                Result::Ok(_) => {
                    // Universe player created successfully, now create overgoal player
                    let mut world = self.world(@"overgoal");
                    let store = StoreTrait::new(world);
                    
                    store.create_overgoal_player(
                        player_id,
                        player_id, // universe_player_id is same as player_id
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
                    panic!("Failed to create universe player");
                },
            }
        }
        
        fn seed_season_player(
            ref self: ContractState,
            season_player_id: felt252,
            season_id: felt252,
            season_club_id: felt252,
            overgoal_player_id: felt252
        ) {
            let mut world = self.world(@"overgoal");
            let store = StoreTrait::new(world);
            
            // Create season player with default relationship values
            store.create_season_player(
                season_player_id,
                season_id,
                season_club_id,
                overgoal_player_id,
                50, // team_relationship (starting at 50)
                50  // fans_relationship (starting at 50)
            );
        }
    }
}

