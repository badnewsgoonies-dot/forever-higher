import Foundation
import SpriteKit

// MARK: - Test Battle Demo

class TestBattleDemo {
    
    static func runBasicUnitTests() {
        print("=== UNIT SYSTEM TESTS ===\n")
        
        // Test 1: Unit Creation
        print("1. Testing Unit Creation:")
        let warrior = UnitFactory.createWarrior(name: "Test Warrior")
        let mage = UnitFactory.createMage(name: "Test Mage")
        
        print("✓ Created Warrior: \(warrior.getStatusString())")
        print("✓ Created Mage: \(mage.getStatusString())")
        print()
        
        // Test 2: Basic Combat
        print("2. Testing Basic Combat:")
        let goblin = UnitFactory.createGoblin(name: "Test Goblin")
        print("Initial Goblin: \(goblin.getStatusString())")
        
        let damage = warrior.performBasicAttack(on: goblin)
        print("Warrior attacks for \(damage) damage")
        print("Goblin after attack: \(goblin.getStatusString())")
        print("Goblin is alive: \(goblin.isAlive())")
        print()
        
        // Test 3: Skill Usage
        print("3. Testing Skill Usage:")
        print("Mage MP before skill: \(mage.currentMP)")
        
        if let firebolt = mage.skills.first(where: { $0.skillName == "Firebolt" }) {
            let canUse = firebolt.canUse(by: mage)
            print("Can use Firebolt: \(canUse)")
            
            if canUse {
                let skillDamage = firebolt.getDamage(from: mage)
                print("Firebolt would deal \(skillDamage) damage")
                
                // Use the skill
                let success = mage.useSkill(firebolt, on: [goblin])
                print("Skill used successfully: \(success)")
                print("Mage MP after skill: \(mage.currentMP)")
                print("Goblin after Firebolt: \(goblin.getStatusString())")
            }
        }
        print()
        
        // Test 4: Healing
        print("4. Testing Healing:")
        let cleric = UnitFactory.createCleric(name: "Test Cleric")
        
        // Damage the warrior first
        warrior.takeDamage(50, damageType: .physical)
        print("Warrior after damage: \(warrior.getStatusString())")
        
        if let heal = cleric.skills.first(where: { $0.skillName == "Heal" }) {
            let healAmount = heal.getHealAmount(from: cleric)
            print("Heal would restore \(healAmount) HP")
            
            cleric.useSkill(heal, on: [warrior])
            print("Warrior after healing: \(warrior.getStatusString())")
        }
        print()
        
        // Test 5: Status Effects
        print("5. Testing Status Effects:")
        warrior.applyStatusEffect("poison", duration: 3)
        warrior.applyStatusEffect("blessed", duration: 2)
        
        print("Warrior status effects: \(warrior.statusEffects.map { "\($0.effect)(\($0.duration))" })")
        
        warrior.processStatusEffects()
        print("After processing (1 turn): \(warrior.statusEffects.map { "\($0.effect)(\($0.duration))" })")
        
        warrior.processStatusEffects()
        print("After processing (2 turns): \(warrior.statusEffects.map { "\($0.effect)(\($0.duration))" })")
        print()
        
        // Test 6: Unit Factory
        print("6. Testing Unit Factory:")
        let allClasses: [String] = ["warrior", "mage", "rogue", "cleric"]
        
        for className in allClasses {
            if let unit = GameData.shared.createUnit(from: className) {
                print("✓ Created \(className): \(unit.unitName) - Skills: \(unit.skills.count)")
            } else {
                print("✗ Failed to create \(className)")
            }
        }
        print()
        
        print("=== UNIT TESTS COMPLETE ===\n")
    }
    
