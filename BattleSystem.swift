import Foundation
import SpriteKit

// MARK: - Battle Action Types

enum BattleAction {
    case attack(target: Unit)
    case skill(skill: Skill, targets: [Unit])
    case item(item: String, target: Unit?) // Simplified item system
    case defend
}

// MARK: - Battle Manager

class BattleManager {
    
    // MARK: - Properties
    var state: BattleState = .playerTurn
    var playerUnits: [Unit] = []
    var enemyUnits: [Unit] = []
    
    var currentUnitIndex: Int = 0
    var isPlayerPhase: Bool = true
    var battleRewards: BattleRewards = BattleRewards()
    
    // MARK: - Delegates and Callbacks
    weak var delegate: BattleManagerDelegate?
    
    // MARK: - Battle Flow
    
    func startBattle(playerTeam: [Unit], enemyTeam: [Unit]) {
        // Create battle copies of units
        playerUnits = playerTeam.map { $0.duplicateForBattle() }
        enemyUnits = enemyTeam.map { $0.duplicateForBattle() }
        
        // Calculate battle rewards
        calculateBattleRewards()
        
        // Initialize battle
        state = .playerTurn
        isPlayerPhase = true
        currentUnitIndex = 0
        
        // Notify delegate
        delegate?.battleStarted(playerUnits: playerUnits, enemyUnits: enemyUnits)
        
        // Start first turn
        startPlayerPhase()
    }
    
    private func startPlayerPhase() {
        state = .playerTurn
        isPlayerPhase = true
        currentUnitIndex = 0
        
        // Reset defend status for all player units
        for unit in playerUnits {
            unit.isDefending = false
        }
        
        delegate?.phaseChanged(isPlayerPhase: true)
        
        // Check if any player units are alive
        let alivePlayerUnits = getAlivePlayerUnits()
        if alivePlayerUnits.isEmpty {
            endBattle(victory: false)
            return
        }
        
        selectNextPlayerUnit()
    }
    
    private func startEnemyPhase() {
        state = .enemyTurn
        isPlayerPhase = false
        currentUnitIndex = 0
        
        // Reset defend status for all enemy units
        for unit in enemyUnits {
            unit.isDefending = false
        }
        
        delegate?.phaseChanged(isPlayerPhase: false)
        
        // Process enemy turns with AI
        processEnemyTurns()
    }
    
    private func selectNextPlayerUnit() {
        let aliveUnits = getAlivePlayerUnits()
        
        if currentUnitIndex >= aliveUnits.count {
            // All player units have acted, start enemy phase
            startEnemyPhase()
            return
        }
        
        let currentUnit = aliveUnits[currentUnitIndex]
        delegate?.unitTurnStarted(unit: currentUnit, isPlayer: true)
    }
    
    // MARK: - Action Processing
    
    func processPlayerAction(_ action: BattleAction) {
        let aliveUnits = getAlivePlayerUnits()
        guard currentUnitIndex < aliveUnits.count else { return }
        
        let currentUnit = aliveUnits[currentUnitIndex]
        
        switch action {
        case .attack(let target):
            executeAttack(attacker: currentUnit, target: target)
            
        case .skill(let skill, let targets):
            executeSkill(caster: currentUnit, skill: skill, targets: targets)
            
        case .item(let itemId, let target):
            executeItem(user: currentUnit, itemId: itemId, target: target)
            
        case .defend:
            executeDefend(unit: currentUnit)
        }
        
        // Move to next unit
        currentUnitIndex += 1
        
        // Check for battle end
        if checkBattleEnd() {
            return
        }
        
        // Continue to next unit or phase
        selectNextPlayerUnit()
    }
    
