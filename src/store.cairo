// Starknet imports
use starknet::{ContractAddress, get_caller_address, get_block_timestamp};

// Dojo imports
use dojo::world::WorldStorage;
use dojo::model::ModelStorage;

// Models imports
use overgoal::models::user::{User, UserTrait, UserAssert, ZeroableUserTrait};
use overgoal::models::overgoal_player::{OvergoalPlayer, OvergoalPlayerTrait, OvergoalPlayerAssert, ZeroableOvergoalPlayerTrait};
use overgoal::models::club::{Club, ClubTrait, AssertClubTrait};
use overgoal::models::season::{Season, SeasonTrait, AssertSeasonTrait};
use overgoal::models::season_club::{SeasonClub, SeasonClubTrait, AssertSeasonClubTrait};
use overgoal::models::season_player::{SeasonPlayer, SeasonPlayerTrait, AssertSeasonPlayerTrait};

// Helpers import
use overgoal::helpers::timestamp::Timestamp;

// Store struct
#[derive(Copy, Drop)]
pub struct Store {
    world: WorldStorage,
}

//Implementation of the `StoreTrait` trait for the `Store` struct
#[generate_trait]
pub impl StoreImpl of StoreTrait {
    fn new(world: WorldStorage) -> Store {
        Store { world: world }
    }

    // --------- User Getters ---------
    fn read_user_from_address(self: Store, user_address: ContractAddress) -> User {
        self.world.read_model(user_address)
    }

    fn read_user(self: Store) -> User {
        let user_address = get_caller_address();
        self.world.read_model(user_address)
    }

    fn user_exists(self: Store, user_address: ContractAddress) -> bool {
        let user: User = self.world.read_model(user_address);
        user.is_non_zero()
    }

    // --------- Setters ---------
    fn write_user(mut self: Store, user: @User) {
        self.world.write_model(user)
    }
    
    // --------- New entities ---------

    fn create_user(mut self: Store, username: felt252) {
        let caller = get_caller_address();
        let current_timestamp = get_block_timestamp();
        
        // Assert user doesn't already exist
        assert(!self.user_exists(caller), 'User already exists');
        
        // Create new user
        let new_user = UserTrait::new(caller, username, current_timestamp);
        
        self.world.write_model(@new_user);
    }

    fn create_user_with_address(mut self: Store, user_address: ContractAddress, username: felt252) {
        let current_timestamp = get_block_timestamp();
        
        // Assert user doesn't already exist
        assert(!self.user_exists(user_address), 'User already exists');
        
        // Create new user
        let new_user = UserTrait::new(user_address, username, current_timestamp);
        
        self.world.write_model(@new_user);
    }

    // --------- User Management ---------
    fn rename_user(mut self: Store, new_username: felt252) {
        // Read existing user for caller
        let mut user = self.read_user();
        user.assert_exists();
        assert(new_username != 0, 'Invalid username');
        
        // Update username
        user.username = new_username;
        
        self.world.write_model(@user);
    }

    fn rename_user_with_address(mut self: Store, user_address: ContractAddress, new_username: felt252) {
        // Read existing user
        let mut user = self.read_user_from_address(user_address);
        user.assert_exists();
        assert(new_username != 0, 'Invalid username');
        
        // Update username
        user.username = new_username;
        
        self.world.write_model(@user);
    }

    // --------- OvergoalPlayer Getters ---------
    fn read_overgoal_player_from_id(self: Store, overgoal_player_id: felt252) -> OvergoalPlayer {
        self.world.read_model(overgoal_player_id)
    }

    fn overgoal_player_exists(self: Store, overgoal_player_id: felt252) -> bool {
        let player: OvergoalPlayer = self.world.read_model(overgoal_player_id);
        player.is_non_zero()
    }

    // --------- OvergoalPlayer Setters ---------
    fn write_overgoal_player(mut self: Store, player: @OvergoalPlayer) {
        self.world.write_model(player)
    }

