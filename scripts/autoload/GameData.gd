extends Node

# Unit archetypes
enum UnitClass {
	WARRIOR,
	MAGE,
	HEALER,
	RANGER,
	TANK
}

enum DamageType {
	PHYSICAL,
	MAGICAL,
	TRUE
}

enum TargetType {
	SINGLE_ENEMY,
	ALL_ENEMIES,
	SINGLE_ALLY,
	ALL_ALLIES,
	SELF
}

# Battle states
enum BattleState {
	PLAYER_TURN,
	ENEMY_TURN,
	ANIMATING,
	VICTORY,
	DEFEAT
}

# Current run data (resets each run)
var current_run_data = {
	"floor": 1,
	"heroes": [],
	"items": [],
	"gold": 0
}

# Meta progression (persists between runs)
var meta_progression = {
	"total_exp": 0,
	"unlocked_heroes": [],
	"global_upgrades": {}
}

func reset_run():
	current_run_data = {
		"floor": 1,
		"heroes": [],
		"items": [],
		"gold": 0
	}

func add_gold(amount: int):
	current_run_data.gold += amount

func increment_floor():
	current_run_data.floor += 1
