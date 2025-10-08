import Foundation
import SpriteKit

// MARK: - Enums for Game Data Types

enum UnitClass: String, CaseIterable, Codable {
    case warrior = "warrior"
    case mage = "mage"
    case rogue = "rogue"
    case cleric = "cleric"
    case archer = "archer"
}

enum DamageType: String, CaseIterable, Codable {
    case physical = "physical"
    case magical = "magical"
    case trueDamage = "true"
}

enum TargetType: String, CaseIterable, Codable {
    case singleEnemy = "single_enemy"
    case allEnemies = "all_enemies"
    case singleAlly = "single_ally"
    case allAllies = "all_allies"
    case self = "self"
}

enum BattleState: String, CaseIterable {
    case playerTurn = "player_turn"
    case enemyTurn = "enemy_turn"
    case animating = "animating"
    case victory = "victory"
    case defeat = "defeat"
}

// MARK: - Status Effect Structure

struct StatusEffect: Codable {
    let effect: String
    var duration: Int
    
    init(effect: String, duration: Int) {
        self.effect = effect
        self.duration = duration
    }
}

// MARK: - Unit Class

class Unit: Codable {
    
    // MARK: - Basic Properties
    var unitName: String
    var unitClass: UnitClass
    var spritePath: String
    var description: String
    
    // MARK: - Base Stats (permanent)
    var maxHP: Int
    var maxMP: Int
    var attack: Int
    var defense: Int
    var magic: Int
    var speed: Int
    
    // MARK: - Current Battle Stats (temporary)
    var currentHP: Int
    var currentMP: Int
    var isDefending: Bool = false
    var statusEffects: [StatusEffect] = []
    var positionIndex: Int = 0
    
    // MARK: - Skills and Abilities
    var skills: [Skill] = []
    
    // MARK: - Initialization
    
    init(name: String, 
         unitClass: UnitClass, 
         maxHP: Int, 
         maxMP: Int, 
         attack: Int, 
         defense: Int, 
         magic: Int, 
         speed: Int,
         spritePath: String = "",
         description: String = "") {
        
        self.unitName = name
        self.unitClass = unitClass
        self.maxHP = maxHP
        self.maxMP = maxMP
        self.attack = attack
        self.defense = defense
        self.magic = magic
        self.speed = speed
        self.spritePath = spritePath
        self.description = description
        
        // Initialize current stats to max values
        self.currentHP = maxHP
        self.currentMP = maxMP
    }
    
    // MARK: - Battle Management
    
    /// Initialize unit for battle (reset current stats and status)
    func initializeForBattle() {
        currentHP = maxHP
        currentMP = maxMP
        isDefending = false
        statusEffects.removeAll()
    }
    
    /// Create a copy of this unit for battle use
    func duplicateForBattle() -> Unit {
        let copy = Unit(name: unitName,
                       unitClass: unitClass,
                       maxHP: maxHP,
                       maxMP: maxMP,
                       attack: attack,
                       defense: defense,
                       magic: magic,
                       speed: speed,
                       spritePath: spritePath,
                       description: description)
        
        copy.skills = skills // Copy skills array
        copy.initializeForBattle()
        return copy
    }
    
    // MARK: - Damage and Healing
    
    /// Apply damage to the unit and return actual damage dealt
    @discardableResult
    func takeDamage(_ amount: Int, damageType: DamageType) -> Int {
        var finalDamage = amount
        
        // Apply damage reduction based on type
        switch damageType {
        case .physical:
            finalDamage -= defense
            if isDefending {
                finalDamage = Int(Double(finalDamage) * 0.5)
            }
        case .magical:
            finalDamage -= Int(Double(magic) * 0.5)
        case .trueDamage:
            // True damage ignores all defenses
            break
        }
        
        // Ensure minimum 1 damage
        finalDamage = max(1, finalDamage)
        
        // Apply damage
        currentHP -= finalDamage
        currentHP = max(0, currentHP)
        
        return finalDamage
    }
    
    /// Heal the unit and return actual healing done
    @discardableResult
    func heal(_ amount: Int) -> Int {
        let actualHeal = min(amount, maxHP - currentHP)
        currentHP += actualHeal
        return actualHeal
    }
    
    /// Restore MP and return actual MP restored
    @discardableResult
    func restoreMP(_ amount: Int) -> Int {
        let actualRestore = min(amount, maxMP - currentMP)
        currentMP += actualRestore
        return actualRestore
    }
    
    /// Use MP for skills - returns true if successful
    @discardableResult
    func useMP(_ amount: Int) -> Bool {
        if currentMP >= amount {
            currentMP -= amount
            return true
        }
        return false
    }
    
    // MARK: - Status Checks
    
    /// Check if unit is alive
    func isAlive() -> Bool {
        return currentHP > 0
    }
    
    /// Get HP as percentage (0.0 to 1.0)
    func getHPPercentage() -> Double {
        return Double(currentHP) / Double(maxHP)
    }
    
    /// Get MP as percentage (0.0 to 1.0)
    func getMPPercentage() -> Double {
        if maxMP == 0 {
            return 0.0
        }
        return Double(currentMP) / Double(maxMP)
    }
    
    // MARK: - Status Effects
    
    /// Apply a status effect to the unit
    func applyStatusEffect(_ effect: String, duration: Int) {
        let statusEffect = StatusEffect(effect: effect, duration: duration)
        statusEffects.append(statusEffect)
    }
    
