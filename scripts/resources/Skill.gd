class_name Skill
extends Resource

@export var skill_name: String = "Skill"
@export_multiline var description: String = "A powerful ability"
@export var mp_cost: int = 5
@export var power: int = 20
@export var damage_type: GameData.DamageType = GameData.DamageType.MAGICAL
@export var target_type: GameData.TargetType = GameData.TargetType.SINGLE_ENEMY
@export var animation_name: String = "default"
@export var icon_path: String = ""

# Additional effects
@export var heal_power: int = 0
@export var buff_stats: Dictionary = {}
@export var debuff_stats: Dictionary = {}
@export var status_effect: String = ""
@export var status_duration: int = 0

func can_use(unit: Unit) -> bool:
    return unit.current_mp >= mp_cost

func get_damage(caster: Unit) -> int:
    if damage_type == GameData.DamageType.PHYSICAL:
        return power + caster.attack
    elif damage_type == GameData.DamageType.MAGICAL:
        return power + (caster.magic * 2)
    else:  # TRUE damage
        return power

func get_heal_amount(caster: Unit) -> int:
    if heal_power > 0:
        return heal_power + caster.magic
    return 0

func get_valid_targets(caster_team: Array, enemy_team: Array, is_player_turn: bool) -> Array:
    var valid_targets = []
    
    match target_type:
        GameData.TargetType.SINGLE_ENEMY:
            if is_player_turn:
                valid_targets = enemy_team.filter(func(u): return u.is_alive())
            else:
                valid_targets = caster_team.filter(func(u): return u.is_alive())
        
        GameData.TargetType.ALL_ENEMIES:
            if is_player_turn:
                valid_targets = enemy_team.filter(func(u): return u.is_alive())
            else:
                valid_targets = caster_team.filter(func(u): return u.is_alive())
        
        GameData.TargetType.SINGLE_ALLY:
            if is_player_turn:
                valid_targets = caster_team.filter(func(u): return u.is_alive())
            else:
                valid_targets = enemy_team.filter(func(u): return u.is_alive())
        
        GameData.TargetType.ALL_ALLIES:
            if is_player_turn:
                valid_targets = caster_team.filter(func(u): return u.is_alive())
            else:
                valid_targets = enemy_team.filter(func(u): return u.is_alive())
        
        GameData.TargetType.SELF:
            valid_targets = [caster_team.filter(func(u): return u.is_alive())[0]]
    
    return valid_targets
