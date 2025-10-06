class_name Skill
extends Resource

@export var skill_name: String = "Fireball"
@export var description: String = "Deals fire damage to one enemy"
@export var mp_cost: int = 5
@export var power: int = 20
@export var damage_type: GameData.DamageType = GameData.DamageType.MAGICAL
@export var target_type: GameData.TargetType = GameData.TargetType.SINGLE_ENEMY
@export var animation_name: String = "fireball"

func can_use(unit: Unit) -> bool:
	return unit.current_mp >= mp_cost

func get_damage(caster: Unit) -> int:
	if damage_type == GameData.DamageType.PHYSICAL:
		return power + caster.attack
	elif damage_type == GameData.DamageType.MAGICAL:
		return power + (caster.magic * 2)
	else:
		return power
