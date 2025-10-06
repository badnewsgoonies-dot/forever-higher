class_name Unit
extends Resource

@export var unit_name: String = "Hero"
@export var unit_class: GameData.UnitClass = GameData.UnitClass.WARRIOR
@export var sprite_path: String = ""
@export_multiline var description: String = "A brave warrior"

# Base stats
@export_group("Base Stats")
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
var position_index: int = 0

# Skills this unit knows
@export_group("Skills")
@export var skills: Array[Resource] = []
func initialize():
    current_hp = max_hp
    current_mp = max_mp
    is_defending = false
    status_effects.clear()

func duplicate_for_battle() -> Unit:
    var copy = duplicate(true)
    copy.initialize()
    return copy

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

func heal(amount: int) -> int:
    var actual_heal = min(amount, max_hp - current_hp)
    current_hp += actual_heal
    return actual_heal

func restore_mp(amount: int) -> int:
    var actual_restore = min(amount, max_mp - current_mp)
    current_mp += actual_restore
    return actual_restore

func use_mp(amount: int) -> bool:
    if current_mp >= amount:
        current_mp -= amount
        return true
    return false

func is_alive() -> bool:
    return current_hp > 0

func get_hp_percentage() -> float:
    return float(current_hp) / float(max_hp)

func get_mp_percentage() -> float:
    if max_mp == 0:
        return 0.0
    return float(current_mp) / float(max_mp)

func apply_status_effect(effect: String, duration: int):
    status_effects.append({
        "effect": effect,
        "duration": duration
    })

func process_status_effects():
    var effects_to_remove = []
    for i in range(status_effects.size()):
        status_effects[i].duration -= 1
        if status_effects[i].duration <= 0:
            effects_to_remove.append(i)
    
    # Remove expired effects (in reverse order)
    for i in range(effects_to_remove.size() - 1, -1, -1):
        status_effects.remove_at(effects_to_remove[i])
