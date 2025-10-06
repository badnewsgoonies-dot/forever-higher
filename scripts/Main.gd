extends Node2D

var test_battle_scene = preload("res://scenes/battle/TestBattle.tscn") if ResourceLoader.exists("res://scenes/battle/TestBattle.tscn") else null

func _ready():
    print("Forever Higher - Main Menu")
    create_main_menu()

func create_main_menu():
    # Create a simple menu
    var menu_container = VBoxContainer.new()
    menu_container.position = Vector2(500, 300)
    menu_container.add_theme_constant_override("separation", 20)
    add_child(menu_container)
    
    # Title
    var title = Label.new()
    title.text = "FOREVER HIGHER"
    title.add_theme_font_size_override("font_size", 48)
    menu_container.add_child(title)
    
    # Start Run button
    var start_btn = Button.new()
    start_btn.text = "Start New Run"
    start_btn.custom_minimum_size = Vector2(200, 50)
    start_btn.pressed.connect(_on_start_pressed)
    menu_container.add_child(start_btn)
    
    # Test Battle button
    var test_btn = Button.new()
    test_btn.text = "Test Battle"
    test_btn.custom_minimum_size = Vector2(200, 50)
    test_btn.pressed.connect(_on_test_battle_pressed)
    menu_container.add_child(test_btn)
    
    # Continue button (if save exists)
    if FileAccess.file_exists("user://savegame.dat"):
        var continue_btn = Button.new()
        continue_btn.text = "Continue Run"
        continue_btn.custom_minimum_size = Vector2(200, 50)
        continue_btn.pressed.connect(_on_continue_pressed)
        menu_container.add_child(continue_btn)
    
    # Meta Upgrades button
    var upgrades_btn = Button.new()
    upgrades_btn.text = "Meta Upgrades"
    upgrades_btn.custom_minimum_size = Vector2(200, 50)
    upgrades_btn.pressed.connect(_on_upgrades_pressed)
    menu_container.add_child(upgrades_btn)
    
    # Stats display
    var stats_label = Label.new()
    stats_label.text = "Total Runs: %d | Best Floor: %d | Total EXP: %d" % [
        GameData.meta_progression.total_runs,
        GameData.meta_progression.best_floor,
        GameData.meta_progression.total_exp
    ]
    stats_label.add_theme_font_size_override("font_size", 16)
    menu_container.add_child(stats_label)
    
    # Exit button
    var exit_btn = Button.new()
    exit_btn.text = "Exit Game"
    exit_btn.custom_minimum_size = Vector2(200, 50)
    exit_btn.pressed.connect(func(): get_tree().quit())
    menu_container.add_child(exit_btn)

func _on_start_pressed():
    print("Starting new run...")
    GameData.reset_run_data()
    # TODO: Show hero selection screen
    _start_test_battle()  # For now, go straight to battle

func _on_continue_pressed():
    print("Continuing run...")
    # TODO: Load saved run state
    _start_test_battle()

func _on_test_battle_pressed():
    print("Starting test battle...")
    _start_test_battle()

func _on_upgrades_pressed():
    print("Opening meta upgrades...")
    # TODO: Create meta upgrade screen
    
func _start_test_battle():
    if test_battle_scene:
        get_tree().change_scene_to_packed(test_battle_scene)
    else:
        # Create test battle scene manually if it doesn't exist
        var test_scene = Node2D.new()
        var script = load("res://scripts/TestBattle.gd")
        test_scene.set_script(script)
        get_tree().root.add_child(test_scene)
        queue_free()
