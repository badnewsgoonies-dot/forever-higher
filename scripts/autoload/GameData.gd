extends Node

# Game constants
const MAX_LEVELS = 10
const BASE_ENEMY_HEALTH = 100
const BASE_PLAYER_HEALTH = 100
const SKILL_POINTS_PER_LEVEL = 2

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

# Current run data
var current_run_data = {
	"floor": 1,
	"heroes": [],
	"items": [],
	"gold": 100,
	"path_choices": []
}

# Meta progression (persists between runs)
var meta_progression = {
	"total_exp": 0,
	"unlocked_heroes": ["Warrior", "Mage", "Healer"],
	"global_upgrades": {},
	"total_runs": 0,
	"best_floor": 0
}

# Persistent game datavar unlocked_skills: Array = []
var skill_points: int = 0
var player_stats = {
	"max_health": 100,
	"current_health": 100,
	"attack_power": 10,
	"defense": 5,
	"speed": 100
}

# Signals
signal level_completed
signal game_over
signal skill_unlocked(skill_name)

func _ready():
	print("GameData singleton loaded")
	load_game_data()

func reset_run_data():
	current_run_data = {
		"floor": 1,
		"heroes": [],
		"items": [],
		"gold": 100,
		"path_choices": []
	}
func add_meta_exp(amount: int):
	meta_progression.total_exp += amount

func unlock_hero(hero_name: String):
	if not hero_name in meta_progression.unlocked_heroes:
		meta_progression.unlocked_heroes.append(hero_name)

func save_game_data():
	var save_dict = {
		"meta_progression": meta_progression,
		"unlocked_skills": unlocked_skills,
		"skill_points": skill_points
	}
	
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_var(save_dict)
		save_file.close()
		print("Game saved successfully")

func load_game_data():
	if not FileAccess.file_exists("user://savegame.dat"):
		print("No save file found")
		return
		
	var save_file = FileAccess.open("user://savegame.dat", FileAccess.READ)
	if save_file:
		var save_dict = save_file.get_var()
		save_file.close()
		
		meta_progression = save_dict.get("meta_progression", meta_progression)
		unlocked_skills = save_dict.get("unlocked_skills", [])
		skill_points = save_dict.get("skill_points", 0)
		
		print("Game loaded successfully")
