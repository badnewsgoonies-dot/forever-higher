class_name UnitSprite
extends Node2D

@export var unit_data: Unit
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_highlighted: bool = false

func _ready():
	if unit_data and unit_data.sprite:
		sprite.texture = unit_data.sprite

func setup(unit: Unit):
	unit_data = unit
	if sprite and unit.sprite:
		sprite.texture = unit.sprite

func highlight():
	is_highlighted = true
	# Add visual feedback (e.g., shader, scale, etc.)
	scale = Vector2(1.1, 1.1)

func unhighlight():
	is_highlighted = false
	scale = Vector2(1.0, 1.0)

func play_attack_animation():
	if animation_player.has_animation("attack"):
		animation_player.play("attack")

func play_hurt_animation():
	if animation_player.has_animation("hurt"):
		animation_player.play("hurt")

func play_death_animation():
	if animation_player.has_animation("death"):
		animation_player.play("death")
	else:
		# Simple fade out
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.5)
