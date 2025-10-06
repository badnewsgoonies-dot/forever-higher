class_name Unit
extends Resource

@export var unit_name: String = "Hero"
@export var unit_class: GameData.UnitClass = GameData.UnitClass.WARRIOR
@export var sprite: Texture2D

# Base stats
@export var max_hp: int = 100
@export var max_mp: int = 30
@export var attack: int = 10
@export var defense: int = 5
@export var magic: int = 5
@export var speed: int = 5

# Current stats (for in-battle)
var current_hp: int
var current_mp: int
var is_defending: bool = false
var status_effects: Array = []

# Skills this unit knows
@export var skills: Array[Skill] = []

func initialize():
	current_hp = max_hp
	current_mp = max_mp
	is_defending = false
	status_effects.clear()

func take_damage(amount: int, damage_type: GameData.DamageType) -> int:
	var final_damage = amount
	
	if damage_type == GameData.DamageType.PHYSICAL:
		final_damage -= defense
		if is_defending:
			final_damage = int(final_damage * 0.5)
	elif damage_type == GameData.DamageType.MAGICAL:
		final_damage -= int(magic * 0.5)
	
	final_damage = max(1, final_damage)  # Minimum 1 damage
	current_hp -= final_damage
	current_hp = max(0, current_hp)
	
	return final_damage

func heal(amount: int):
	current_hp = min(current_hp + amount, max_hp)

func use_mp(amount: int) -> bool:
	if current_mp >= amount:
		current_mp -= amount
		return true
	return false

func is_alive() -> bool:
	return current_hp > 0
