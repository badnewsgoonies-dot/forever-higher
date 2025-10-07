import Foundation

// MARK: - Skill Class

class Skill: Codable {
    
    // MARK: - Basic Properties
    var skillName: String
    var description: String
    var mpCost: Int
    var power: Int
    var damageType: DamageType
    var targetType: TargetType
    var animationName: String
    var iconPath: String
    
    // MARK: - Additional Effects
    var healPower: Int
    var buffStats: [String: Int] // Dictionary for stat buffs/debuffs
    var debuffStats: [String: Int]
    var statusEffect: String
    var statusDuration: Int
    
    // MARK: - Initialization
    
    init(name: String,
         description: String,
         mpCost: Int,
         power: Int = 0,
         damageType: DamageType = .physical,
         targetType: TargetType = .singleEnemy,
         animationName: String = "default",
         iconPath: String = "",
         healPower: Int = 0,
         buffStats: [String: Int] = [:],
         debuffStats: [String: Int] = [:],
         statusEffect: String = "",
         statusDuration: Int = 0) {
        
        self.skillName = name
        self.description = description
        self.mpCost = mpCost
        self.power = power
        self.damageType = damageType
        self.targetType = targetType
        self.animationName = animationName
        self.iconPath = iconPath
        self.healPower = healPower
        self.buffStats = buffStats
        self.debuffStats = debuffStats
        self.statusEffect = statusEffect
        self.statusDuration = statusDuration
    }
    
    // MARK: - Skill Usage
    
    /// Check if a unit can use this skill
    func canUse(by unit: Unit) -> Bool {
        return unit.currentMP >= mpCost
    }
    
    /// Calculate damage this skill would deal from a specific caster
    func getDamage(from caster: Unit) -> Int {
        switch damageType {
        case .physical:
            return power + caster.attack
        case .magical:
            return power + (caster.magic * 2)
        case .trueDamage:
            return power
        }
    }
    
    /// Calculate healing this skill would provide from a specific caster
    func getHealAmount(from caster: Unit) -> Int {
        if healPower > 0 {
            return healPower + caster.magic
        }
        return 0
    }
    
    /// Apply all effects of this skill from caster to target
    func applyEffects(from caster: Unit, to target: Unit) {
        // Apply damage
        if power > 0 {
            let damage = getDamage(from: caster)
            target.takeDamage(damage, damageType: damageType)
        }
        
        // Apply healing
        if healPower > 0 {
            let healing = getHealAmount(from: caster)
            target.heal(healing)
        }
        
        // Apply status effect
        if !statusEffect.isEmpty && statusDuration > 0 {
            target.applyStatusEffect(statusEffect, duration: statusDuration)
        }
        
        // Apply stat buffs/debuffs (simplified - in full game would modify stats temporarily)
        // For now, we'll apply them as status effects
        for (stat, value) in buffStats {
            if value > 0 {
                target.applyStatusEffect("buff_\(stat)", duration: 3)
            }
        }
        
        for (stat, value) in debuffStats {
            if value > 0 {
                target.applyStatusEffect("debuff_\(stat)", duration: 3)
            }
        }
    }
    
    /// Get valid targets for this skill in battle context
    func getValidTargets(casterTeam: [Unit], enemyTeam: [Unit], isPlayerTurn: Bool) -> [Unit] {
        var validTargets: [Unit] = []
        
        switch targetType {
        case .singleEnemy:
            let enemies = isPlayerTurn ? enemyTeam : casterTeam
            validTargets = enemies.filter { $0.isAlive() }
            
        case .allEnemies:
            let enemies = isPlayerTurn ? enemyTeam : casterTeam
            validTargets = enemies.filter { $0.isAlive() }
            
        case .singleAlly:
            let allies = isPlayerTurn ? casterTeam : enemyTeam
            validTargets = allies.filter { $0.isAlive() }
            
        case .allAllies:
            let allies = isPlayerTurn ? casterTeam : enemyTeam
            validTargets = allies.filter { $0.isAlive() }
            
        case .self:
            // For self-targeting, we need the caster
            // This is a simplified approach - in full implementation, 
            // the caster would be passed as parameter
            validTargets = []
        }
        
        return validTargets
    }
    
    // MARK: - Display Helpers
    
    /// Get formatted skill info for UI
    func getDisplayInfo() -> String {
        var info = "\(skillName) (MP: \(mpCost))"
        
        if power > 0 {
            info += " - Damage: \(power)"
        }
        
        if healPower > 0 {
            info += " - Heal: \(healPower)"
        }
        
        if !statusEffect.isEmpty {
            info += " - Status: \(statusEffect)"
        }
        
        return info
    }
    
    /// Get detailed skill description
    func getDetailedDescription() -> String {
        var details = [description]
        
        if power > 0 {
            details.append("Base Power: \(power) (\(damageType.rawValue))")
        }
        
        if healPower > 0 {
            details.append("Base Healing: \(healPower)")
        }
        
        if mpCost > 0 {
            details.append("MP Cost: \(mpCost)")
        }
        
        if !statusEffect.isEmpty {
            details.append("Status Effect: \(statusEffect) (\(statusDuration) turns)")
        }
        
        details.append("Target: \(targetType.rawValue.replacingOccurrences(of: "_", with: " "))")
        
        return details.joined(separator: "\n")
    }
}

// MARK: - Skill Factory

class SkillFactory {
    
    // MARK: - Warrior Skills
    
