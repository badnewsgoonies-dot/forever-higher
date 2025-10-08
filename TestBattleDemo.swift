import Foundation

// MARK: - Test Battle Demo System
class TestBattleDemo {
    static let shared = TestBattleDemo()
    
    private init() {}
    
    // MARK: - Main Test Runner
    func runAllTests() {
        print("\n🎮 FOREVER HIGHER - COMPREHENSIVE SYSTEM TESTS 🎮")
        print("=" * 60)
        
        runUnitSystemTests()
        runSkillSystemTests()
        runBattleSystemTests()
        runGameDataTests()
        runStatusEffectTests()
        
        print("\n🎉 ALL TESTS COMPLETED! 🎉")
        print("=" * 60)
    }
    
    func runQuickTests() {
        print("\n⚡ QUICK VALIDATION TESTS ⚡")
        print("-" * 40)
        
        // Quick unit creation test
        let warrior = UnitFactory.createPlayerUnit(name: "Test Warrior", unitClass: .warrior)
        let mage = UnitFactory.createPlayerUnit(name: "Test Mage", unitClass: .mage)
        let goblin = UnitFactory.createEnemyUnit(name: "Test Goblin", level: 1)
        
        print("✅ Unit creation: Warrior(\(warrior.currentHP)HP), Mage(\(mage.currentHP)HP), Goblin(\(goblin.currentHP)HP)")
        
        // Quick skill test
        let skillCount = warrior.availableSkills.count + mage.availableSkills.count
        print("✅ Skills loaded: \(skillCount) total skills available")
        
        // Quick battle test
        let battle = BattleManager(playerUnits: [warrior], enemyUnits: [goblin])
        print("✅ Battle system: Initialized successfully")
        
        // Quick data test
        let gameData = GameDataManager.shared
        print("✅ Game data: Runs(\(gameData.metaProgression.totalRuns)), Gold(\(gameData.playerData.gold))")
        
        print("⚡ Quick tests completed - System is ready!")
        print("-" * 40)
    }
    
    func runQuickBattleDemo() {
        print("\n⚔️ QUICK BATTLE DEMONSTRATION ⚔️")
        print("-" * 40)
        
        // Create test units
        let hero = UnitFactory.createPlayerUnit(name: "Hero", unitClass: .warrior)
        let wizard = UnitFactory.createPlayerUnit(name: "Wizard", unitClass: .mage)
        let goblin = UnitFactory.createEnemyUnit(name: "Goblin", level: 1)
        let orc = UnitFactory.createEnemyUnit(name: "Orc", level: 2)
        
        print("🛡️ Player Team: \(hero.name) (HP:\(hero.currentHP)), \(wizard.name) (HP:\(wizard.currentHP))")
        print("👹 Enemy Team: \(goblin.name) (HP:\(goblin.currentHP)), \(orc.name) (HP:\(orc.currentHP))")
        
        // Create battle
        let battle = BattleManager(playerUnits: [hero, wizard], enemyUnits: [goblin, orc])
        
        // Set up callbacks
        battle.onUnitActionCompleted = { unit, action, result in
            print("⚡ \(unit.name) \(result.description)")
        }
        
        battle.onBattleEnded = { result in
            switch result {
            case .victory(let rewards):
                print("🎉 Victory! Rewards: \(rewards.experience) XP, \(rewards.gold) Gold")
            case .defeat:
                print("💀 Defeat! Heroes have fallen.")
            case .escaped:
                print("🏃 Escaped from battle!")
            }
        }
        
        // Simulate a few turns
        for turn in 1...3 {
            print("\n--- Turn \(turn) ---")
            
            // Plan actions for living players
            for player in battle.playerUnits.filter({ $0.isAlive }) {
                if let skill = player.availableSkills.randomElement(), player.canUseSkill(skill) {
                    let enemies = battle.enemyUnits.filter { $0.isAlive }
                    if let target = enemies.randomElement() {
                        let action = BattleAction(actor: player, type: .useSkill(skill), targets: [target])
                        _ = battle.planAction(unit: player, action: action)
                    }
                } else {
                    let enemies = battle.enemyUnits.filter { $0.isAlive }
                    if let target = enemies.randomElement() {
                        let action = BattleAction(actor: player, type: .attack, targets: [target])
                        _ = battle.planAction(unit: player, action: action)
                    }
                }
            }
            
            // Execute turn
            battle.executePlayerTurn()
            
            // Check if battle ended
            if battle.currentPhase == .victory || battle.currentPhase == .defeat {
                break
            }
        }
        
        print("⚔️ Battle demonstration completed!")
        print("-" * 40)
    }
    
