import Foundation

// MARK: - Game Data Manager

class GameData {
    static let shared = GameData()
    
    // MARK: - File Paths
    private let unitsFileName = "units.json"
    private let skillsFileName = "skills.json"
    private let encountersFileName = "encounters.json"
    private let saveFileName = "save_data.json"
    
    // MARK: - Game Data
    var unitTemplates: [String: UnitTemplate] = [:]
    var skillTemplates: [String: SkillTemplate] = [:]
    var encounterTemplates: [String: EncounterTemplate] = [:]
    
    // MARK: - Save Data
    var metaProgression: MetaProgression = MetaProgression()
    var currentRunData: RunData = RunData()
    
    private init() {
        loadAllData()
    }
    
    // MARK: - Data Loading
    
    func loadAllData() {
        loadUnitTemplates()
        loadSkillTemplates()
        loadEncounterTemplates()
        loadSaveData()
    }
    
    private func loadUnitTemplates() {
        // Create default unit templates if file doesn't exist
        createDefaultUnitTemplates()
        
        // In a full implementation, you would load from JSON file:
        // if let data = loadJSONFile(unitsFileName) { ... }
    }
    
    private func loadSkillTemplates() {
        // Create default skill templates
        createDefaultSkillTemplates()
    }
    
    private func loadEncounterTemplates() {
        // Create default encounter templates
        createDefaultEncounterTemplates()
    }
    
    private func loadSaveData() {
        // In a full implementation, load from JSON file
        // For now, use defaults
        metaProgression = MetaProgression()
        currentRunData = RunData()
    }
    
    // MARK: - Data Saving
    
    func saveGameData() {
        // In a full implementation, save to JSON files
        print("Game data saved (placeholder)")
    }
    
    // MARK: - Unit Creation
    
    func createUnit(from templateId: String) -> Unit? {
        guard let template = unitTemplates[templateId] else {
            print("Unit template not found: \(templateId)")
            return nil
        }
        
        let unit = Unit(
            name: template.name,
            unitClass: template.unitClass,
            maxHP: template.baseStats.hp,
            maxMP: template.baseStats.mp,
            attack: template.baseStats.attack,
            defense: template.baseStats.defense,
            magic: template.baseStats.magic,
            speed: template.baseStats.speed,
            spritePath: template.spritePath,
            description: template.description
        )
        
        // Add skills from template
        for skillId in template.skillIds {
            if let skill = createSkill(from: skillId) {
                unit.addSkill(skill)
            }
        }
        
        return unit
    }
    
    func createSkill(from templateId: String) -> Skill? {
        guard let template = skillTemplates[templateId] else {
            print("Skill template not found: \(templateId)")
            return nil
        }
        
        return Skill(
            name: template.name,
            description: template.description,
            mpCost: template.mpCost,
            power: template.power,
            damageType: template.damageType,
            targetType: template.targetType,
            animationName: template.animationName,
            iconPath: template.iconPath,
            healPower: template.healPower,
            buffStats: template.buffStats,
            debuffStats: template.debuffStats,
            statusEffect: template.statusEffect,
            statusDuration: template.statusDuration
        )
    }
    
    // MARK: - Meta Progression
    
    func addMetaExp(_ amount: Int) {
        metaProgression.totalExp += amount
        
        // Check for level up
        let newLevel = calculateLevel(from: metaProgression.totalExp)
        if newLevel > metaProgression.level {
            metaProgression.level = newLevel
            metaProgression.skillPoints += (newLevel - metaProgression.level)
            print("Level up! New level: \(newLevel)")
        }
    }
    
    private func calculateLevel(from exp: Int) -> Int {
        // Simple level calculation: 100 exp per level
        return max(1, exp / 100 + 1)
    }
    
    // MARK: - Default Data Creation
    