    private func processEnemyTurns() {
        let aliveEnemies = getAliveEnemyUnits()
        
        // Simple AI for each enemy
        for enemy in aliveEnemies {
            guard enemy.isAlive() else { continue }
            
            let action = getEnemyAction(for: enemy)
            executeEnemyAction(enemy: enemy, action: action)
            
            // Check for battle end after each enemy action
            if checkBattleEnd() {
                return
            }
        }
        
        // All enemies have acted, start next player phase
        startPlayerPhase()
    }
    
    private func getEnemyAction(for enemy: Unit) -> BattleAction {
        let playerTargets = getAlivePlayerUnits()
        guard !playerTargets.isEmpty else {
            return .defend
        }
        
        // Simple AI logic
        let usableSkills = enemy.getUsableSkills()
        
        // 30% chance to use skill if available
        if !usableSkills.isEmpty && Double.random(in: 0...1) < 0.3 {
            let skill = usableSkills.randomElement()!
            let targets = getValidTargets(for: skill, caster: enemy, isPlayerTurn: false)
            if !targets.isEmpty {
                return .skill(skill: skill, targets: targets)
            }
        }
        
        // Default to basic attack
        let target = playerTargets.randomElement()!
        return .attack(target: target)
    }
    
    private func executeEnemyAction(enemy: Unit, action: BattleAction) {
        delegate?.unitTurnStarted(unit: enemy, isPlayer: false)
        
        switch action {
        case .attack(let target):
            executeAttack(attacker: enemy, target: target)
            
        case .skill(let skill, let targets):
            executeSkill(caster: enemy, skill: skill, targets: targets)
            
        case .defend:
            executeDefend(unit: enemy)
            
        case .item:
            // Enemies don't use items in this implementation
            break
        }
    }
    
    // MARK: - Action Execution
    
    private func executeAttack(attacker: Unit, target: Unit) {
        state = .animating
        
        let damage = target.takeDamage(attacker.attack, damageType: .physical)
        
        delegate?.damageDealt(target: target, amount: damage, damageType: .physical)
        
        if !target.isAlive() {
            delegate?.unitDefeated(unit: target)
        }
        
        state = isPlayerPhase ? .playerTurn : .enemyTurn
    }
    
    private func executeSkill(caster: Unit, skill: Skill, targets: [Unit]) {
        state = .animating
        
        guard skill.canUse(by: caster) else {
            delegate?.actionFailed(reason: "Not enough MP")
            return
        }
        
        // Use MP
        caster.useMP(skill.mpCost)
        
        delegate?.skillUsed(caster: caster, skill: skill, targets: targets)
        
        // Apply effects to all targets
        for target in targets {
            if skill.power > 0 {
                let damage = skill.getDamage(from: caster)
                let actualDamage = target.takeDamage(damage, damageType: skill.damageType)
                delegate?.damageDealt(target: target, amount: actualDamage, damageType: skill.damageType)
            }
            
            if skill.healPower > 0 {
                let healing = skill.getHealAmount(from: caster)
                let actualHealing = target.heal(healing)
                delegate?.healingDone(target: target, amount: actualHealing)
            }
            
            if !skill.statusEffect.isEmpty && skill.statusDuration > 0 {
                target.applyStatusEffect(skill.statusEffect, duration: skill.statusDuration)
                delegate?.statusEffectApplied(target: target, effect: skill.statusEffect, duration: skill.statusDuration)
            }
            
            if !target.isAlive() {
                delegate?.unitDefeated(unit: target)
            }
        }
        
        state = isPlayerPhase ? .playerTurn : .enemyTurn
    }
    
    private func executeDefend(unit: Unit) {
        unit.defend()
        delegate?.unitDefended(unit: unit)
    }
    
    private func executeItem(user: Unit, itemId: String, target: Unit?) {
        // Simplified item system - in full game would have item definitions
        switch itemId {
        case "health_potion":
            if let target = target {
                let healing = target.heal(50)
                delegate?.healingDone(target: target, amount: healing)
            }
        case "mana_potion":
            if let target = target {
                let mpRestore = target.restoreMP(30)
                delegate?.mpRestored(target: target, amount: mpRestore)
            }
        default:
            delegate?.actionFailed(reason: "Unknown item")
        }
    }
    
