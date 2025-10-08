import Foundation
import SpriteKit

// MARK: - Battle Manager
class BattleManager: ObservableObject {
    
    // MARK: - Battle State
    enum BattlePhase {
        case setup
        case playerTurn
        case enemyTurn
        case victory
        case defeat
        case animating
    }
    
    enum BattleAction {
        case attack(attacker: Unit, target: Unit)
        case useSkill(caster: Unit, skill: Skill, targets: [Unit])
        case defend(unit: Unit)
        case useItem(user: Unit, item: String, target: Unit?)
    }
    
    // MARK: - Properties
    @Published var currentPhase: BattlePhase = .setup
    @Published var playerUnits: [Unit] = []
    @Published var enemyUnits: [Unit] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var battleLog: [String] = []
    
    var allUnits: [Unit] {
        return playerUnits + enemyUnits
    }
    
    var alivePlayerUnits: [Unit] {
        return playerUnits.filter { $0.isAlive }
    }
    
    var aliveEnemyUnits: [Unit] {
        return enemyUnits.filter { $0.isAlive }
    }
    
    // MARK: - Battle Flow
    func startBattle(playerTeam: [Unit], enemyTeam: [Unit]) {
        playerUnits = playerTeam
        enemyUnits = enemyTeam
        currentPlayerIndex = 0
        battleLog.removeAll()
        
        addToBattleLog("🔥 Battle begins!")
        addToBattleLog("Player team: \(playerUnits.map { $0.name }.joined(separator: ", "))")
        addToBattleLog("Enemy team: \(enemyUnits.map { $0.name }.joined(separator: ", "))")
        
        currentPhase = .playerTurn
        startPlayerTurn()
    }
    
    private func startPlayerTurn() {
        currentPhase = .playerTurn
        addToBattleLog("\n⚔️ Player turn begins")
        
        // Process status effects for all units
        processAllStatusEffects()
        
        // Check if battle is over
        if checkBattleEnd() {
            return
        }
        
        // Find next alive player unit
        selectNextPlayerUnit()
    }
    
    private func selectNextPlayerUnit() {
        let aliveUnits = alivePlayerUnits
        
        // If we've gone through all player units, start enemy turn
        if currentPlayerIndex >= aliveUnits.count {
            startEnemyTurn()
            return
        }
        
        let currentUnit = aliveUnits[currentPlayerIndex]
        addToBattleLog("🛡️ \(currentUnit.name)'s turn - HP: \(currentUnit.currentHP)/\(currentUnit.maxHP), MP: \(currentUnit.currentMP)/\(currentUnit.maxMP)")
    }
    
    private func startEnemyTurn() {
        currentPhase = .enemyTurn
        currentPlayerIndex = 0 // Reset for next player turn
        addToBattleLog("\n👹 Enemy turn begins")
        
        // Process enemy actions with simple AI
        processEnemyActions()
    }
    
