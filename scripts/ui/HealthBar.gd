class_name HealthBar
extends Control

@onready var hp_bar: ProgressBar = $VBoxContainer/HPBar
@onready var mp_bar: ProgressBar = $VBoxContainer/MPBar
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var hp_label: Label = $VBoxContainer/HPBar/HPLabel
@onready var mp_label: Label = $VBoxContainer/MPBar/MPLabel

var unit: Unit

func setup(unit_data: Unit):
	unit = unit_data
	update_display()

func update_display():
	if not unit:
		return
	
	name_label.text = unit.unit_name
	
	hp_bar.max_value = unit.max_hp
	hp_bar.value = unit.current_hp
	hp_label.text = "%d/%d" % [unit.current_hp, unit.max_hp]
	
	mp_bar.max_value = unit.max_mp
	mp_bar.value = unit.current_mp
	mp_label.text = "%d/%d" % [unit.current_mp, unit.max_mp]
	
	# Color coding for low health
	if unit.current_hp <= unit.max_hp * 0.25:
		hp_bar.modulate = Color.RED
	elif unit.current_hp <= unit.max_hp * 0.5:
		hp_bar.modulate = Color.YELLOW
	else:
		hp_bar.modulate = Color.GREEN
