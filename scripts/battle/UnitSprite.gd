class_name UnitSprite
extends Node2D

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar
@onready var mp_bar = $MPBar
@onready var selection_indicator = $SelectionIndicator
@onready var status_icons = $StatusIcons

var unit: Unit
var is_player_unit: bool = true
var original_position: Vector2
var highlight_active: bool = false

# Colors for placeholder sprites
const PLAYER_COLOR = Color(0.2, 0.4, 0.8, 1.0)  # Blue
const ENEMY_COLOR = Color(0.8, 0.2, 0.2, 1.0)   # Red
const HIGHLIGHT_COLOR = Color(1.0, 1.0, 0.2, 1.0)  # Yellow

func _ready():
    original_position = position
    
    # Create placeholder sprite if it doesn't exist
    if not sprite:
        sprite = Sprite2D.new()
        add_child(sprite)
        
    # Create placeholder health bar
    if not health_bar:
        health_bar = ProgressBar.new()
        health_bar.size = Vector2(60, 8)
        health_bar.position = Vector2(-30, -50)
        health_bar.modulate = Color.RED
        add_child(health_bar)    
    # Create placeholder MP bar
    if not mp_bar:
        mp_bar = ProgressBar.new()
        mp_bar.size = Vector2(60, 6)
        mp_bar.position = Vector2(-30, -40)
        mp_bar.modulate = Color.BLUE
        add_child(mp_bar)

func setup(unit_data: Unit, is_player: bool):
    unit = unit_data
    is_player_unit = is_player
    
    # Create placeholder texture if no sprite specified
    if unit.sprite_path == "" or not ResourceLoader.exists(unit.sprite_path):
        create_placeholder_sprite()
    else:
        sprite.texture = load(unit.sprite_path)
    
    # Set initial values
    update_display()
    
    # Flip enemy sprites to face left
    if not is_player_unit:
        scale.x = -1

func create_placeholder_sprite():
    # Create a colored square as placeholder
    var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
    var color = PLAYER_COLOR if is_player_unit else ENEMY_COLOR
    image.fill(color)    
    # Add unit class initial to the square
    var font = ThemeDB.fallback_font
    var text_color = Color.WHITE
    var initial = unit.unit_name.substr(0, 1).to_upper()
    
    # Draw the initial (simplified approach - just use the colored square for now)
    var texture = ImageTexture.create_from_image(image)
    sprite.texture = texture

func update_display():
    if not unit:
        return
    
    # Update health bar
    if health_bar:
        health_bar.max_value = unit.max_hp
        health_bar.value = unit.current_hp
    
    # Update MP bar
    if mp_bar:
        mp_bar.max_value = unit.max_mp
        mp_bar.value = unit.current_mp
    
    # Update visibility based on alive status
    visible = unit.is_alive()

func set_highlight(active: bool):
    highlight_active = active
    
    if active:
        modulate = HIGHLIGHT_COLOR
    else:
        modulate = Color.WHITE

# Animation functions
func play_attack_animation():
    var tween = create_tween()
    var target_pos = original_position + Vector2(30 if is_player_unit else -30, 0)
    
    tween.tween_property(self, "position", target_pos, 0.2)
    tween.tween_property(self, "position", original_position, 0.2)

func play_skill_animation(skill_name: String):
    # Basic skill animation - shake and flash
    var tween = create_tween()
    
    tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.1)
    tween.tween_property(self, "modulate", Color.WHITE, 0.1)
    
    # Add shake
    for i in range(3):
        tween.tween_property(self, "position", original_position + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
    tween.tween_property(self, "position", original_position, 0.05)

func play_hurt_animation():
    var tween = create_tween()
    
    # Flash red and shake
    tween.tween_property(self, "modulate", Color.RED, 0.1)
    tween.tween_property(self, "position", original_position + Vector2(-10, 0), 0.1)
    tween.tween_property(self, "modulate", Color.WHITE, 0.1)
    tween.tween_property(self, "position", original_position, 0.1)

func play_defend_animation():
    var tween = create_tween()
    
    # Move back slightly and add shield effect
    tween.tween_property(self, "position", original_position + Vector2(-10 if is_player_unit else 10, 0), 0.2)
    tween.tween_property(self, "modulate", Color(0.5, 0.5, 1.0, 1.0), 0.1)

func play_death_animation():
    var tween = create_tween()
    
    tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
    tween.tween_property(self, "scale", Vector2(0, 0), 0.5)
    tween.tween_callback(queue_free)
