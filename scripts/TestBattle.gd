extends Node2D

@onready var battle_manager = $BattleManager

func _ready():
    print("Starting test battle...")
    setup_test_battle()

func setup_test_battle():
    # Create test heroes
    var heroes = []
    
    # Warrior
    var warrior = Unit.new()
    warrior.unit_name = "Warrior"
    warrior.unit_class = GameData.UnitClass.WARRIOR
    warrior.max_hp = 120
    warrior.max_mp = 20
    warrior.attack = 15
    warrior.defense = 8
    warrior.magic = 3
    warrior.speed = 5
    warrior.skills = []
    heroes.append(warrior)
    
    # Mage
    var mage = Unit.new()
    mage.unit_name = "Mage"
    mage.unit_class = GameData.UnitClass.MAGE
    mage.max_hp = 80
    mage.max_mp = 50    mage.attack = 5
    mage.defense = 3
    mage.magic = 15
    mage.speed = 7
    
    # Create Fireball skill for mage
    var fireball = Skill.new()
    fireball.skill_name = "Fireball"
    fireball.description = "Deals fire damage to one enemy"
    fireball.mp_cost = 5
    fireball.power = 25
    fireball.damage_type = GameData.DamageType.MAGICAL
    fireball.target_type = GameData.TargetType.SINGLE_ENEMY
    mage.skills = [fireball]
    heroes.append(mage)
    
    # Healer
    var healer = Unit.new()
    healer.unit_name = "Healer"
    healer.unit_class = GameData.UnitClass.HEALER
    healer.max_hp = 90
    healer.max_mp = 40
    healer.attack = 4
    healer.defense = 5
    healer.magic = 12
    healer.speed = 6
    
    # Create Heal skill for healer
    var heal_skill = Skill.new()
    heal_skill.skill_name = "Heal"
    heal_skill.description = "Restores HP to one ally"    heal_skill.mp_cost = 4
    heal_skill.power = 0
    heal_skill.heal_power = 30
    heal_skill.damage_type = GameData.DamageType.MAGICAL
    heal_skill.target_type = GameData.TargetType.SINGLE_ALLY
    healer.skills = [heal_skill]
    heroes.append(healer)
    
    # Create test enemies
    var enemies = []
    
    # Goblin 1
    var goblin1 = Unit.new()
    goblin1.unit_name = "Goblin A"
    goblin1.unit_class = GameData.UnitClass.WARRIOR
    goblin1.max_hp = 60
    goblin1.max_mp = 10
    goblin1.attack = 8
    goblin1.defense = 3
    goblin1.magic = 2
    goblin1.speed = 8
    enemies.append(goblin1)
    
    # Goblin 2
    var goblin2 = Unit.new()
    goblin2.unit_name = "Goblin B"
    goblin2.unit_class = GameData.UnitClass.WARRIOR
    goblin2.max_hp = 60
    goblin2.max_mp = 10
    goblin2.attack = 8
    goblin2.defense = 3
    goblin2.magic = 2
    goblin2.speed = 8
    enemies.append(goblin2)
    
    # Start the battle
    if battle_manager:
        battle_manager.battle_ended.connect(_on_battle_ended)
        battle_manager.start_battle(heroes, enemies)
    else:
        print("Error: BattleManager not found!")

func _on_battle_ended(victory: bool, rewards: Dictionary):
    print("Battle ended! Victory: ", victory)
    print("Rewards: ", rewards)
    
    # Return to main menu or show rewards screen
    await get_tree().create_timer(2.0).timeout
    get_tree().change_scene_to_file("res://Main.tscn")
