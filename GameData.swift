import Foundation

// MARK: - Game Data Manager
class GameData: ObservableObject {
    static let shared = GameData()
    
    // MARK: - Meta Progression
    @Published var metaProgression = MetaProgression()
    @Published var currentRun = RunData()
    
    // MARK: - Game Content
    let encounters: [EncounterData] = [
        EncounterData(
            id: "goblin_pack",
            name: "Goblin Pack",
            description: "A group of weak goblins",
            enemies: [
                EnemyData(name: "Goblin Scout", level: 1),
                EnemyData(name: "Goblin Warrior", level: 1)
            ],
            difficulty: 1,
            rewards: RewardData(exp: 75, gold: 50, items: ["health_potion"])
        ),
        
        EncounterData(
            id: "orc_patrol",
            name: "Orc Patrol",
            description: "Dangerous orc warriors",
            enemies: [
                EnemyData(name: "Orc Brute", level: 2),
                EnemyData(name: "Orc Shaman", level: 2)
            ],
            difficulty: 2,
            rewards: RewardData(exp: 120, gold: 80, items: ["mana_potion", "health_potion"])
        ),
        
        EncounterData(
            id: "skeleton_ambush",
            name: "Skeleton Ambush",
            description: "Undead creatures attack!",
            enemies: [
                EnemyData(name: "Skeleton Warrior", level: 2),
                EnemyData(name: "Skeleton Mage", level: 2),
                EnemyData(name: "Skeleton Archer", level: 1)
            ],
            difficulty: 3,
            rewards: RewardData(exp: 150, gold: 100, items: ["magic_scroll"])
        )
    ]
    
    private init() {
        loadGameData()
    }
    
    // MARK: - Save/Load System
    private func loadGameData() {
        // In a full implementation, load from UserDefaults or files
        // For now, use defaults
        if metaProgression.unlockedClasses.isEmpty {
            metaProgression.unlockedClasses = [.warrior, .mage, .rogue, .cleric]
        }
    }
    
    func saveGameData() {
        // In a full implementation, save to UserDefaults or files
        print("💾 Game data saved")
    }
    
    // MARK: - Run Management
    func startNewRun(with selectedClasses: [UnitClass]) {
        currentRun = RunData()
        currentRun.isActive = true
        currentRun.selectedClasses = selectedClasses
        currentRun.floor = 1
        currentRun.gold = 0
        currentRun.inventory = ["health_potion", "health_potion", "mana_potion"]
        
        print("🚀 New run started with: \(selectedClasses.map { $0.rawValue }.joined(separator: ", "))")
        saveGameData()
    }
    
    func endRun(victory: Bool) {
        if victory {
            metaProgression.bestFloor = max(metaProgression.bestFloor, currentRun.floor)
            metaProgression.totalGoldEarned += currentRun.gold
        }
        
        metaProgression.totalRuns += 1
        currentRun.isActive = false
        
        print(victory ? "🎉 Run completed successfully!" : "💀 Run ended in defeat")
        saveGameData()
    }
    
    func advanceFloor() {
        currentRun.floor += 1
        saveGameData()
    }
    
    // MARK: - Meta Progression
    func addExperience(_ amount: Int) {
        metaProgression.totalExp += amount
        
        let newLevel = calculateLevel(from: metaProgression.totalExp)
        if newLevel > metaProgression.level {
            let levelsGained = newLevel - metaProgression.level
            metaProgression.level = newLevel
            metaProgression.skillPoints += levelsGained
            
            print("🆙 Level up! New level: \(newLevel) (+\(levelsGained) skill points)")
        }
        
        saveGameData()
    }
    
    private func calculateLevel(from exp: Int) -> Int {
        // Level formula: 100 exp for level 2, then +50 exp per level
        if exp < 100 { return 1 }
        return 2 + (exp - 100) / 50
    }
    