    // MARK: - Battle End Conditions
    
    private func checkBattleEnd() -> Bool {
        let alivePlayerUnits = getAlivePlayerUnits()
        let aliveEnemyUnits = getAliveEnemyUnits()
        
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
        state = victory ? .victory : .defeat
        
        if victory {
            // Apply rewards
            GameData.shared.currentRunData.gold += battleRewards.gold
            GameData.shared.addMetaExp(battleRewards.exp)
            GameData.shared.currentRunData.floor += 1
            
            // Update best floor
            if GameData.shared.currentRunData.floor > GameData.shared.metaProgression.bestFloor {
                GameData.shared.metaProgression.bestFloor = GameData.shared.currentRunData.floor
            }
        } else {
            // End run
            GameData.shared.metaProgression.totalRuns += 1
            GameData.shared.currentRunData.reset()
        }
        
        GameData.shared.saveGameData()
        delegate?.battleEnded(victory: victory, rewards: battleRewards)
    }
    
    // MARK: - Helper Methods
    
    func getAlivePlayerUnits() -> [Unit] {
        return playerUnits.filter { $0.isAlive() }
    }
    
    func getAliveEnemyUnits() -> [Unit] {
        return enemyUnits.filter { $0.isAlive() }
    }
    
    func getValidTargets(for skill: Skill, caster: Unit, isPlayerTurn: Bool) -> [Unit] {
        let casterTeam = isPlayerTurn ? playerUnits : enemyUnits
        let enemyTeam = isPlayerTurn ? enemyUnits : playerUnits
        
        switch skill.targetType {
        case .singleEnemy:
            return enemyTeam.filter { $0.isAlive() }
        case .allEnemies:
            return enemyTeam.filter { $0.isAlive() }
        case .singleAlly:
            return casterTeam.filter { $0.isAlive() }
        case .allAllies:
            return casterTeam.filter { $0.isAlive() }
        case .self:
            return [caster]
        }
    }
    
    private func calculateBattleRewards() {
        battleRewards.exp = enemyUnits.count * 50
        battleRewards.gold = enemyUnits.count * 30
        battleRewards.items = [] // Could add random item drops
    }
}

// MARK: - Battle Manager Delegate

protocol BattleManagerDelegate: AnyObject {
    func battleStarted(playerUnits: [Unit], enemyUnits: [Unit])
    func phaseChanged(isPlayerPhase: Bool)
    func unitTurnStarted(unit: Unit, isPlayer: Bool)
    func damageDealt(target: Unit, amount: Int, damageType: DamageType)
    func healingDone(target: Unit, amount: Int)
    func mpRestored(target: Unit, amount: Int)
    func skillUsed(caster: Unit, skill: Skill, targets: [Unit])
    func statusEffectApplied(target: Unit, effect: String, duration: Int)
    func unitDefended(unit: Unit)
    func unitDefeated(unit: Unit)
    func actionFailed(reason: String)
    func battleEnded(victory: Bool, rewards: BattleRewards)
}

// MARK: - Battle Rewards

struct BattleRewards {
    var exp: Int = 0
    var gold: Int = 0
    var items: [String] = []
}

// MARK: - Battle Scene (SpriteKit Integration)

class BattleScene: SKScene {
    
    // MARK: - Properties
    var battleManager: BattleManager!
    var playerUnitNodes: [SKSpriteNode] = []
    var enemyUnitNodes: [SKSpriteNode] = []
    var uiNodes: [SKNode] = []
    
    // MARK: - Scene Setup
    
    override func didMove(to view: SKView) {
        setupBattleScene()
        setupBattleManager()
    }
    
    private func setupBattleScene() {
        backgroundColor = SKColor.darkGray
        
        // Add background
        let background = SKSpriteNode(color: .systemBlue, size: size)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.alpha = 0.3
        addChild(background)
        
        // Setup UI positions
        setupUILayout()
    }
    