    private func createDefaultUnitTemplates() {
        // Player unit templates
        unitTemplates["warrior"] = UnitTemplate(
            id: "warrior",
            name: "Warrior",
            unitClass: .warrior,
            baseStats: StatBlock(hp: 120, mp: 20, attack: 15, defense: 12, magic: 3, speed: 6),
            skillIds: ["power_strike", "defensive_stance"],
            spritePath: "warrior_sprite",
            description: "A sturdy melee fighter with high HP and defense"
        )
        
        unitTemplates["mage"] = UnitTemplate(
            id: "mage",
            name: "Mage",
            unitClass: .mage,
            baseStats: StatBlock(hp: 80, mp: 50, attack: 6, defense: 4, magic: 18, speed: 8),
            skillIds: ["firebolt", "heal"],
            spritePath: "mage_sprite",
            description: "A magical damage dealer with high MP and magic power"
        )
        
        unitTemplates["rogue"] = UnitTemplate(
            id: "rogue",
            name: "Rogue",
            unitClass: .rogue,
            baseStats: StatBlock(hp: 90, mp: 30, attack: 12, defense: 6, magic: 5, speed: 15),
            skillIds: ["backstab", "smoke_screen"],
            spritePath: "rogue_sprite",
            description: "A fast attacker with high speed and critical hits"
        )
        
        unitTemplates["cleric"] = UnitTemplate(
            id: "cleric",
            name: "Cleric",
            unitClass: .cleric,
            baseStats: StatBlock(hp: 100, mp: 40, attack: 8, defense: 8, magic: 14, speed: 7),
            skillIds: ["heal", "bless"],
            spritePath: "cleric_sprite",
            description: "A support unit specializing in healing and buffs"
        )
        
        // Enemy unit templates
        unitTemplates["goblin"] = UnitTemplate(
            id: "goblin",
            name: "Goblin",
            unitClass: .rogue,
            baseStats: StatBlock(hp: 60, mp: 15, attack: 10, defense: 4, magic: 2, speed: 12),
            skillIds: ["quick_strike"],
            spritePath: "goblin_sprite",
            description: "A weak but fast enemy"
        )
        
        unitTemplates["orc"] = UnitTemplate(
            id: "orc",
            name: "Orc",
            unitClass: .warrior,
            baseStats: StatBlock(hp: 100, mp: 10, attack: 18, defense: 8, magic: 1, speed: 4),
            skillIds: ["power_strike"],
            spritePath: "orc_sprite",
            description: "A strong but slow enemy"
        )
        
        unitTemplates["skeleton_mage"] = UnitTemplate(
            id: "skeleton_mage",
            name: "Skeleton Mage",
            unitClass: .mage,
            baseStats: StatBlock(hp: 70, mp: 35, attack: 4, defense: 3, magic: 15, speed: 6),
            skillIds: ["firebolt", "ice_shard"],
            spritePath: "skeleton_mage_sprite",
            description: "An undead spellcaster"
        )
    }
    
