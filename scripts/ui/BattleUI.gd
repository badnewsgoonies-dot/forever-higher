class_name BattleUI
extends CanvasLayer

signal action_selected(action: String, data)
signal target_selected(target: Unit)

@onready var action_menu = $ActionMenu
@onready var attack_btn = $ActionMenu/AttackBtn
@onready var spells_btn = $ActionMenu/SpellsBtn
@onready var items_btn = $ActionMenu/ItemsBtn
@onready var defend_btn = $ActionMenu/DefendBtn
@onready var current_unit_display = $CurrentUnitDisplay
@onready var turn_indicator = $TurnIndicator
@onready var enemy_health_bars = $TopBar/EnemyHealthBars
@onready var hero_health_bars = $TopBar/HeroHealthBars

var current_unit: Unit
var player_units: Array = []
var enemy_units: Array = []
var damage_number_scene = preload("res://scenes/ui/DamageNumber.tscn") if ResourceLoader.exists("res://scenes/ui/DamageNumber.tscn") else null

func _ready():
    # Connect button signals
    if attack_btn:
        attack_btn.pressed.connect(func(): _on_action_button_pressed("attack"))
    if spells_btn:
        spells_btn.pressed.connect(func(): _on_action_button_pressed("spells"))
    if items_btn:
        items_btn.pressed.connect(func(): _on_action_button_pressed("items"))
    if defend_btn:
        defend_btn.pressed.connect(func(): _on_action_button_pressed("defend"))
func setup_battle(heroes: Array, enemies: Array):
    player_units = heroes
    enemy_units = enemies
    
    # Create health bar displays for all units
    create_health_bars()
    update_health_bars()

func create_health_bars():
    # Clear existing bars
    if hero_health_bars:
        for child in hero_health_bars.get_children():
            child.queue_free()
    
    if enemy_health_bars:
        for child in enemy_health_bars.get_children():
            child.queue_free()
    
    # Create hero health bars
    for unit in player_units:
        var bar_container = create_unit_health_display(unit)
        if hero_health_bars:
            hero_health_bars.add_child(bar_container)
    
    # Create enemy health bars
    for unit in enemy_units:
        var bar_container = create_unit_health_display(unit)
        if enemy_health_bars:
            enemy_health_bars.add_child(bar_container)
func create_unit_health_display(unit: Unit) -> Control:
    var container = VBoxContainer.new()
    container.custom_minimum_size = Vector2(100, 40)
    
    # Name label
    var name_label = Label.new()
    name_label.text = unit.unit_name
    name_label.add_theme_font_size_override("font_size", 12)
    container.add_child(name_label)
    
    # HP Bar
    var hp_bar = ProgressBar.new()
    hp_bar.custom_minimum_size = Vector2(100, 12)
    hp_bar.max_value = unit.max_hp
    hp_bar.value = unit.current_hp
    hp_bar.show_percentage = false
    hp_bar.modulate = Color.RED
    container.add_child(hp_bar)
    
    # MP Bar
    var mp_bar = ProgressBar.new()
    mp_bar.custom_minimum_size = Vector2(100, 8)
    mp_bar.max_value = unit.max_mp
    mp_bar.value = unit.current_mp
    mp_bar.show_percentage = false
    mp_bar.modulate = Color.BLUE
    container.add_child(mp_bar)
    
    # Store reference to unit
    container.set_meta("unit", unit)
    container.set_meta("hp_bar", hp_bar)
    container.set_meta("mp_bar", mp_bar)    
    return container

func update_health_bars():
    # Update hero bars
    if hero_health_bars:
        for child in hero_health_bars.get_children():
            var unit = child.get_meta("unit")
            var hp_bar = child.get_meta("hp_bar")
            var mp_bar = child.get_meta("mp_bar")
            
            if unit and hp_bar:
                hp_bar.value = unit.current_hp
                hp_bar.max_value = unit.max_hp
            
            if unit and mp_bar:
                mp_bar.value = unit.current_mp
                mp_bar.max_value = unit.max_mp
            
            # Hide if dead
            child.modulate.a = 1.0 if unit.is_alive() else 0.3
    
    # Update enemy bars
    if enemy_health_bars:
        for child in enemy_health_bars.get_children():
            var unit = child.get_meta("unit")
            var hp_bar = child.get_meta("hp_bar")
            var mp_bar = child.get_meta("mp_bar")
            
            if unit and hp_bar:
                hp_bar.value = unit.current_hp                hp_bar.max_value = unit.max_hp
            
            if unit and mp_bar:
                mp_bar.value = unit.current_mp
                mp_bar.max_value = unit.max_mp
            
            # Hide if dead
            child.modulate.a = 1.0 if unit.is_alive() else 0.3

func show_action_menu(unit: Unit):
    current_unit = unit
    
    if action_menu:
        action_menu.visible = true
    
    # Update current unit display
    if current_unit_display:
        var label = current_unit_display.get_node_or_null("Label")
        if not label:
            label = Label.new()
            label.name = "Label"
            current_unit_display.add_child(label)
        label.text = "Current Unit's Turn: " + unit.unit_name
    
    # Enable/disable spell button based on available MP
    if spells_btn:
        spells_btn.disabled = unit.skills.is_empty() or unit.current_mp == 0

func hide_action_menu():
    if action_menu:
        action_menu.visible = false

func show_damage(target: Unit, amount: int):
    # Show floating damage number
    if not damage_number_scene:
        # Create simple damage display
        var label = Label.new()
        label.text = str(amount)
        label.modulate = Color.RED
        label.position = Vector2(500, 300)  # Center of screen roughly
        add_child(label)
        
        # Animate and remove
        var tween = create_tween()
        tween.tween_property(label, "position", label.position + Vector2(0, -50), 0.5)
        tween.parallel().tween_property(label, "modulate:a", 0, 0.5)
        tween.tween_callback(label.queue_free)

func show_heal(target: Unit, amount: int):
    # Show floating heal number
    var label = Label.new()
    label.text = "+" + str(amount)
    label.modulate = Color.GREEN
    label.position = Vector2(500, 300)
    add_child(label)
    
    # Animate and remove
    var tween = create_tween()
    tween.tween_property(label, "position", label.position + Vector2(0, -50), 0.5)
    tween.parallel().tween_property(label, "modulate:a", 0, 0.5)
    tween.tween_callback(label.queue_free)

func _on_action_button_pressed(action: String):
    match action:
        "attack":
            action_selected.emit("attack", null)
            # TODO: Show target selection
        "spells":
            # TODO: Show spell selection menu
            if current_unit and current_unit.skills.size() > 0:
                action_selected.emit("skill", current_unit.skills[0])
        "items":
            # TODO: Show item menu
            action_selected.emit("item", null)
        "defend":
            action_selected.emit("defend", null)
