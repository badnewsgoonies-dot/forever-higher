# Forever Higher - Roguelike JRPG Foundation

A comprehensive Swift implementation of the foundational systems for a roguelike JRPG, designed for Swift Playgrounds on iPad.

## 🎮 Project Overview

Forever Higher combines:
- **Golden Sun's** turn-based battle mechanics
- **Pokemon Battle Tower's** progression system  
- **Slay the Spire's** path selection gameplay

This is a gameplay-focused implementation that strips away art and aesthetics to concentrate purely on functional game systems.

## 📁 File Structure

### Core System Files

1. **`Unit.swift`** - The foundational Unit class with complete battle mechanics
2. **`Skill.swift`** - Comprehensive skill system with various effects
3. **`GameData.swift`** - Data management, templates, and save system
4. **`BattleSystem.swift`** - Complete battle manager and SpriteKit integration
5. **`TestBattleDemo.swift`** - Comprehensive testing and demo system
6. **`ContentView.swift`** - SwiftUI interface for Swift Playgrounds

## 🛠️ Core Features Implemented

### Unit System
- ✅ Complete stat system (HP, MP, Attack, Defense, Magic, Speed)
- ✅ Battle state management (current HP/MP, status effects, defending)
- ✅ Damage calculation with type resistance
- ✅ Healing and MP restoration
- ✅ Status effect system with duration tracking
- ✅ Unit factory for easy creation

### Skill System
- ✅ Comprehensive skill framework with multiple effect types
- ✅ MP cost system
- ✅ Damage, healing, and status effect skills
- ✅ Target type system (single/all enemies/allies, self)
- ✅ Skill factory with pre-built abilities for all classes

### Battle System
- ✅ Turn-based combat with player/enemy phases
- ✅ Action system (Attack, Skill, Item, Defend)
- ✅ AI system for enemy behavior
- ✅ Battle state management
- ✅ SpriteKit integration with visual feedback
- ✅ Delegate pattern for UI updates

### Data Management
- ✅ Template system for units and skills
- ✅ JSON-ready data structures
- ✅ Save/load system foundation
- ✅ Meta-progression tracking
- ✅ Run data management

## 🎯 Unit Classes Available

### Player Units
- **Warrior** - High HP/Defense, physical attacks, defensive abilities
- **Mage** - High MP/Magic, elemental spells, area attacks  
- **Rogue** - High Speed, critical strikes, debuff abilities
- **Cleric** - Balanced stats, healing spells, buff abilities

### Enemy Units
- **Goblin** - Fast, weak enemy with quick attacks
- **Orc** - Strong, slow enemy with powerful attacks
- **Skeleton Mage** - Magical enemy with elemental spells

## 🔧 How to Use in Swift Playgrounds

1. **Copy all Swift files** to your Swift Playgrounds project
2. **Set ContentView as your main view** in App.swift:
   ```swift
   import SwiftUI

   @main
   struct MyApp: App {
       var body: some Scene {
           WindowGroup {
               ContentView()
           }
       }
   }
   ```
3. **Run the app** and use the interface to:
   - Select units for your team
   - Start battle demos
   - Run comprehensive tests
   - View game statistics

## 🧪 Testing System

The project includes comprehensive tests accessible through:

### In-App Testing
- Tap "Run Unit Tests" in the main interface
- Check the console output for detailed test results

### Manual Testing
```swift
// Run all tests
TestBattleDemo.runAllTests()

// Run specific test suites
TestBattleDemo.runBasicUnitTests()
TestBattleDemo.runBattleSystemTests()
TestBattleDemo.runGameDataTests()
```

## 🎲 Example Usage

### Creating Units
```swift
// Using factory methods
let warrior = UnitFactory.createWarrior(name: "Hero")
let mage = UnitFactory.createMage(name: "Wizard")

// Using GameData templates
let goblin = GameData.shared.createUnit(from: "goblin")
```

### Battle System
```swift
let battleManager = BattleManager()
battleManager.delegate = self // Implement BattleManagerDelegate

let playerTeam = [warrior, mage]
let enemyTeam = [goblin, orc]

battleManager.startBattle(playerTeam: playerTeam, enemyTeam: enemyTeam)
```

### Using Skills
```swift
let firebolt = SkillFactory.createFirebolt()
let canUse = firebolt.canUse(by: mage)

if canUse {
    let success = mage.useSkill(firebolt, on: [goblin])
}
```

## 🔄 Next Development Steps

1. **Map System** - Implement Slay the Spire style path selection
2. **Item System** - Add consumables and equipment
3. **UI Polish** - Enhanced battle interface and animations
4. **More Content** - Additional units, skills, and encounters
5. **Persistence** - Full JSON save/load implementation
6. **Balance** - Fine-tune combat mathematics

## 📊 System Architecture

```
GameData (Singleton)
├── Unit Templates
├── Skill Templates  
├── Encounter Templates
├── Meta Progression
└── Current Run Data

BattleManager
├── Battle State
├── Unit Management
├── Action Processing
├── AI System
└── SpriteKit Integration

Unit System
├── Base Stats
├── Current Stats
├── Skills
├── Status Effects
└── Battle Actions
```

## 🎮 Combat Flow

1. **Battle Start** - Initialize units, calculate rewards
2. **Player Phase** - Each player unit can act
3. **Enemy Phase** - AI controls enemy actions
4. **Status Processing** - Handle ongoing effects
5. **Victory Check** - Determine battle outcome
6. **Rewards** - Apply EXP, gold, and progression

## 💡 Design Philosophy

- **Modular Architecture** - Each system is independent and testable
- **Data-Driven** - Game content defined in templates, not code
- **Touch-Friendly** - Designed specifically for iPad interaction
- **Performance-First** - Efficient algorithms suitable for mobile
- **Extensible** - Easy to add new units, skills, and mechanics

## 🚀 Ready to Build

This foundation provides everything needed to start building your roguelike JRPG:

- Complete battle system with AI
- Flexible unit and skill framework  
- Data management and persistence
- Testing and debugging tools
- SwiftUI interface ready for expansion

Copy the files to Swift Playgrounds and start building your adventure! 🎉