    // --------- OvergoalPlayer Creation ---------
    fn create_overgoal_player(
        mut self: Store,
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
        // Assert overgoal player doesn't already exist
        assert(!self.overgoal_player_exists(overgoal_player_id), 'OvergoalPlayer already exists');

        // Create new overgoal player
        let new_player = OvergoalPlayerTrait::new(
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

        self.world.write_model(@new_player);
    }

    // --------- OvergoalPlayer Management ---------
    fn update_overgoal_player_stats(
        mut self: Store,
        overgoal_player_id: felt252,
        speed: u16,
        leadership: u16,
        pass: u16,
        shoot: u16,
        freekick: u16
    ) {
        let mut player = self.read_overgoal_player_from_id(overgoal_player_id);
        player.assert_exists();
        
        // Update stats by creating a new player with updated values
        // Note: In a real implementation, you might want individual update methods
        // For now, we'll read the player, modify it, and write it back
        let updated_player = OvergoalPlayer {
            id: player.id,
            universe_player_id: player.universe_player_id,
            goal_currency: player.goal_currency,
            energy: player.energy,
            speed,
            leadership,
            pass,
            shoot,
            freekick,
            is_injured: player.is_injured,
            visor_type: player.visor_type,
            visor_color: player.visor_color,
        };
        
        self.world.write_model(@updated_player);
    }

    fn add_overgoal_player_currency(mut self: Store, overgoal_player_id: felt252, amount: u128) {
        let mut player = self.read_overgoal_player_from_id(overgoal_player_id);
        player.assert_exists();
        
        player.add_currency(amount);
        
        self.world.write_model(@player);
    }

    fn spend_overgoal_player_currency(mut self: Store, overgoal_player_id: felt252, amount: u128) {
        let mut player = self.read_overgoal_player_from_id(overgoal_player_id);
        player.assert_exists();
        
        player.spend_currency(amount);
        
        self.world.write_model(@player);
    }

    fn set_overgoal_player_injury(mut self: Store, overgoal_player_id: felt252, is_injured: bool) {
        let mut player = self.read_overgoal_player_from_id(overgoal_player_id);
        player.assert_exists();
        
        player.set_injured(is_injured);
        
        self.world.write_model(@player);
    }

    // ========================================
    // Club CRUD Operations
    // ========================================

    fn read_club(self: Store, club_id: felt252) -> Club {
        self.world.read_model(club_id)
    }

    fn club_exists(self: Store, club_id: felt252) -> bool {
        let club: Club = self.world.read_model(club_id);
        club.is_non_zero()
    }

    fn create_club(mut self: Store, club_id: felt252, name: ByteArray) {
        assert(!self.club_exists(club_id), 'Club already exists');
        let club = ClubTrait::new(club_id, name);
        self.world.write_model(@club);
    }

    fn update_club_name(mut self: Store, club_id: felt252, new_name: ByteArray) {
        let mut club = self.read_club(club_id);
        club.assert_exists();
        club.update_name(new_name);
        self.world.write_model(@club);
    }

    // ========================================
    // Season CRUD Operations
    // ========================================

    fn read_season(self: Store, season_id: felt252) -> Season {
        self.world.read_model(season_id)
    }

    fn season_exists(self: Store, season_id: felt252) -> bool {
        let season: Season = self.world.read_model(season_id);
        season.is_non_zero()
    }

    fn create_season(
        mut self: Store,
        season_id: felt252,
        name: ByteArray,
        start_date: u64,
        end_date: u64,
        prize_pool: u128
    ) {
        assert(!self.season_exists(season_id), 'Season already exists');
        let season = SeasonTrait::new(season_id, name, start_date, end_date, prize_pool);
        self.world.write_model(@season);
    }

    fn extend_season(mut self: Store, season_id: felt252, new_end_date: u64) {
        let mut season = self.read_season(season_id);
        season.assert_exists();
        season.extend_end_date(new_end_date);
        self.world.write_model(@season);
    }

    fn increase_season_prize_pool(mut self: Store, season_id: felt252, additional_amount: u128) {
        let mut season = self.read_season(season_id);
        season.assert_exists();
        season.increase_prize_pool(additional_amount);
        self.world.write_model(@season);
    }

    // ========================================
    // SeasonClub CRUD Operations
    // ========================================

    fn read_season_club(self: Store, season_club_id: felt252) -> SeasonClub {
        self.world.read_model(season_club_id)
    }

    fn season_club_exists(self: Store, season_club_id: felt252) -> bool {
        let season_club: SeasonClub = self.world.read_model(season_club_id);
        season_club.is_non_zero()
    }

    fn create_season_club(
        mut self: Store,
        season_club_id: felt252,
        season_id: felt252,
        club_id: felt252,
        manager_id: felt252,
        coach_id: felt252,
        offense: u16,
        defense: u16,
        intensity: u16,
        chemistry: u16
    ) {
        assert(!self.season_club_exists(season_club_id), 'SeasonClub already exists');
        let season_club = SeasonClubTrait::new(
            season_club_id, season_id, club_id, manager_id, coach_id,
            offense, defense, intensity, chemistry
        );
        self.world.write_model(@season_club);
    }

    fn update_season_club_manager(mut self: Store, season_club_id: felt252, new_manager_id: felt252) {
        let mut season_club = self.read_season_club(season_club_id);
        season_club.assert_exists();
        season_club.change_manager(new_manager_id);
        self.world.write_model(@season_club);
    }

    fn update_season_club_coach(mut self: Store, season_club_id: felt252, new_coach_id: felt252) {
        let mut season_club = self.read_season_club(season_club_id);
        season_club.assert_exists();
        season_club.change_coach(new_coach_id);
        self.world.write_model(@season_club);
    }

    fn update_season_club_attributes(
        mut self: Store,
        season_club_id: felt252,
        offense: u16,
        defense: u16,
        intensity: u16,
        chemistry: u16
    ) {
        let mut season_club = self.read_season_club(season_club_id);
        season_club.assert_exists();
        season_club.update_team_attributes(offense, defense, intensity, chemistry);
        self.world.write_model(@season_club);
    }

    fn record_season_club_match_win(mut self: Store, season_club_id: felt252, points: u32) {
        let mut season_club = self.read_season_club(season_club_id);
        season_club.assert_exists();
        season_club.record_match_win(points);
        self.world.write_model(@season_club);
    }

    fn record_season_club_match_loss(mut self: Store, season_club_id: felt252) {
        let mut season_club = self.read_season_club(season_club_id);
        season_club.assert_exists();
        season_club.record_match_loss();
        self.world.write_model(@season_club);
    }

    fn record_season_club_match_draw(mut self: Store, season_club_id: felt252, points: u32) {
        let mut season_club = self.read_season_club(season_club_id);
        season_club.assert_exists();
        season_club.record_match_draw(points);
        self.world.write_model(@season_club);
    }

    // ========================================
    // SeasonPlayer CRUD Operations
    // ========================================

    fn read_season_player(self: Store, season_player_id: felt252) -> SeasonPlayer {
        self.world.read_model(season_player_id)
    }

    fn season_player_exists(self: Store, season_player_id: felt252) -> bool {
        let season_player: SeasonPlayer = self.world.read_model(season_player_id);
        season_player.is_non_zero()
    }

    fn create_season_player(
        mut self: Store,
        season_player_id: felt252,
        season_id: felt252,
        season_club_id: felt252,
        overgoal_player_id: felt252,
        team_relationship: u16,
        fans_relationship: u16
    ) {
        assert(!self.season_player_exists(season_player_id), 'SeasonPlayer already exists');
        let season_player = SeasonPlayerTrait::new(
            season_player_id, season_id, season_club_id, overgoal_player_id,
            team_relationship, fans_relationship
        );
        self.world.write_model(@season_player);
    }

    fn transfer_season_player(mut self: Store, season_player_id: felt252, new_season_club_id: felt252) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.transfer_to_club(new_season_club_id);
        self.world.write_model(@season_player);
    }

    fn update_season_player_team_relationship(mut self: Store, season_player_id: felt252, change: i16) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.update_team_relationship(change);
        self.world.write_model(@season_player);
    }

    fn update_season_player_fans_relationship(mut self: Store, season_player_id: felt252, change: i16) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.update_fans_relationship(change);
        self.world.write_model(@season_player);
    }

    fn add_season_player_points(mut self: Store, season_player_id: felt252, points: u32) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.add_season_points(points);
        self.world.write_model(@season_player);
    }

    fn record_season_player_match_win(mut self: Store, season_player_id: felt252) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.record_match_win();
        self.world.write_model(@season_player);
    }

    fn record_season_player_match_loss(mut self: Store, season_player_id: felt252) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.record_match_loss();
        self.world.write_model(@season_player);
    }

    fn award_season_player_trophy(mut self: Store, season_player_id: felt252) {
        let mut season_player = self.read_season_player(season_player_id);
        season_player.assert_exists();
        season_player.award_trophy();
        self.world.write_model(@season_player);
    }
    
}