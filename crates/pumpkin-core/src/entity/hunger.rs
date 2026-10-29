use super::{NBTStorage, NBTStorageInit, player::Player};
use crossbeam::atomic::AtomicCell;
use pumpkin_nbt::compound::NbtCompound;

const MAX_FOOD: u8 = 20;
const EXHAUSTION_COST: f32 = 4.0;
const MAX_EXHAUSTION: f32 = 40.0;

pub struct HungerManager {
    pub level: AtomicCell<u8>,
    pub saturation: AtomicCell<f32>,
    pub exhaustion: AtomicCell<f32>,
    pub tick_timer: AtomicCell<u32>,
}

impl Default for HungerManager {
    fn default() -> Self {
        Self {
            level: AtomicCell::new(MAX_FOOD),
            saturation: AtomicCell::new(5.0),
            exhaustion: AtomicCell::new(0.0),
            tick_timer: AtomicCell::new(0),
        }
    }
}

impl HungerManager {
    pub fn tick(&self, _player: &Player) {
        // Hunger disabled in PumpkinLobby.
    }

    pub fn eat(&self, player: &Player, food: u8, saturation: f32) {
        let new_level = self.level.load().saturating_add(food).min(MAX_FOOD);
        let new_sat = (self.saturation.load() + saturation).clamp(0.0, f32::from(new_level));

        self.level.store(new_level);
        self.saturation.store(new_sat);

        player.send_health();
    }

    /// Add exhaustion to trigger hunger decrease
    pub fn add_exhaustion(&self, exhaustion: f32) {
        let current = self.exhaustion.load();
        self.exhaustion
            .store((current + exhaustion).min(MAX_EXHAUSTION));
    }

    /// Add hunger manually
    pub fn add_hunger(&self, hunger: u8) {
        let current = self.level.load();
        self.level.store((current + hunger).min(MAX_FOOD));
    }

    /// Add saturation manually
    pub fn add_saturation(&self, saturation: f32) {
        let current = self.saturation.load();
        self.saturation
            .store((current + saturation).min(f32::from(self.level.load())));
    }

    pub fn set_level(&self, level: u8) {
        self.level.store(level);
    }

    pub fn set_saturation(&self, saturation: f32) {
        self.saturation.store(saturation);
    }

    pub fn get_exhaustion(&self) -> f32 {
        self.exhaustion.load()
    }

    pub fn set_exhaustion(&self, exhaustion: f32) {
        self.exhaustion.store(exhaustion.min(MAX_EXHAUSTION));
    }

    pub fn restart(&self) {
        self.level.store(MAX_FOOD);
        self.saturation.store(5.0);
        self.exhaustion.store(0.0);
        self.tick_timer.store(0);
    }
}

impl NBTStorage for HungerManager {
    fn write_nbt(&self, nbt: &mut NbtCompound) {
        nbt.put_int("foodLevel", self.level.load().into());
        nbt.put_float("foodSaturationLevel", self.saturation.load());
        nbt.put_float("foodExhaustionLevel", self.exhaustion.load());
        nbt.put_int("foodTickTimer", self.tick_timer.load() as i32);
    }

    fn read_nbt_non_mut(&self, nbt: &NbtCompound) {
        self.level
            .store(nbt.get_int("foodLevel").unwrap_or(20) as u8);
        self.saturation
            .store(nbt.get_float("foodSaturationLevel").unwrap_or(5.0));
        self.exhaustion
            .store(nbt.get_float("foodExhaustionLevel").unwrap_or(0.0));
        self.tick_timer
            .store(nbt.get_int("foodTickTimer").unwrap_or(0) as u32);
    }
}

impl NBTStorageInit for HungerManager {}