    static func createPowerStrike() -> Skill {
        return Skill(
            name: "Power Strike",
            description: "A powerful physical attack that deals extra damage",
            mpCost: 8,
            power: 25,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "power_strike"
        )
    }
    
    static func createDefensiveStance() -> Skill {
        return Skill(
            name: "Defensive Stance",
            description: "Increases defense for several turns",
            mpCost: 6,
            power: 0,
            targetType: .self,
            animationName: "defensive_stance",
            statusEffect: "defense_up",
            statusDuration: 3
        )
    }
    
    // MARK: - Mage Skills
    
    static func createFirebolt() -> Skill {
        return Skill(
            name: "Firebolt",
            description: "A magical fire attack that may burn the target",
            mpCost: 12,
            power: 30,
            damageType: .magical,
            targetType: .singleEnemy,
            animationName: "firebolt",
            statusEffect: "burn",
            statusDuration: 2
        )
    }
    
    static func createIceShard() -> Skill {
        return Skill(
            name: "Ice Shard",
            description: "A magical ice attack that may slow the target",
            mpCost: 10,
            power: 22,
            damageType: .magical,
            targetType: .singleEnemy,
            animationName: "ice_shard",
            statusEffect: "slow",
            statusDuration: 3
        )
    }
    
    static func createLightning() -> Skill {
        return Skill(
            name: "Lightning",
            description: "A fast magical attack that hits all enemies",
            mpCost: 20,
            power: 18,
            damageType: .magical,
            targetType: .allEnemies,
            animationName: "lightning"
        )
    }
    
    // MARK: - Cleric Skills
    
    static func createHeal() -> Skill {
        return Skill(
            name: "Heal",
            description: "Restores HP to a single ally",
            mpCost: 8,
            power: 0,
            targetType: .singleAlly,
            animationName: "heal",
            healPower: 35
        )
    }
    
    static func createGroupHeal() -> Skill {
        return Skill(
            name: "Group Heal",
            description: "Restores HP to all allies",
            mpCost: 18,
            power: 0,
            targetType: .allAllies,
            animationName: "group_heal",
            healPower: 25
        )
    }
    
    static func createBless() -> Skill {
        return Skill(
            name: "Bless",
            description: "Increases all stats of an ally temporarily",
            mpCost: 12,
            power: 0,
            targetType: .singleAlly,
            animationName: "bless",
            buffStats: ["attack": 5, "defense": 5, "magic": 5],
            statusEffect: "blessed",
            statusDuration: 4
        )
    }
    
    // MARK: - Rogue Skills
    
    static func createBackstab() -> Skill {
        return Skill(
            name: "Backstab",
            description: "A critical strike that deals high damage",
            mpCost: 10,
            power: 35,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "backstab"
        )
    }
    
    static func createSmokeScreen() -> Skill {
        return Skill(
            name: "Smoke Screen",
            description: "Reduces accuracy of all enemies",
            mpCost: 8,
            power: 0,
            targetType: .allEnemies,
            animationName: "smoke_screen",
            statusEffect: "blinded",
            statusDuration: 3
        )
    }
    
    static func createQuickStrike() -> Skill {
        return Skill(
            name: "Quick Strike",
            description: "A fast attack with low MP cost",
            mpCost: 4,
            power: 15,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "quick_strike"
        )
    }
    
    // MARK: - Archer Skills
    
    static func createPiercingShot() -> Skill {
        return Skill(
            name: "Piercing Shot",
            description: "An arrow that hits all enemies in a line",
            mpCost: 12,
            power: 20,
            damageType: .physical,
            targetType: .allEnemies,
            animationName: "piercing_shot"
        )
    }
    
    static func createAimedShot() -> Skill {
        return Skill(
            name: "Aimed Shot",
            description: "A precise shot that always hits critically",
            mpCost: 15,
            power: 40,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "aimed_shot"
        )
    }
    
    // MARK: - Utility Skills
    
    static func createDispel() -> Skill {
        return Skill(
            name: "Dispel",
            description: "Removes all status effects from target",
            mpCost: 6,
            power: 0,
            targetType: .singleAlly,
            animationName: "dispel",
            statusEffect: "dispel",
            statusDuration: 1
        )
    }
    
    static func createRegenerate() -> Skill {
        return Skill(
            name: "Regenerate",
            description: "Gradually restores HP over several turns",
            mpCost: 10,
            power: 0,
            targetType: .singleAlly,
            animationName: "regenerate",
            statusEffect: "regeneration",
            statusDuration: 5
        )
    }
    
    // MARK: - Enemy Skills
    
    static func createBite() -> Skill {
        return Skill(
            name: "Bite",
            description: "A vicious bite attack",
            mpCost: 3,
            power: 12,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "bite"
        )
    }
    
    static func createRoar() -> Skill {
        return Skill(
            name: "Intimidating Roar",
            description: "Reduces the attack power of all enemies",
            mpCost: 8,
            power: 0,
            targetType: .allEnemies,
            animationName: "roar",
            debuffStats: ["attack": 3],
            statusEffect: "intimidated",
            statusDuration: 3
        )
    }
    
    static func createPoisonSpit() -> Skill {
        return Skill(
            name: "Poison Spit",
            description: "A toxic attack that poisons the target",
            mpCost: 6,
            power: 8,
            damageType: .magical,
            targetType: .singleEnemy,
            animationName: "poison_spit",
            statusEffect: "poison",
            statusDuration: 4
        )
    }
}