    static func runBattleSystemTests() {
        print("=== BATTLE SYSTEM TESTS ===\n")
        
        // Create test teams
        let playerTeam = [
            UnitFactory.createWarrior(name: "Hero Warrior"),
            UnitFactory.createMage(name: "Hero Mage")
        ]
        
        let enemyTeam = [
            UnitFactory.createGoblin(name: "Enemy Goblin"),
            UnitFactory.createOrc(name: "Enemy Orc")
        ]
        
        print("Player Team:")
        for unit in playerTeam {
            print("  - \(unit.getStatusString())")
        }
        
        print("\nEnemy Team:")
        for unit in enemyTeam {
            print("  - \(unit.getStatusString())")
        }
        print()
        
        // Create battle manager
        let battleManager = BattleManager()
        let testDelegate = TestBattleDelegate()
        battleManager.delegate = testDelegate
        
        // Start battle
        print("Starting battle simulation...")
        battleManager.startBattle(playerTeam: playerTeam, enemyTeam: enemyTeam)
        
        // Simulate some player actions
        print("\n--- Simulating Player Actions ---")
        
        // Player 1 attacks
        if let target = battleManager.getAliveEnemyUnits().first {
            let action = BattleAction.attack(target: target)
            battleManager.processPlayerAction(action)
        }
        
        // Player 2 uses skill
        if let caster = battleManager.getAlivePlayerUnits().last,
           let skill = caster.skills.first,
           let target = battleManager.getAliveEnemyUnits().first {
            let action = BattleAction.skill(skill: skill, targets: [target])
            battleManager.processPlayerAction(action)
        }
        
        print("\n=== BATTLE SYSTEM TESTS COMPLETE ===\n")
    }
    
    static func runGameDataTests() {
        print("=== GAME DATA TESTS ===\n")
        
        let gameData = GameData.shared
        
        // Test unit creation from templates
        print("1. Testing Unit Template System:")
        let templateIds = ["warrior", "mage", "rogue", "cleric", "goblin", "orc"]
        
        for templateId in templateIds {
            if let unit = gameData.createUnit(from: templateId) {
                print("✓ \(templateId): \(unit.unitName) (HP: \(unit.maxHP), Skills: \(unit.skills.count))")
            } else {
                print("✗ Failed to create unit from template: \(templateId)")
            }
        }
        print()
        
        // Test skill creation
        print("2. Testing Skill Template System:")
        let skillIds = ["firebolt", "heal", "power_strike", "backstab"]
        
        for skillId in skillIds {
            if let skill = gameData.createSkill(from: skillId) {
                print("✓ \(skillId): \(skill.skillName) (MP: \(skill.mpCost), Power: \(skill.power))")
            } else {
                print("✗ Failed to create skill from template: \(skillId)")
            }
        }
        print()
        
        // Test meta progression
        print("3. Testing Meta Progression:")
        print("Current level: \(gameData.metaProgression.level)")
        print("Current EXP: \(gameData.metaProgression.totalExp)")
        
        gameData.addMetaExp(150)
        print("After adding 150 EXP:")
        print("New level: \(gameData.metaProgression.level)")
        print("New EXP: \(gameData.metaProgression.totalExp)")
        print()
        
        // Test run data
        print("4. Testing Run Data:")
        print("Current run active: \(gameData.currentRunData.isActive)")
        
        gameData.currentRunData.startNewRun(with: ["warrior", "mage"])
        print("Started new run with: \(gameData.currentRunData.playerUnits)")
        print("Run is now active: \(gameData.currentRunData.isActive)")
        print()
        
        print("=== GAME DATA TESTS COMPLETE ===\n")
    }
    
    static func runAllTests() {
        print("🎮 FOREVER HIGHER - UNIT SYSTEM TESTS 🎮\n")
        print("Testing the foundational systems for the roguelike JRPG\n")
        
        runBasicUnitTests()
        runGameDataTests()
        runBattleSystemTests()
        
        print("🎉 ALL TESTS COMPLETE! 🎉")
        print("The Unit class foundation is ready for your roguelike JRPG!")
        print("\nNext steps:")
        print("1. Copy these Swift files to your Swift Playgrounds project")
        print("2. Test the basic functionality")
        print("3. Add SpriteKit scene integration")
        print("4. Build the UI system")
        print("5. Add the map/progression system")
    }
}

// MARK: - Test Battle Delegate

class TestBattleDelegate: BattleManagerDelegate {
    
    func battleStarted(playerUnits: [Unit], enemyUnits: [Unit]) {
        print("🔥 Battle Started!")
        print("Player units: \(playerUnits.map { $0.unitName })")
        print("Enemy units: \(enemyUnits.map { $0.unitName })")
    }
    
    func phaseChanged(isPlayerPhase: Bool) {
        print(isPlayerPhase ? "⚔️ Player Phase" : "👹 Enemy Phase")
    }
    
