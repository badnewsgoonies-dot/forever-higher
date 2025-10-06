class_name BattleManager
extends Node

signal battle_ended(victory: bool, rewards: Dictionary)
signal unit_turn_started(unit: Unit)
signal phase_changed(is_player_phase: bool)
signal damage_dealt(target: Unit, amount: int)
signal unit_defeated(unit: Unit)

@onready var player_positions = $"../BattleField/PlayerPositions"
@onready var enemy_positions = $"../BattleField/EnemyPositions"
@onready var battle_ui = $"../UI/BattleUI"

var state: GameData.BattleState = GameData.BattleState.PLAYER_TURN
var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var all_player_sprites: Array = []
var all_enemy_sprites: Array = []

var current_unit_index: int = 0
var is_player_phase: bool = true
var selected_skill: Skill = null
var battle_rewards: Dictionary = {
	"exp": 0,
	"gold": 0,
	"items": []
}

func _ready():
	if battle_ui:
		battle_ui.action_selected.connect(_on_action_selected)
func start_battle(heroes: Array, enemies: Array):
	player_units = heroes
	enemy_units = enemies
	
	# Initialize all units
	for unit in player_units:
		unit.initialize()
	for unit in enemy_units:
		unit.initialize()
	
	# Calculate battle rewards based on enemies
	battle_rewards.exp = enemy_units.size() * 50
	battle_rewards.gold = enemy_units.size() * 30
	
	# Spawn unit sprites
	spawn_units()
	
	# Update UI
	if battle_ui:
		battle_ui.setup_battle(player_units, enemy_units)
	
	# Start player phase
	await get_tree().process_frame
	start_player_phase()

func spawn_units():
	# Clear existing sprites
	for sprite in all_player_sprites + all_enemy_sprites:
		sprite.queue_free()
	all_player_sprites.clear()
	all_enemy_sprites.clear()    
	# Spawn player units
	var player_spots = player_positions.get_children()
	for i in range(min(player_units.size(), player_spots.size())):
		var unit_sprite = preload("res://scenes/battle/UnitSprite.tscn").instantiate()
		unit_sprite.setup(player_units[i], true)
		unit_sprite.position = player_spots[i].position
		player_units[i].position_index = i
		add_child(unit_sprite)
		all_player_sprites.append(unit_sprite)
	
	# Spawn enemy units
	var enemy_spots = enemy_positions.get_children()
	for i in range(min(enemy_units.size(), enemy_spots.size())):
		var unit_sprite = preload("res://scenes/battle/UnitSprite.tscn").instantiate()
		unit_sprite.setup(enemy_units[i], false)
		unit_sprite.position = enemy_spots[i].position
		enemy_units[i].position_index = i
		add_child(unit_sprite)
		all_enemy_sprites.append(unit_sprite)

func start_player_phase():
	state = GameData.BattleState.PLAYER_TURN
	is_player_phase = true
	current_unit_index = 0
	
	# Reset defend status
	for unit in player_units:
		unit.is_defending = false    
	phase_changed.emit(true)
	
	if get_alive_player_units().size() > 0:
		select_next_unit()
	else:
		end_battle(false)

func start_enemy_phase():
	state = GameData.BattleState.ENEMY_TURN
	is_player_phase = false
	current_unit_index = 0
	
	# Reset defend status
	for unit in enemy_units:
		unit.is_defending = false
	
	phase_changed.emit(false)
	
	if battle_ui:
		battle_ui.hide_action_menu()
	
	await get_tree().create_timer(0.5).timeout
	process_enemy_turns()

func select_next_unit():
	var alive_units = get_alive_player_units()
	
	if current_unit_index >= alive_units.size():
		# All player units have acted
		start_enemy_phase()
		return    
	var current_unit = alive_units[current_unit_index]
	unit_turn_started.emit(current_unit)
	
	if battle_ui:
		battle_ui.show_action_menu(current_unit)
	
	# Highlight current unit
	highlight_current_unit(current_unit)

func process_enemy_turns():
	# Simple AI - each enemy acts
	var alive_enemies = get_alive_enemy_units()
	
	for enemy in alive_enemies:
		if not enemy.is_alive():
			continue
			
		await get_tree().create_timer(0.5).timeout
		
		# Simple AI logic
		var targets = get_alive_player_units()
		if targets.size() > 0:
			# 70% chance to attack, 30% to use skill if available
			if enemy.skills.size() > 0 and randf() < 0.3:
				var skill = enemy.skills[0]
				if skill.can_use(enemy):
					var skill_targets = get_skill_targets(skill, enemy, false)
					if skill_targets.size() > 0:
						execute_skill(enemy, skill, skill_targets)
						await get_tree().create_timer(1.0).timeout
						continue            
			# Default to basic attack
			var target = targets.pick_random()
			execute_attack(enemy, target)
			await get_tree().create_timer(0.7).timeout
	
	# Check for battle end
	if get_alive_player_units().size() == 0:
		end_battle(false)
	elif get_alive_enemy_units().size() == 0:
		end_battle(true)
	else:
		start_player_phase()