    private func setupBattleManager() {
        battleManager = BattleManager()
        battleManager.delegate = self
    }
    
    private func setupUILayout() {
        // Create placeholder positions for units
        let playerY = size.height * 0.3
        let enemyY = size.height * 0.7
        
        // Player positions (left side)
        for i in 0..<4 {
            let x = size.width * 0.2 + CGFloat(i) * 60
            let position = CGPoint(x: x, y: playerY)
            
            let positionMarker = SKShapeNode(circleOfRadius: 25)
            positionMarker.strokeColor = .green
            positionMarker.fillColor = .clear
            positionMarker.position = position
            positionMarker.alpha = 0.5
            addChild(positionMarker)
        }
        
        // Enemy positions (right side)
        for i in 0..<4 {
            let x = size.width * 0.6 + CGFloat(i) * 60
            let position = CGPoint(x: x, y: enemyY)
            
            let positionMarker = SKShapeNode(circleOfRadius: 25)
            positionMarker.strokeColor = .red
            positionMarker.fillColor = .clear
            positionMarker.position = position
            positionMarker.alpha = 0.5
            addChild(positionMarker)
        }
    }
    
    // MARK: - Battle Visualization
    
    private func spawnUnits(playerUnits: [Unit], enemyUnits: [Unit]) {
        // Clear existing unit nodes
        playerUnitNodes.forEach { $0.removeFromParent() }
        enemyUnitNodes.forEach { $0.removeFromParent() }
        playerUnitNodes.removeAll()
        enemyUnitNodes.removeAll()
        
        // Spawn player units
        for (index, unit) in playerUnits.enumerated() {
            let unitNode = createUnitNode(for: unit, isPlayer: true)
            let x = size.width * 0.2 + CGFloat(index) * 60
            let y = size.height * 0.3
            unitNode.position = CGPoint(x: x, y: y)
            addChild(unitNode)
            playerUnitNodes.append(unitNode)
        }
        
        // Spawn enemy units
        for (index, unit) in enemyUnits.enumerated() {
            let unitNode = createUnitNode(for: unit, isPlayer: false)
            let x = size.width * 0.6 + CGFloat(index) * 60
            let y = size.height * 0.7
            unitNode.position = CGPoint(x: x, y: y)
            addChild(unitNode)
            enemyUnitNodes.append(unitNode)
        }
    }
    
    private func createUnitNode(for unit: Unit, isPlayer: Bool) -> SKSpriteNode {
        // Create a simple colored rectangle for now
        let color: SKColor = isPlayer ? .blue : .red
        let unitNode = SKSpriteNode(color: color, size: CGSize(width: 40, height: 60))
        
        // Add unit name label
        let nameLabel = SKLabelNode(text: unit.unitName)
        nameLabel.fontSize = 12
        nameLabel.fontColor = .white
        nameLabel.position = CGPoint(x: 0, y: -40)
        unitNode.addChild(nameLabel)
        
        // Add HP bar
        let hpBar = createHealthBar(for: unit)
        hpBar.position = CGPoint(x: 0, y: 35)
        unitNode.addChild(hpBar)
        
        return unitNode
    }
    
    private func createHealthBar(for unit: Unit) -> SKNode {
        let barContainer = SKNode()
        
        // Background bar
        let bgBar = SKSpriteNode(color: .darkGray, size: CGSize(width: 40, height: 6))
        barContainer.addChild(bgBar)
        
        // Health bar
        let hpPercentage = unit.getHPPercentage()
        let hpBar = SKSpriteNode(color: .green, size: CGSize(width: 40 * hpPercentage, height: 6))
        hpBar.anchorPoint = CGPoint(x: 0, y: 0.5)
        hpBar.position = CGPoint(x: -20, y: 0)
        barContainer.addChild(hpBar)
        
        return barContainer
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Simple touch handling for demo
        // In full game, would have proper UI buttons
        print("Touch at: \(location)")
    }
}