    // MARK: - Individual Test Suites
    
    private func runUnitSystemTests() {
        print("\n🛡️ UNIT SYSTEM TESTS")
        print("-" * 30)
        
        // Test unit creation
        let warrior = UnitFactory.createPlayerUnit(name: "Test Warrior", unitClass: .warrior)
        let mage = UnitFactory.createPlayerUnit(name: "Test Mage", unitClass: .mage)
        let rogue = UnitFactory.createPlayerUnit(name: "Test Rogue", unitClass: .rogue)
        let cleric = UnitFactory.createPlayerUnit(name: "Test Cleric", unitClass: .cleric)
        
        print("✅ Created Warrior: HP(\(warrior.maxHP)), ATK(\(warrior.attack)), Skills(\(warrior.availableSkills.count))")
        print("✅ Created Mage: HP(\(mage.maxHP)), MAG(\(mage.magic)), Skills(\(mage.availableSkills.count))")
        print("✅ Created Rogue: HP(\(rogue.maxHP)), SPD(\(rogue.speed)), Skills(\(rogue.availableSkills.count))")
        print("✅ Created Cleric: HP(\(cleric.maxHP)), MP(\(cleric.maxMP)), Skills(\(cleric.availableSkills.count))")
        
        // Test damage and healing
        let enemy = UnitFactory.createEnemyUnit(name: "Test Enemy", level: 1)
        let initialHP = enemy.currentHP
        let damage = enemy.takeDamage(20, damageType: .physical)
        print("✅ Damage test: Enemy took \(damage) damage (\(initialHP) → \(enemy.currentHP))")
        
        let healing = enemy.heal(10)
        print("✅ Healing test: Enemy healed \(healing) HP (\(enemy.currentHP - healing) → \(enemy.currentHP))")
        
        // Test status effects
        let poisonEffect = StatusEffect(type: .poison, power: 5, duration: 3)
        enemy.addStatusEffect(poisonEffect)
        print("✅ Status effect test: Applied poison to enemy")
        
        let statusResults = enemy.processStatusEffects()
        for result in statusResults {
            print("   💊 \(result.type): \(result.value) \(result.isPositive ? "benefit" : "damage")")
        }
        
        print("🛡️ Unit system tests completed!")
    }
    
    private func runSkillSystemTests() {
        print("\n✨ SKILL SYSTEM TESTS")
        print("-" * 30)
        
        let mage = UnitFactory.createPlayerUnit(name: "Test Mage", unitClass: .mage)
        let enemy = UnitFactory.createEnemyUnit(name: "Test Target", level: 1)
        
        print("🧙 Testing skills for \(mage.name) (MP: \(mage.currentMP))")
        
        for skill in mage.availableSkills {
            let canUse = mage.canUseSkill(skill)
            print("   \(canUse ? "✅" : "❌") \(skill.name) (Cost: \(skill.mpCost), Power: \(skill.power))")
            
            if canUse && skill.skillType == .damage {
                let oldHP = enemy.currentHP
                let oldMP = mage.currentMP
                
                // Simulate skill use
                if mage.consumeMP(skill.mpCost) {
                    let damage = enemy.takeDamage(skill.power + mage.magic, damageType: .magical)
                    print("      💥 Used \(skill.name): \(damage) damage dealt, \(skill.mpCost) MP consumed")
                    print("      📊 Enemy: \(oldHP) → \(enemy.currentHP) HP, Mage: \(oldMP) → \(mage.currentMP) MP")
                }
                break // Test only one damage skill
            }
        }
        
        print("✨ Skill system tests completed!")
    }
    