    private func createDefaultSkillTemplates() {
        // Warrior skills
        skillTemplates["power_strike"] = SkillTemplate(
            id: "power_strike",
            name: "Power Strike",
            description: "A powerful physical attack that deals extra damage",
            mpCost: 8,
            power: 25,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "power_strike"
        )
        
        skillTemplates["defensive_stance"] = SkillTemplate(
            id: "defensive_stance",
            name: "Defensive Stance",
            description: "Increases defense for several turns",
            mpCost: 6,
            targetType: .self,
            animationName: "defensive_stance",
            statusEffect: "defense_up",
            statusDuration: 3
        )
        
        // Mage skills
        skillTemplates["firebolt"] = SkillTemplate(
            id: "firebolt",
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
        
        skillTemplates["ice_shard"] = SkillTemplate(
            id: "ice_shard",
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
        
        // Cleric skills
        skillTemplates["heal"] = SkillTemplate(
            id: "heal",
            name: "Heal",
            description: "Restores HP to a single ally",
            mpCost: 8,
            targetType: .singleAlly,
            animationName: "heal",
            healPower: 35
        )
        
        skillTemplates["bless"] = SkillTemplate(
            id: "bless",
            name: "Bless",
            description: "Increases all stats of an ally temporarily",
            mpCost: 12,
            targetType: .singleAlly,
            animationName: "bless",
            buffStats: ["attack": 5, "defense": 5, "magic": 5],
            statusEffect: "blessed",
            statusDuration: 4
        )
        
        // Rogue skills
        skillTemplates["backstab"] = SkillTemplate(
            id: "backstab",
            name: "Backstab",
            description: "A critical strike that deals high damage",
            mpCost: 10,
            power: 35,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "backstab"
        )
        
        skillTemplates["smoke_screen"] = SkillTemplate(
            id: "smoke_screen",
            name: "Smoke Screen",
            description: "Reduces accuracy of all enemies",
            mpCost: 8,
            targetType: .allEnemies,
            animationName: "smoke_screen",
            statusEffect: "blinded",
            statusDuration: 3
        )
        
        skillTemplates["quick_strike"] = SkillTemplate(
            id: "quick_strike",
            name: "Quick Strike",
            description: "A fast attack with low MP cost",
            mpCost: 4,
            power: 15,
            damageType: .physical,
            targetType: .singleEnemy,
            animationName: "quick_strike"
        )
    }
    
    private func createDefaultEncounterTemplates() {
        encounterTemplates["easy_goblins"] = EncounterTemplate(
            id: "easy_goblins",
            name: "Goblin Pack",
            description: "A small group of goblins",
            enemyIds: ["goblin", "goblin"],
            difficulty: 1,
            rewards: RewardTemplate(exp: 50, gold: 30, itemIds: [])
        )
        
        encounterTemplates["mixed_enemies"] = EncounterTemplate(
            id: "mixed_enemies",
            name: "Orc and Goblin",
            description: "An orc leading a goblin",
            enemyIds: ["orc", "goblin"],
            difficulty: 2,
            rewards: RewardTemplate(exp: 80, gold: 50, itemIds: [])
        )
        
        encounterTemplates["skeleton_mages"] = EncounterTemplate(
            id: "skeleton_mages",
            name: "Undead Casters",
            description: "Dangerous skeleton mages",
            enemyIds: ["skeleton_mage", "skeleton_mage"],
            difficulty: 3,
            rewards: RewardTemplate(exp: 120, gold: 75, itemIds: [])
        )
    }
}

// MARK: - Data Templates

struct UnitTemplate: Codable {
    let id: String
    let name: String
    let unitClass: UnitClass
    let baseStats: StatBlock
    let skillIds: [String]
    let spritePath: String
    let description: String
}

struct SkillTemplate: Codable {
    let id: String
    let name: String
    let description: String
    let mpCost: Int
    let power: Int
    let damageType: DamageType
    let targetType: TargetType
    let animationName: String
    let iconPath: String
    let healPower: Int
    let buffStats: [String: Int]
    let debuffStats: [String: Int]
    let statusEffect: String
    let statusDuration: Int
    
    init(id: String,
         name: String,
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
        
        self.id = id
        self.name = name
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
}

struct EncounterTemplate: Codable {
    let id: String
    let name: String
    let description: String
    let enemyIds: [String]
    let difficulty: Int
    let rewards: RewardTemplate
}

struct RewardTemplate: Codable {
    let exp: Int
    let gold: Int
    let itemIds: [String]
}

struct StatBlock: Codable {
    let hp: Int
    let mp: Int
    let attack: Int
    let defense: Int
    let magic: Int
    let speed: Int
}

// MARK: - Save Data Structures

struct MetaProgression: Codable {
    var level: Int = 1
    var totalExp: Int = 0
    var skillPoints: Int = 0
    var totalRuns: Int = 0
    var bestFloor: Int = 0
    var totalGoldEarned: Int = 0
    var unlockedUnits: Set<String> = ["warrior", "mage", "rogue", "cleric"]
    var permanentUpgrades: [String: Int] = [:]
}

struct RunData: Codable {
    var floor: Int = 1
    var gold: Int = 0
    var playerUnits: [String] = [] // Unit template IDs
    var inventory: [String] = [] // Item IDs
    var currentPath: [String] = [] // Node IDs for current run path
    var isActive: Bool = false
    
    mutating func reset() {
        floor = 1
        gold = 0
        playerUnits.removeAll()
        inventory.removeAll()
        currentPath.removeAll()
        isActive = false
    }
    
    mutating func startNewRun(with unitIds: [String]) {
        reset()
        playerUnits = unitIds
        isActive = true
    }
}