// MARK: - Battle Manager Delegate Implementation

extension BattleScene: BattleManagerDelegate {
    
    func battleStarted(playerUnits: [Unit], enemyUnits: [Unit]) {
        spawnUnits(playerUnits: playerUnits, enemyUnits: enemyUnits)
        print("Battle started!")
    }
    
    func phaseChanged(isPlayerPhase: Bool) {
        print(isPlayerPhase ? "Player phase started" : "Enemy phase started")
    }
    
    func unitTurnStarted(unit: Unit, isPlayer: Bool) {
        print("\(unit.unitName)'s turn")
    }
    
    func damageDealt(target: Unit, amount: Int, damageType: DamageType) {
        print("\(target.unitName) takes \(amount) \(damageType.rawValue) damage")
        // Update health bar visuals
        updateHealthBars()
    }
    
    func healingDone(target: Unit, amount: Int) {
        print("\(target.unitName) healed for \(amount) HP")
        updateHealthBars()
    }
    
    func mpRestored(target: Unit, amount: Int) {
        print("\(target.unitName) restored \(amount) MP")
    }
    
    func skillUsed(caster: Unit, skill: Skill, targets: [Unit]) {
        print("\(caster.unitName) uses \(skill.skillName)")
    }
    
    func statusEffectApplied(target: Unit, effect: String, duration: Int) {
        print("\(target.unitName) is affected by \(effect) for \(duration) turns")
    }
    
    func unitDefended(unit: Unit) {
        print("\(unit.unitName) defends")
    }
    
    func unitDefeated(unit: Unit) {
        print("\(unit.unitName) is defeated")
        // Fade out defeated unit
        if let unitNode = getUnitNode(for: unit) {
            unitNode.alpha = 0.3
        }
    }
    
    func actionFailed(reason: String) {
        print("Action failed: \(reason)")
    }
    
    func battleEnded(victory: Bool, rewards: BattleRewards) {
        print(victory ? "Victory!" : "Defeat!")
        print("Rewards: \(rewards.exp) EXP, \(rewards.gold) Gold")
    }
    
    private func updateHealthBars() {
        // Update all health bars
        for (index, unit) in battleManager.playerUnits.enumerated() {
            if index < playerUnitNodes.count {
                updateHealthBar(for: playerUnitNodes[index], unit: unit)
            }
        }
        
        for (index, unit) in battleManager.enemyUnits.enumerated() {
            if index < enemyUnitNodes.count {
                updateHealthBar(for: enemyUnitNodes[index], unit: unit)
            }
        }
    }
    
    private func updateHealthBar(for unitNode: SKSpriteNode, unit: Unit) {
        // Find and update the health bar in the unit node
        if let barContainer = unitNode.children.first(where: { $0.children.count >= 2 }) {
            if let hpBar = barContainer.children.last as? SKSpriteNode {
                let hpPercentage = unit.getHPPercentage()
                hpBar.size.width = 40 * hpPercentage
                
                // Change color based on health
                if hpPercentage > 0.6 {
                    hpBar.color = .green
                } else if hpPercentage > 0.3 {
                    hpBar.color = .yellow
                } else {
                    hpBar.color = .red
                }
            }
        }
    }
    
    private func getUnitNode(for unit: Unit) -> SKSpriteNode? {
        // Find the node corresponding to this unit
        // This is simplified - in full game would have better unit tracking
        for (index, playerUnit) in battleManager.playerUnits.enumerated() {
            if playerUnit === unit && index < playerUnitNodes.count {
                return playerUnitNodes[index]
            }
        }
        
        for (index, enemyUnit) in battleManager.enemyUnits.enumerated() {
            if enemyUnit === unit && index < enemyUnitNodes.count {
                return enemyUnitNodes[index]
            }
        }
        
        return nil
    }
}