func execute_attack(attacker: Unit, target: Unit):
	state = GameData.BattleState.ANIMATING
	
	var damage = target.take_damage(attacker.attack, GameData.DamageType.PHYSICAL)
	damage_dealt.emit(target, damage)
	
	# Update UI
	if battle_ui:
		battle_ui.show_damage(target, damage)
		battle_ui.update_health_bars()
	
	# Play animation on sprites
	var attacker_sprite = get_unit_sprite(attacker)
	var target_sprite = get_unit_sprite(target)
	
	if attacker_sprite:
		attacker_sprite.play_attack_animation()    
	if target_sprite:
		target_sprite.play_hurt_animation()
	
	if not target.is_alive():
		unit_defeated.emit(target)
	
	state = GameData.BattleState.PLAYER_TURN if is_player_phase else GameData.BattleState.ENEMY_TURN

func execute_skill(caster: Unit, skill: Skill, targets: Array):
	state = GameData.BattleState.ANIMATING
	
	if not skill.can_use(caster):
		return
	
	caster.use_mp(skill.mp_cost)
	
	# Play skill animation
	var caster_sprite = get_unit_sprite(caster)
	if caster_sprite:
		caster_sprite.play_skill_animation(skill.animation_name)
	
	# Apply skill effects
	for target in targets:
		if skill.power > 0:  # Damage skill
			var damage = skill.get_damage(caster)
			var actual_damage = target.take_damage(damage, skill.damage_type)
			damage_dealt.emit(target, actual_damage)
			
			if battle_ui:
				battle_ui.show_damage(target, actual_damage)        
		if skill.heal_power > 0:  # Healing skill
			var heal = skill.get_heal_amount(caster)
			var actual_heal = target.heal(heal)
			
			if battle_ui:
				battle_ui.show_heal(target, actual_heal)
		
		if skill.status_effect != "":
			target.apply_status_effect(skill.status_effect, skill.status_duration)
		
		if not target.is_alive():
			unit_defeated.emit(target)
	
	if battle_ui:
		battle_ui.update_health_bars()
	
	state = GameData.BattleState.PLAYER_TURN if is_player_phase else GameData.BattleState.ENEMY_TURN

func execute_defend(unit: Unit):
	unit.is_defending = true
	
	var unit_sprite = get_unit_sprite(unit)
	if unit_sprite:
		unit_sprite.play_defend_animation()
	
	# Move to next unit
	current_unit_index += 1
	await get_tree().create_timer(0.3).timeout
	select_next_unit()
func end_battle(victory: bool):
	state = GameData.BattleState.VICTORY if victory else GameData.BattleState.DEFEAT
	
	if victory:
		# Add rewards to game data
		GameData.current_run_data.gold += battle_rewards.gold
		GameData.add_meta_exp(battle_rewards.exp)
		GameData.current_run_data.floor += 1
		
		if GameData.current_run_data.floor > GameData.meta_progression.best_floor:
			GameData.meta_progression.best_floor = GameData.current_run_data.floor
	else:
		# End run
		GameData.meta_progression.total_runs += 1
	
	GameData.save_game_data()
	battle_ended.emit(victory, battle_rewards)

# Helper functions
func get_alive_player_units() -> Array:
	return player_units.filter(func(u): return u.is_alive())

func get_alive_enemy_units() -> Array:
	return enemy_units.filter(func(u): return u.is_alive())

func get_unit_sprite(unit: Unit) -> Node:
	if unit in player_units:
		var index = player_units.find(unit)
		if index >= 0 and index < all_player_sprites.size():
			return all_player_sprites[index]
	else:
		var index = enemy_units.find(unit)
		if index >= 0 and index < all_enemy_sprites.size():
			return all_enemy_sprites[index]
	return null

func highlight_current_unit(unit: Unit):
	var sprite = get_unit_sprite(unit)
	if sprite:
		sprite.set_highlight(true)
	
	# Remove highlight from others
	for s in all_player_sprites:
		if s != sprite:
			s.set_highlight(false)

func get_skill_targets(skill: Skill, caster: Unit, is_player: bool) -> Array:
	var targets = []
	var caster_team = player_units if is_player else enemy_units
	var enemy_team = enemy_units if is_player else player_units
	
	match skill.target_type:
		GameData.TargetType.SINGLE_ENEMY:
			var enemies = enemy_team.filter(func(u): return u.is_alive())
			if enemies.size() > 0:
				targets = [enemies.pick_random()]  # AI picks random
		GameData.TargetType.ALL_ENEMIES:
			targets = enemy_team.filter(func(u): return u.is_alive())
		GameData.TargetType.SINGLE_ALLY:
			var allies = caster_team.filter(func(u): return u.is_alive())
			if allies.size() > 0:
				# Heal lowest HP ally
				allies.sort_custom(func(a, b): return a.get_hp_percentage() < b.get_hp_percentage())
				targets = [allies[0]]
		GameData.TargetType.ALL_ALLIES:
			targets = caster_team.filter(func(u): return u.is_alive())
		GameData.TargetType.SELF:
			targets = [caster]
	
	return targets

# Signal handlers
func _on_action_selected(action: String, data = null):
	var alive_units = get_alive_player_units()
	if current_unit_index >= alive_units.size():
		return
	
	var current_unit = alive_units[current_unit_index]
	
	match action:
		"attack":
			# Need target selection
			pass  # Will be handled by UI
		"defend":
			execute_defend(current_unit)
		"skill":
			selected_skill = data
			# Need target selection
		"item":
			# TODO: Implement items
			pass