    // MARK: - Unit Creation
    func createPlayerTeam(from classes: [UnitClass]) -> [Unit] {
        var team: [Unit] = []
        
        for (index, unitClass) in classes.enumerated() {
            let name = "\(unitClass.rawValue) \(index + 1)"
            let unit = UnitFactory.createPlayerUnit(name: name, unitClass: unitClass)
            
            // Apply meta progression bonuses
            applyMetaProgressionBonuses(to: unit)
            
            team.append(unit)
        }
        
        return team
    }
    
    func createEnemyTeam(from encounter: EncounterData) -> [Unit] {
        return encounter.enemies.map { enemyData in
            UnitFactory.createEnemyUnit(name: enemyData.name, level: enemyData.level)
        }
    }
    
    private func applyMetaProgressionBonuses(to unit: Unit) {
        // Apply permanent upgrades based on meta progression
        // This is where you'd modify unit stats based on purchased upgrades
        
        // Example: +5 HP per meta level
        let bonusHP = (metaProgression.level - 1) * 5
        // In a full implementation, you'd modify the unit's maxHP here
        
        print("Applied meta bonuses to \(unit.name): +\(bonusHP) HP")
    }
    
    // MARK: - Encounter Selection
    func getRandomEncounter(for floor: Int) -> EncounterData {
        let availableEncounters = encounters.filter { $0.difficulty <= floor }
        return availableEncounters.randomElement() ?? encounters.first!
    }
    
    func getEncounterById(_ id: String) -> EncounterData? {
        return encounters.first { $0.id == id }
    }
    
    // MARK: - Inventory Management
    func addItemToInventory(_ item: String) {
        currentRun.inventory.append(item)
        saveGameData()
    }
    
    func removeItemFromInventory(_ item: String) -> Bool {
        if let index = currentRun.inventory.firstIndex(of: item) {
            currentRun.inventory.remove(at: index)
            saveGameData()
            return true
        }
        return false
    }
    
    func getItemCount(_ item: String) -> Int {
        return currentRun.inventory.filter { $0 == item }.count
    }
}

// MARK: - Data Structures

struct MetaProgression: Codable {
    var level: Int = 1
    var totalExp: Int = 0
    var skillPoints: Int = 0
    var totalRuns: Int = 0
    var bestFloor: Int = 0
    var totalGoldEarned: Int = 0
    var unlockedClasses: [UnitClass] = []
    var permanentUpgrades: [String: Int] = [:]
    
    // Permanent upgrade costs
    var upgradeCosts: [String: Int] {
        return [
            "bonus_hp": 100,
            "bonus_mp": 80,
            "bonus_attack": 120,
            "bonus_defense": 100,
            "starting_gold": 150
        ]
    }
}

struct RunData: Codable {
    var isActive: Bool = false
    var floor: Int = 1
    var gold: Int = 0
    var selectedClasses: [UnitClass] = []
    var inventory: [String] = []
    var completedEncounters: [String] = []
    
    mutating func reset() {
        isActive = false
        floor = 1
        gold = 0
        selectedClasses.removeAll()
        inventory.removeAll()
        completedEncounters.removeAll()
    }
}

struct EncounterData: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let enemies: [EnemyData]
    let difficulty: Int
    let rewards: RewardData
}

struct EnemyData: Codable {
    let name: String
    let level: Int
}

struct RewardData: Codable {
    let exp: Int
    let gold: Int
    let items: [String]
}

// MARK: - Item System (Simplified)
struct ItemData {
    let id: String
    let name: String
    let description: String
    let type: ItemType
    let value: Int
    
    enum ItemType {
        case consumable
        case equipment
        case key
    }
    
    static let items: [String: ItemData] = [
        "health_potion": ItemData(
            id: "health_potion",
            name: "Health Potion",
            description: "Restores 50 HP",
            type: .consumable,
            value: 50
        ),
        
        "mana_potion": ItemData(
            id: "mana_potion",
            name: "Mana Potion",
            description: "Restores 30 MP",
            type: .consumable,
            value: 30
        ),
        
        "magic_scroll": ItemData(
            id: "magic_scroll",
            name: "Magic Scroll",
            description: "Teaches a random spell",
            type: .consumable,
            value: 0
        )
    ]
    
    static func getItem(_ id: String) -> ItemData? {
        return items[id]
    }
}