    /// Process status effects at end of turn (reduce duration, remove expired)
    func processStatusEffects() {
        // Reduce duration and mark expired effects
        for i in 0..<statusEffects.count {
            statusEffects[i].duration -= 1
        }
        
        // Remove expired effects
        statusEffects = statusEffects.filter { $0.duration > 0 }
    }
    
    /// Check if unit has a specific status effect
    func hasStatusEffect(_ effect: String) -> Bool {
        return statusEffects.contains { $0.effect == effect }
    }
    
    // MARK: - Skill Management
    
    /// Add a skill to this unit
    func addSkill(_ skill: Skill) {
        skills.append(skill)
    }
    
    /// Get all usable skills (enough MP)
    func getUsableSkills() -> [Skill] {
        return skills.filter { $0.canUse(by: self) }
    }
    
    // MARK: - Combat Actions
    
    /// Perform a basic attack on target
    func performBasicAttack(on target: Unit) -> Int {
        return target.takeDamage(attack, damageType: .physical)
    }
    
    /// Use a skill on targets
    func useSkill(_ skill: Skill, on targets: [Unit]) -> Bool {
        guard skill.canUse(by: self) else { return false }
        
        // Use MP
        useMP(skill.mpCost)
        
        // Apply skill effects to all targets
        for target in targets {
            skill.applyEffects(from: self, to: target)
        }
        
        return true
    }
    
    /// Set defending status
    func defend() {
        isDefending = true
    }
    
    // MARK: - Display Helpers
    
    /// Get formatted status string for UI
    func getStatusString() -> String {
        return "\(unitName) - HP: \(currentHP)/\(maxHP) MP: \(currentMP)/\(maxMP)"
    }
    
    /// Get unit info for debugging
    func getDebugInfo() -> String {
        let statusList = statusEffects.map { "\($0.effect)(\($0.duration))" }.joined(separator: ", ")
        return """
        \(unitName) (\(unitClass.rawValue))
        HP: \(currentHP)/\(maxHP) (\(Int(getHPPercentage() * 100))%)
        MP: \(currentMP)/\(maxMP) (\(Int(getMPPercentage() * 100))%)
        Stats: ATK:\(attack) DEF:\(defense) MAG:\(magic) SPD:\(speed)
        Status: \(statusList.isEmpty ? "None" : statusList)
        Defending: \(isDefending)
        Skills: \(skills.count)
        """
    }
}

// MARK: - Unit Factory

class UnitFactory {
    
    /// Create a basic warrior unit
    static func createWarrior(name: String = "Warrior") -> Unit {
        let warrior = Unit(name: name,
                          unitClass: .warrior,
                          maxHP: 120,
                          maxMP: 20,
                          attack: 15,
                          defense: 12,
                          magic: 3,
                          speed: 6,
                          description: "A sturdy melee fighter with high HP and defense")
        
        // Add basic warrior skills
        warrior.addSkill(SkillFactory.createPowerStrike())
        warrior.addSkill(SkillFactory.createDefensiveStance())
        
        return warrior
    }
    
    /// Create a basic mage unit
    static func createMage(name: String = "Mage") -> Unit {
        let mage = Unit(name: name,
                       unitClass: .mage,
                       maxHP: 80,
                       maxMP: 50,
                       attack: 6,
                       defense: 4,
                       magic: 18,
                       speed: 8,
                       description: "A magical damage dealer with high MP and magic power")
        
        // Add basic mage skills
        mage.addSkill(SkillFactory.createFirebolt())
        mage.addSkill(SkillFactory.createHeal())
        
        return mage
    }
    
    /// Create a basic rogue unit
    static func createRogue(name: String = "Rogue") -> Unit {
        let rogue = Unit(name: name,
                        unitClass: .rogue,
                        maxHP: 90,
                        maxMP: 30,
                        attack: 12,
                        defense: 6,
                        magic: 5,
                        speed: 15,
                        description: "A fast attacker with high speed and critical hits")
        
        // Add basic rogue skills
        rogue.addSkill(SkillFactory.createBackstab())
        rogue.addSkill(SkillFactory.createSmokeScreen())
        
        return rogue
    }
    
    /// Create a basic cleric unit
    static func createCleric(name: String = "Cleric") -> Unit {
        let cleric = Unit(name: name,
                         unitClass: .cleric,
                         maxHP: 100,
                         maxMP: 40,
                         attack: 8,
                         defense: 8,
                         magic: 14,
                         speed: 7,
                         description: "A support unit specializing in healing and buffs")
        
        // Add basic cleric skills
        cleric.addSkill(SkillFactory.createHeal())
        cleric.addSkill(SkillFactory.createBless())
        
        return cleric
    }
    
    /// Create a basic enemy unit
    static func createGoblin(name: String = "Goblin") -> Unit {
        let goblin = Unit(name: name,
                         unitClass: .rogue,
                         maxHP: 60,
                         maxMP: 15,
                         attack: 10,
                         defense: 4,
                         magic: 2,
                         speed: 12,
                         description: "A weak but fast enemy")
        
        goblin.addSkill(SkillFactory.createQuickStrike())
        
        return goblin
    }
    
    /// Create a stronger enemy unit
    static func createOrc(name: String = "Orc") -> Unit {
        let orc = Unit(name: name,
                      unitClass: .warrior,
                      maxHP: 100,
                      maxMP: 10,
                      attack: 18,
                      defense: 8,
                      magic: 1,
                      speed: 4,
                      description: "A strong but slow enemy")
        
        orc.addSkill(SkillFactory.createPowerStrike())
        
        return orc
    }
}