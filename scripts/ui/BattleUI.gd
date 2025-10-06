class_name BattleUI
extends CanvasLayer

@onready var player_health_bars = $TopBar/PlayerHealthBars
@onready var enemy_health_bars = $TopBar/EnemyHealthBars
@onready var action_menu = $ActionMenu
@onready var attack_btn = $ActionMenu/VBoxContainer/AttackBtn
@onready var skills_btn = $ActionMenu/VBoxContainer/SkillsBtn
@onready var items_btn = $ActionMenu/VBoxContainer/ItemsBtn
@onready var defend_btn = $ActionMenu/VBoxContainer/DefendBtn
@onready var current_unit_label = $CurrentUnitDisplay/Label

var health_bar_scene = preload("res://scenes/ui/HealthBar.tscn")
var battle_manager: BattleManager

func _ready():
	attack_btn.pressed.connect(_on_attack_pressed)
	skills_btn.pressed.connect(_on_skills_pressed)
	items_btn.pressed.connect(_on_items_pressed)
	defend_btn.pressed.connect(_on_defend_pressed)
	
	action_menu.hide()

func setup(manager: BattleManager):
	battle_manager = manager
	battle_manager.unit_turn_started.connect(_on_unit_turn_started)
	battle_manager.health_changed.connect(_on_health_changed)

func create_health_bars(player_units: Array[Unit], enemy_units: Array[Unit]):
	# Clear existing bars
	for child in player_health_bars.get_children():
		child.queue_free()
	for child in enemy_health_bars.get_children():
		child.queue_free()
	
	# Create player health bars
	for unit in player_units:
		var bar = health_bar_scene.instantiate()
		player_health_bars.add_child(bar)
		bar.setup(unit)
	
	# Create enemy health bars
	for unit in enemy_units:
		var bar = health_bar_scene.instantiate()
		enemy_health_bars.add_child(bar)
		bar.setup(unit)

func _on_health_changed():
	# Update all health bars
	for bar in player_health_bars.get_children():
		bar.update_display()
	for bar in enemy_health_bars.get_children():
		bar.update_display()

func _on_unit_turn_started(unit: Unit):
	current_unit_label.text = "%s's Turn" % unit.unit_name
	action_menu.show()

func _on_attack_pressed():
	# TODO: Show target selection
	print("Attack selected")

func _on_skills_pressed():
	# TODO: Show skill menu
	print("Skills selected")

func _on_items_pressed():
	# TODO: Show item menu
	print("Items selected")

func _on_defend_pressed():
	if battle_manager and battle_manager.current_unit:
		battle_manager.defend(battle_manager.current_unit)
	action_menu.hide()
