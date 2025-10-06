class_name BattleManager
extends Node

signal battle_ended(victory: bool)
signal unit_turn_started(unit: Unit)
signal health_changed()

@onready var player_positions = $"../BattleField/PlayerPositions"
@onready var enemy_positions = $"../BattleField/EnemyPositions"
@onready var action_menu = $"../UI/ActionMenu"

var state: GameData.BattleState = GameData.BattleState.PLAYER_TURN
var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var current_unit_index: int = 0
var is_player_phase: bool = true
var current_unit: Unit = null

func start_battle(heroes: Array[Unit], enemies: Array[Unit]):
	player_units = heroes
	enemy_units = enemies
	
	# Initialize all units
	for unit in player_units + enemy_units:
		unit.initialize()
	
	# Spawn unit sprites
	_spawn_units()
	
	# Start player phase
	start_player_phase()

func start_player_phase():
	state = GameData.BattleState.PLAYER_TURN
	is_player_phase = true
	current_unit_index = 0
	
	# Reset defend status for all player units
	for unit in player_units:
		unit.is_defending = false
	
	if _get_alive_player_units().size() > 0:
		select_next_unit()
	else:
		battle_ended.emit(false)

func start_enemy_phase():
	state = GameData.BattleState.ENEMY_TURN
	is_player_phase = false
	current_unit_index = 0
	
	# Reset defend status for all enemy units
	for unit in enemy_units:
		unit.is_defending = false
	
	process_enemy_turns()

func select_next_unit():
	var alive_units = _get_alive_player_units()
	if current_unit_index >= alive_units.size():
		# All player units have acted
		start_enemy_phase()
		return
	
	current_unit = alive_units[current_unit_index]
	unit_turn_started.emit(current_unit)
	action_menu.show()
	
	# Update UI to show current unit
	_highlight_current_unit(current_unit)

func end_current_unit_turn():
	current_unit_index += 1
	select_next_unit()

func process_enemy_turns():
	action_menu.hide()
	# Simple AI - each enemy attacks random player
	for enemy in _get_alive_enemy_units():
		await get_tree().create_timer(0.5).timeout
		var targets = _get_alive_player_units()
		if targets.size() > 0:
			var target = targets.pick_random()
			execute_attack(enemy, target)
			await get_tree().create_timer(0.5).timeout
	
	# Check for victory/defeat
	if _get_alive_player_units().size() == 0:
		battle_ended.emit(false)
	elif _get_alive_enemy_units().size() == 0:
		battle_ended.emit(true)
	else:
		start_player_phase()

func execute_attack(attacker: Unit, target: Unit):
	var damage = target.take_damage(attacker.attack, GameData.DamageType.PHYSICAL)
	print("%s attacks %s for %d damage!" % [attacker.unit_name, target.unit_name, damage])
	health_changed.emit()

func execute_skill(caster: Unit, skill: Skill, targets: Array[Unit]):
	if not skill.can_use(caster):
		return
	
	caster.use_mp(skill.mp_cost)
	
	for target in targets:
		var damage = skill.get_damage(caster)
		target.take_damage(damage, skill.damage_type)
	
	health_changed.emit()

func defend(unit: Unit):
	unit.is_defending = true
	end_current_unit_turn()

func _get_alive_player_units() -> Array[Unit]:
	return player_units.filter(func(u): return u.is_alive())

func _get_alive_enemy_units() -> Array[Unit]:
	return enemy_units.filter(func(u): return u.is_alive())

func _spawn_units():
	# TODO: Create unit sprites at positions
	pass

func _highlight_current_unit(unit: Unit):
	# TODO: Visual indicator for current unit
	pass