    func unitTurnStarted(unit: Unit, isPlayer: Bool) {
        let icon = isPlayer ? "🛡️" : "⚔️"
        print("\(icon) \(unit.unitName)'s turn - HP: \(unit.currentHP)/\(unit.maxHP), MP: \(unit.currentMP)/\(unit.maxMP)")
    }
    
    func damageDealt(target: Unit, amount: Int, damageType: DamageType) {
        print("💥 \(target.unitName) takes \(amount) \(damageType.rawValue) damage! (HP: \(target.currentHP)/\(target.maxHP))")
    }
    
    func healingDone(target: Unit, amount: Int) {
        print("💚 \(target.unitName) healed for \(amount) HP! (HP: \(target.currentHP)/\(target.maxHP))")
    }
    
    func mpRestored(target: Unit, amount: Int) {
        print("💙 \(target.unitName) restored \(amount) MP! (MP: \(target.currentMP)/\(target.maxMP))")
    }
    
    func skillUsed(caster: Unit, skill: Skill, targets: [Unit]) {
        let targetNames = targets.map { $0.unitName }.joined(separator: ", ")
        print("✨ \(caster.unitName) uses \(skill.skillName) on \(targetNames)")
    }
    
    func statusEffectApplied(target: Unit, effect: String, duration: Int) {
        print("🌟 \(target.unitName) is affected by \(effect) for \(duration) turns")
    }
    
    func unitDefended(unit: Unit) {
        print("🛡️ \(unit.unitName) defends (damage reduced next turn)")
    }
    
    func unitDefeated(unit: Unit) {
        print("💀 \(unit.unitName) is defeated!")
    }
    
    func actionFailed(reason: String) {
        print("❌ Action failed: \(reason)")
    }
    
    func battleEnded(victory: Bool, rewards: BattleRewards) {
        if victory {
            print("🎉 VICTORY!")
            print("Rewards: \(rewards.exp) EXP, \(rewards.gold) Gold")
        } else {
            print("💀 DEFEAT!")
            print("Better luck next time...")
        }
    }
}

// MARK: - Demo Scene for Swift Playgrounds

class DemoScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Add title
        let titleLabel = SKLabelNode(text: "Forever Higher - Unit System Demo")
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width/2, y: size.height - 50)
        addChild(titleLabel)
        
        // Add instruction
        let instructionLabel = SKLabelNode(text: "Tap to run tests")
        instructionLabel.fontSize = 16
        instructionLabel.fontColor = .lightGray
        instructionLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(instructionLabel)
        
        // Add unit display
        displaySampleUnits()
    }
    
    private func displaySampleUnits() {
        let units = [
            UnitFactory.createWarrior(),
            UnitFactory.createMage(),
            UnitFactory.createRogue(),
            UnitFactory.createCleric()
        ]
        
        let startX = size.width * 0.2
        let spacing = size.width * 0.6 / CGFloat(units.count - 1)
        
        for (index, unit) in units.enumerated() {
            let x = startX + CGFloat(index) * spacing
            let y = size.height * 0.3
            
            // Unit sprite
            let unitNode = SKSpriteNode(color: .blue, size: CGSize(width: 40, height: 60))
            unitNode.position = CGPoint(x: x, y: y)
            addChild(unitNode)
            
            // Unit name
            let nameLabel = SKLabelNode(text: unit.unitName)
            nameLabel.fontSize = 12
            nameLabel.fontColor = .white
            nameLabel.position = CGPoint(x: x, y: y - 50)
            addChild(nameLabel)
            
            // Unit stats
            let statsLabel = SKLabelNode(text: "HP:\(unit.maxHP) MP:\(unit.maxMP)")
            statsLabel.fontSize = 10
            statsLabel.fontColor = .lightGray
            statsLabel.position = CGPoint(x: x, y: y - 65)
            addChild(statsLabel)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Run tests when screen is tapped
        TestBattleDemo.runAllTests()
        
        // Add visual feedback
        let flashNode = SKSpriteNode(color: .white, size: size)
        flashNode.alpha = 0.3
        flashNode.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(flashNode)
        
        let fadeAction = SKAction.fadeOut(withDuration: 0.5)
        let removeAction = SKAction.removeFromParent()
        flashNode.run(SKAction.sequence([fadeAction, removeAction]))
        
        // Update instruction
        if let instruction = childNode(withName: "//instruction") as? SKLabelNode {
            instruction.text = "Tests running - check console output"
        }
    }
}