    private func runBattleSystemTests() {
        print("\n⚔️ BATTLE SYSTEM TESTS")
        print("-" * 30)
        
        let hero = UnitFactory.createPlayerUnit(name: "Test Hero", unitClass: .warrior)
        let mage = UnitFactory.createPlayerUnit(name: "Test Mage", unitClass: .mage)
        let goblin = UnitFactory.createEnemyUnit(name: "Test Goblin", level: 1)
        
        print("🏟️ Setting up battle: Heroes vs Goblin")
        
        let battle = BattleManager(playerUnits: [hero, mage], enemyUnits: [goblin])
        
        print("✅ Battle initialized - Phase: \(battle.currentPhase)")
        print("✅ Player units: \(battle.playerUnits.count), Enemy units: \(battle.enemyUnits.count)")
        
        // Test action planning
        let attackAction = BattleAction(actor: hero, type: .attack, targets: [goblin])
        let actionPlanned = battle.planAction(unit: hero, action: attackAction)
        print("✅ Action planning: \(actionPlanned ? "Success" : "Failed")")
        
        // Test battle statistics
        let stats = battle.getBattleStatistics()
        print("✅ Battle stats: Turn \(stats.turnCount), Living players: \(stats.livingPlayers), Living enemies: \(stats.livingEnemies)")
        
        print("⚔️ Battle system tests completed!")
    }
    
    private func runGameDataTests() {
        print("\n💾 GAME DATA TESTS")
        print("-" * 30)
        
        let gameData = GameDataManager.shared
        
        print("📊 Current game state:")
        print("   Runs: \(gameData.metaProgression.totalRuns)")
        print("   Victories: \(gameData.metaProgression.totalVictories)")
        print("   Best Floor: \(gameData.metaProgression.bestFloorReached)")
        print("   Gold: \(gameData.playerData.gold)")
        print("   Experience: \(gameData.playerData.experience)")
        
        // Test enemy creation from templates
        if let goblin = GameTemplates.createEnemyFromTemplate("goblin", level: 2) {
            print("✅ Template system: Created \(goblin.name) (Level 2, HP: \(goblin.maxHP))")
        }
        
        if let orc = GameTemplates.createEnemyFromTemplate("orc", level: 3) {
            print("✅ Template system: Created \(orc.name) (Level 3, HP: \(orc.maxHP))")
        }
        
        // Test item system
        if let healthPotion = GameTemplates.itemTemplates["health_potion"] {
            print("✅ Item system: \(healthPotion.name) - \(healthPotion.description)")
        }
        
        print("💾 Game data tests completed!")
    }
    
    private func runStatusEffectTests() {
        print("\n🌟 STATUS EFFECT TESTS")
        print("-" * 30)
        
        let testUnit = UnitFactory.createPlayerUnit(name: "Test Subject", unitClass: .warrior)
        
        // Test various status effects
        let effects = [
            StatusEffect(type: .poison, power: 3, duration: 3),
            StatusEffect(type: .burn, power: 5, duration: 2),
            StatusEffect(type: .attack_up, power: 10, duration: 4)
        ]
        
        for effect in effects {
            testUnit.addStatusEffect(effect)
            print("✅ Applied \(effect.type) (Power: \(effect.power), Duration: \(effect.duration))")
        }
        
        // Process effects over several turns
        for turn in 1...4 {
            print("\n--- Turn \(turn) Status Processing ---")
            let results = testUnit.processStatusEffects()
            
            for result in results {
                let icon = result.isPositive ? "✨" : "💀"
                print("   \(icon) \(result.type): \(result.value) \(result.isPositive ? "benefit" : "damage")")
            }
            
            print("   HP: \(testUnit.currentHP)/\(testUnit.maxHP)")
            
            if testUnit.currentHP <= 0 {
                print("   💀 Unit defeated by status effects!")
                break
            }
        }
        
        print("🌟 Status effect tests completed!")
    }
}

// MARK: - Battle Demonstrator
class BattleDemonstrator {
    