    // MARK: - Action Processing
    func processPlayerAction(_ action: BattleAction) {
        guard currentPhase == .playerTurn else { return }
        
        currentPhase = .animating
        
        switch action {
        case .attack(let attacker, let target):
            executeAttack(attacker: attacker, target: target)
            
        case .useSkill(let caster, let skill, let targets):
            executeSkill(caster: caster, skill: skill, targets: targets)
            
        case .defend(let unit):
            executeDefend(unit: unit)
            
        case .useItem(let user, let item, let target):
            executeItem(user: user, item: item, target: target)
        }
        
        // Move to next player unit
        currentPlayerIndex += 1
        
        // Check for battle end
        if checkBattleEnd() {
            return
        }
        
        // Continue player turn or switch to enemy turn
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentPhase = .playerTurn
            self.selectNextPlayerUnit()
        }
    }
    
    private func processEnemyActions() {
        let aliveEnemies = aliveEnemyUnits
        
        guard !aliveEnemies.isEmpty else {
            endBattle(victory: true)
            return
        }
        
        processEnemyAction(for: aliveEnemies, index: 0)
    }
    
    private func processEnemyAction(for enemies: [Unit], index: Int) {
        guard index < enemies.count else {
            // All enemies have acted, start next player turn
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startPlayerTurn()
            }
            return
        }
        
        let enemy = enemies[index]
        let action = getEnemyAction(for: enemy)
        
        currentPhase = .animating
        
        switch action {
        case .attack(let attacker, let target):
            executeAttack(attacker: attacker, target: target)
            
        case .useSkill(let caster, let skill, let targets):
            executeSkill(caster: caster, skill: skill, targets: targets)
            
        case .defend(let unit):
            executeDefend(unit: unit)
            
        default:
            break
        }
        
        // Check for battle end
        if checkBattleEnd() {
            return
        }
        
        // Process next enemy after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.processEnemyAction(for: enemies, index: index + 1)
        }
    }
    
    // MARK: - Action Execution
    private func executeAttack(attacker: Unit, target: Unit) {
        let damage = attacker.calculatePhysicalDamage()
        let actualDamage = target.takeDamage(damage, damageType: .physical)
        
        addToBattleLog("💥 \(attacker.name) attacks \(target.name) for \(actualDamage) damage!")
        
        if target.isDefeated {
            addToBattleLog("💀 \(target.name) is defeated!")
        }
    }
    
    private func executeSkill(caster: Unit, skill: Skill, targets: [Unit]) {
        guard caster.canUseSkill(skill) else {
            addToBattleLog("❌ \(caster.name) cannot use \(skill.name) (not enough MP)")
            return
        }
        
        caster.consumeMP(skill.mpCost)
        addToBattleLog("✨ \(caster.name) uses \(skill.name)!")
        
        for target in targets {
            switch skill.skillType {
            case .damage:
                let damage = skill.power + (skill.element != nil ? caster.calculateMagicalDamage() : caster.calculatePhysicalDamage())
                let actualDamage = target.takeDamage(damage, damageType: skill.element != nil ? .magical : .physical)
                addToBattleLog("💥 \(target.name) takes \(actualDamage) damage!")
                
            case .healing:
                let healAmount = target.heal(skill.power + caster.magic)
                addToBattleLog("💚 \(target.name) heals for \(healAmount) HP!")
                
            case .buff, .debuff:
                if let statusEffect = skill.statusEffect {
                    let effect = StatusEffect(type: statusEffect, power: skill.power, duration: skill.statusDuration)
                    target.addStatusEffect(effect)
                    addToBattleLog("🌟 \(target.name) is affected by \(statusEffect)!")
                }
                
            case .utility:
                addToBattleLog("🔧 \(caster.name) uses utility skill on \(target.name)")
            }
            
            if target.isDefeated {
                addToBattleLog("💀 \(target.name) is defeated!")
            }
        }
    }
    
    private func executeDefend(unit: Unit) {
        addToBattleLog("🛡️ \(unit.name) defends (damage will be reduced)")
        // In a full implementation, you'd apply a temporary defense boost
    }
    
    private func executeItem(user: Unit, item: String, target: Unit?) {
        switch item {
        case "health_potion":
            if let target = target {
                let healAmount = target.heal(50)
                addToBattleLog("🧪 \(user.name) uses Health Potion on \(target.name) - healed \(healAmount) HP!")
            }
        case "mana_potion":
            if let target = target {
                let mpAmount = target.restoreMP(30)
                addToBattleLog("🧪 \(user.name) uses Mana Potion on \(target.name) - restored \(mpAmount) MP!")
            }
        default:
            addToBattleLog("❓ Unknown item: \(item)")
        }
    }
    
    // MARK: - Enemy AI
    private func getEnemyAction(for enemy: Unit) -> BattleAction {
        let playerTargets = alivePlayerUnits
        guard !playerTargets.isEmpty else {
            return .defend(unit: enemy)
        }
        
        // Simple AI: 70% attack, 30% skill if available
        let useSkill = Double.random(in: 0...1) < 0.3 && !enemy.availableSkills.isEmpty
        
        if useSkill {
            let availableSkills = enemy.availableSkills.filter { enemy.canUseSkill($0) }
            if let skill = availableSkills.randomElement() {
                let targets = getValidTargets(for: skill, caster: enemy, isPlayerCaster: false)
                if !targets.isEmpty {
                    return .useSkill(caster: enemy, skill: skill, targets: targets)
                }
            }
        }
        
        // Default to attack
        let target = playerTargets.randomElement()!
        return .attack(attacker: enemy, target: target)
    }
    
    // MARK: - Target Selection
    func getValidTargets(for skill: Skill, caster: Unit, isPlayerCaster: Bool) -> [Unit] {
        switch skill.targetType {
        case .self_target:
            return [caster]
            
        case .single_ally:
            return isPlayerCaster ? alivePlayerUnits : aliveEnemyUnits
            
        case .all_allies:
            return isPlayerCaster ? alivePlayerUnits : aliveEnemyUnits
            
        case .single_enemy:
            return isPlayerCaster ? aliveEnemyUnits : alivePlayerUnits
            
        case .all_enemies:
            return isPlayerCaster ? aliveEnemyUnits : alivePlayerUnits
            
        case .random_enemy:
            let enemies = isPlayerCaster ? aliveEnemyUnits : alivePlayerUnits
            return enemies.isEmpty ? [] : [enemies.randomElement()!]
        }
    }
    
    // MARK: - Status Effects
    private func processAllStatusEffects() {
        for unit in allUnits where unit.isAlive {
            let results = unit.processStatusEffects()
            for result in results {
                if result.value > 0 {
                    let effect = result.isPositive ? "✨" : "💀"
                    addToBattleLog("\(effect) \(unit.name) \(result.type) effect: \(result.value)")
                }
            }
        }
    }
    
    // MARK: - Battle End
    private func checkBattleEnd() -> Bool {
        if alivePlayerUnits.isEmpty {
            endBattle(victory: false)
            return true
        } else if aliveEnemyUnits.isEmpty {
            endBattle(victory: true)
            return true
        }
        return false
    }
    
    private func endBattle(victory: Bool) {
        currentPhase = victory ? .victory : .defeat
        
        if victory {
            addToBattleLog("\n🎉 VICTORY!")
            addToBattleLog("The battle is won!")
            
            // Calculate rewards
            let expGained = enemyUnits.count * 50
            let goldGained = enemyUnits.count * 25
            addToBattleLog("💰 Gained \(expGained) EXP and \(goldGained) Gold!")
            
        } else {
            addToBattleLog("\n💀 DEFEAT!")
            addToBattleLog("Your party has been defeated...")
        }
    }
    
    // MARK: - Utility
    private func addToBattleLog(_ message: String) {
        battleLog.append(message)
        print(message) // Also print to console for debugging
    }
    
    func getCurrentPlayerUnit() -> Unit? {
        let aliveUnits = alivePlayerUnits
        guard currentPlayerIndex < aliveUnits.count else { return nil }
        return aliveUnits[currentPlayerIndex]
    }
    
    func canPlayerAct() -> Bool {
        return currentPhase == .playerTurn && getCurrentPlayerUnit() != nil
    }
    
    // MARK: - Quick Actions (for UI)
    func playerAttack(target: Unit) {
        guard let attacker = getCurrentPlayerUnit() else { return }
        let action = BattleAction.attack(attacker: attacker, target: target)
        processPlayerAction(action)
    }
    
    func playerUseSkill(_ skill: Skill, on targets: [Unit]) {
        guard let caster = getCurrentPlayerUnit() else { return }
        let action = BattleAction.useSkill(caster: caster, skill: skill, targets: targets)
        processPlayerAction(action)
    }
    
    func playerDefend() {
        guard let unit = getCurrentPlayerUnit() else { return }
        let action = BattleAction.defend(unit: unit)
        processPlayerAction(action)
    }
}