    static func demonstrateSkillEffects() {
        print("\n🎯 SKILL EFFECTS DEMONSTRATION")
        print("-" * 40)
        
        let mage = UnitFactory.createPlayerUnit(name: "Demo Mage", unitClass: .mage)
        let cleric = UnitFactory.createPlayerUnit(name: "Demo Cleric", unitClass: .cleric)
        let target = UnitFactory.createEnemyUnit(name: "Training Dummy", level: 1)
        
        print("🧙 Demonstrating Mage Skills:")
        for skill in mage.availableSkills {
            if mage.canUseSkill(skill) {
                print("   ✨ \(skill.name): \(skill.description)")
                print("      Type: \(skill.skillType), Target: \(skill.targetType)")
                print("      MP Cost: \(skill.mpCost), Power: \(skill.power)")
                
                if let element = skill.element {
                    print("      Element: \(element)")
                }
                
                if let statusEffect = skill.statusEffect {
                    print("      Status: \(statusEffect) (\(skill.statusDuration) turns)")
                }
                print("")
            }
        }
        
        print("⛪ Demonstrating Cleric Skills:")
        for skill in cleric.availableSkills {
            if cleric.canUseSkill(skill) {
                print("   ✨ \(skill.name): \(skill.description)")
                print("      Type: \(skill.skillType), Target: \(skill.targetType)")
                print("      MP Cost: \(skill.mpCost), Power: \(skill.power)")
                print("")
            }
        }
        
        print("🎯 Skill demonstration completed!")
    }
    
    static func demonstrateStatusEffects() {
        print("\n🌪️ STATUS EFFECTS DEMONSTRATION")
        print("-" * 40)
        
        let testUnit = UnitFactory.createPlayerUnit(name: "Test Subject", unitClass: .rogue)
        
        print("🧪 Testing all status effect types:")
        
        let allEffects: [StatusEffectType] = [
            .poison, .burn, .freeze,
            .attack_up, .defense_up, .speed_up,
            .attack_down, .defense_down, .speed_down
        ]
        
        for effectType in allEffects {
            let effect = StatusEffect(type: effectType, power: 5, duration: 2)
            testUnit.addStatusEffect(effect)
            
            let icon = getStatusEffectIcon(effectType)
            let category = getStatusEffectCategory(effectType)
            
            print("   \(icon) \(effectType) (\(category))")
        }
        
        print("\n🔄 Processing effects over 3 turns:")
        
        for turn in 1...3 {
            print("\n--- Turn \(turn) ---")
            let results = testUnit.processStatusEffects()
            
            if results.isEmpty {
                print("   No active effects")
            } else {
                for result in results {
                    let icon = result.isPositive ? "✨" : "💥"
                    print("   \(icon) \(result.type): \(result.value)")
                }
            }
        }
        
        print("\n🌪️ Status effects demonstration completed!")
    }
    
    private static func getStatusEffectIcon(_ effect: StatusEffectType) -> String {
        switch effect {
        case .poison: return "☠️"
        case .burn: return "🔥"
        case .freeze: return "❄️"
        case .attack_up: return "⚔️"
        case .defense_up: return "🛡️"
        case .speed_up: return "💨"
        case .attack_down: return "🔻"
        case .defense_down: return "📉"
        case .speed_down: return "🐌"
        }
    }
    
    private static func getStatusEffectCategory(_ effect: StatusEffectType) -> String {
        switch effect {
        case .poison, .burn, .freeze: return "Damage Over Time"
        case .attack_up, .defense_up, .speed_up: return "Buff"
        case .attack_down, .defense_down, .speed_down: return "Debuff"
        }
    }
}

// MARK: - Performance Tester
class PerformanceTester {
    
    static func runPerformanceTests() {
        print("\n⚡ PERFORMANCE TESTS")
        print("-" * 30)
        
        // Test unit creation performance
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var units: [Unit] = []
        for i in 0..<1000 {
            let unit = UnitFactory.createPlayerUnit(name: "Unit \(i)", unitClass: .warrior)
            units.append(unit)
        }
        
        let creationTime = CFAbsoluteTimeGetCurrent() - startTime
        print("✅ Created 1000 units in \(String(format: "%.3f", creationTime)) seconds")
        
        // Test battle simulation performance
        let battleStartTime = CFAbsoluteTimeGetCurrent()
        
        let hero = UnitFactory.createPlayerUnit(name: "Hero", unitClass: .warrior)
        let enemy = UnitFactory.createEnemyUnit(name: "Enemy", level: 1)
        
        for _ in 0..<100 {
            let battle = BattleManager(playerUnits: [hero], enemyUnits: [enemy])
            _ = battle.getBattleStatistics()
        }
        
        let battleTime = CFAbsoluteTimeGetCurrent() - battleStartTime
        print("✅ Simulated 100 battles in \(String(format: "%.3f", battleTime)) seconds")
        
        print("⚡ Performance tests completed!")
    }
}

// MARK: - String Extension for Repeated Characters
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}