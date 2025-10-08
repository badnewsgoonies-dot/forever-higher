import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var gameData = GameDataManager.shared
    @State private var currentView: GameView = .mainMenu
    @State private var selectedUnits: [UnitClass] = []
    @State private var showingUnitSelection = false
    @State private var showingBattle = false
    @State private var currentBattle: BattleManager?
    
    enum GameView {
        case mainMenu
        case unitSelection
        case map
        case battle
        case shop
        case results
        case settings
        case statistics
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Main content
                switch currentView {
                case .mainMenu:
                    mainMenuView
                case .unitSelection:
                    unitSelectionView
                case .map:
                    mapView
                case .battle:
                    if let battle = currentBattle {
                        BattleView(playerUnits: battle.playerUnits, enemyUnits: battle.enemyUnits)
                    }
                case .shop:
                    shopView
                case .results:
                    resultsView
                case .settings:
                    settingsView
                case .statistics:
                    statisticsView
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Main Menu View
    private var mainMenuView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Title
            VStack(spacing: 10) {
                Text("Forever Higher")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Roguelike JRPG")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Menu buttons
            VStack(spacing: 15) {
                if gameData.currentProgress.currentFloor > 1 {
                    MenuButton(title: "Continue Run", icon: "play.fill", color: .green) {
                        continueRun()
                    }
                }
                
                MenuButton(title: "New Run", icon: "plus.circle.fill", color: .blue) {
                    startNewRun()
                }
                
                MenuButton(title: "Statistics", icon: "chart.bar.fill", color: .orange) {
                    currentView = .statistics
                }
                
                MenuButton(title: "Settings", icon: "gear.fill", color: .gray) {
                    currentView = .settings
                }
            }
            
            Spacer()
            
            // Meta progression info
            metaProgressionInfo
        }
        .padding()
    }
    
    private var metaProgressionInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meta Progression")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Runs: \(gameData.metaProgression.totalRuns)")
                    Text("Victories: \(gameData.metaProgression.totalVictories)")
                    Text("Best Floor: \(gameData.metaProgression.bestFloorReached)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Battles Won: \(gameData.metaProgression.totalBattlesWon)")
                    Text("Gold Earned: \(gameData.metaProgression.totalGoldEarned)")
                    Text("Achievements: \(gameData.metaProgression.achievements.count)")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
    }
    
    // MARK: - Unit Selection View
    private var unitSelectionView: some View {
        VStack(spacing: 20) {
            Text("Select Your Party")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Choose up to 4 units for your adventure")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                ForEach(UnitClass.allCases, id: \.self) { unitClass in
                    UnitSelectionCard(
                        unitClass: unitClass,
                        isSelected: selectedUnits.contains(unitClass),
                        isUnlocked: gameData.metaProgression.unlockedClasses.contains(unitClass.rawValue.lowercased())
                    ) {
                        toggleUnitSelection(unitClass)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 20) {
                Button("Back") {
                    currentView = .mainMenu
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Start Adventure") {
                    startAdventure()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedUnits.isEmpty)
            }
        }
        .padding()
    }
    
    // MARK: - Map View
    private var mapView: some View {
        VStack(spacing: 20) {
            // Floor info
            HStack {
                Text("Floor \(gameData.currentProgress.currentFloor)")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("Gold: \(gameData.playerData.gold)")
                    .font(.headline)
                    .foregroundColor(.yellow)
            }
            .padding()
            
            // Map nodes (simplified)
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                    ForEach(generateMapNodes(), id: \.id) { node in
                        MapNodeView(node: node) {
                            selectMapNode(node)
                        }
                    }
                }
                .padding()
            }
            
            // Party status
            partyStatusView
        }
    }
    
    private var partyStatusView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Party Status")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(gameData.playerData.createUnits(), id: \.id) { unit in
                        PartyUnitCard(unit: unit)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Shop View
    private var shopView: some View {
        VStack(spacing: 20) {
            Text("Shop")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Gold: \(gameData.playerData.gold)")
                .font(.headline)
                .foregroundColor(.yellow)
            
            List(RewardGenerator.generateShopItems(playerLevel: gameData.playerData.currentLevel), id: \.id) { item in
                ShopItemRow(item: item) {
                    purchaseItem(item)
                }
            }
            
            Button("Leave Shop") {
                currentView = .map
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Results View
    private var resultsView: some View {
        VStack(spacing: 30) {
            Text("Run Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                Text("Floor Reached: \(gameData.currentProgress.currentFloor)")
                Text("Battles Won: \(gameData.currentProgress.battlesWon)")
                Text("Gold Earned: \(gameData.playerData.gold)")
                Text("Experience Gained: \(gameData.playerData.experience)")
            }
            .font(.headline)
            
            Button("Return to Menu") {
                gameData.resetCurrentRun()
                currentView = .mainMenu
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Settings View
    private var settingsView: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Form {
                Section("Audio") {
                    Toggle("Sound Effects", isOn: Binding(
                        get: { gameData.gameSettings.soundEnabled },
                        set: { gameData.gameSettings.soundEnabled = $0 }
                    ))
                    
                    Toggle("Music", isOn: Binding(
                        get: { gameData.gameSettings.musicEnabled },
                        set: { gameData.gameSettings.musicEnabled = $0 }
                    ))
                }
                
                Section("Gameplay") {
                    Toggle("Show Damage Numbers", isOn: Binding(
                        get: { gameData.gameSettings.showDamageNumbers },
                        set: { gameData.gameSettings.showDamageNumbers = $0 }
                    ))
                    
                    Toggle("Confirm Actions", isOn: Binding(
                        get: { gameData.gameSettings.confirmActions },
                        set: { gameData.gameSettings.confirmActions = $0 }
                    ))
                    
                    Toggle("Auto Save", isOn: Binding(
                        get: { gameData.gameSettings.autoSave },
                        set: { gameData.gameSettings.autoSave = $0 }
                    ))
                }
                
                Section("Data") {
                    Button("Reset All Progress", role: .destructive) {
                        gameData.resetAllProgress()
                    }
                }
            }
            
            Button("Back") {
                currentView = .mainMenu
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Statistics View
    private var statisticsView: some View {
        VStack(spacing: 20) {
            Text("Statistics")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ScrollView {
                VStack(spacing: 15) {
                    StatCard(title: "Total Runs", value: "\(gameData.metaProgression.totalRuns)")
                    StatCard(title: "Victories", value: "\(gameData.metaProgression.totalVictories)")
                    StatCard(title: "Win Rate", value: winRateString)
                    StatCard(title: "Best Floor", value: "\(gameData.metaProgression.bestFloorReached)")
                    StatCard(title: "Total Battles", value: "\(gameData.metaProgression.totalBattlesWon)")
                    StatCard(title: "Total Gold", value: "\(gameData.metaProgression.totalGoldEarned)")
                    StatCard(title: "Achievements", value: "\(gameData.metaProgression.achievements.count)")
                }
            }
            
            Button("Back") {
                currentView = .mainMenu
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    private func startNewRun() {
        selectedUnits = []
        currentView = .unitSelection
    }
    
    private func continueRun() {
        currentView = .map
    }
    
    private func toggleUnitSelection(_ unitClass: UnitClass) {
        if selectedUnits.contains(unitClass) {
            selectedUnits.removeAll { $0 == unitClass }
        } else if selectedUnits.count < 4 {
            selectedUnits.append(unitClass)
        }
    }
    
    private func startAdventure() {
        // Create party units
        gameData.playerData.partyUnits = selectedUnits.enumerated().map { index, unitClass in
            let unit = UnitFactory.createPlayerUnit(name: "\(unitClass.rawValue) \(index + 1)", unitClass: unitClass)
            return UnitData(from: unit)
        }
        
        // Reset run progress
        gameData.currentProgress = GameProgress()
        gameData.playerData.gold = 100
        gameData.playerData.experience = 0
        
        currentView = .map
    }
    
    private func generateMapNodes() -> [MapNode] {
        // Generate simple map nodes for current floor
        let nodeTypes: [MapNode.NodeType] = [.battle, .battle, .elite, .shop, .rest, .treasure]
        
        return nodeTypes.enumerated().map { index, type in
            MapNode(
                id: "node_\(index)",
                type: type,
                position: MapNode.Position(x: index % 3, y: index / 3),
                isCompleted: false,
                connectedNodes: []
            )
        }
    }
    
    private func selectMapNode(_ node: MapNode) {
        switch node.type {
        case .battle, .elite:
            startBattle(isElite: node.type == .elite)
        case .shop:
            currentView = .shop
        case .boss:
            startBossBattle()
        case .rest:
            restAtCampfire()
        case .treasure:
            findTreasure()
        default:
            break
        }
    }
    
    private func startBattle(isElite: Bool = false) {
        let playerUnits = gameData.playerData.createUnits()
        let enemyLevel = isElite ? gameData.currentProgress.currentFloor + 1 : gameData.currentProgress.currentFloor
        
        var enemies: [Unit] = []
        
        if isElite {
            // Elite encounter
            if let dragon = GameTemplates.createEnemyFromTemplate("dragon", level: enemyLevel) {
                enemies.append(dragon)
            }
        } else {
            // Regular encounter
            if let goblin = GameTemplates.createEnemyFromTemplate("goblin", level: enemyLevel) {
                enemies.append(goblin)
            }
            if let orc = GameTemplates.createEnemyFromTemplate("orc", level: enemyLevel) {
                enemies.append(orc)
            }
        }
        
        currentBattle = BattleManager(playerUnits: playerUnits, enemyUnits: enemies)
        setupBattleCallbacks()
        currentView = .battle
    }
    
    private func startBossBattle() {
        let playerUnits = gameData.playerData.createUnits()
        
        if let boss = GameTemplates.createEnemyFromTemplate("dragon", level: gameData.currentProgress.currentFloor + 2) {
            currentBattle = BattleManager(playerUnits: playerUnits, enemyUnits: [boss])
            setupBattleCallbacks()
            currentView = .battle
        }
    }
    
    private func setupBattleCallbacks() {
        currentBattle?.onBattleEnded = { result in
            DispatchQueue.main.async {
                self.handleBattleEnd(result)
            }
        }
    }
    
    private func handleBattleEnd(_ result: BattleManager.BattleResult) {
        switch result {
        case .victory(let rewards):
            gameData.playerData.gold += rewards.gold
            gameData.playerData.experience += rewards.experience
            gameData.currentProgress.battlesWon += 1
            
            StatisticsTracker.recordBattleVictory(currentBattle!)
            
            // Check if run is complete (simplified)
            if gameData.currentProgress.currentFloor >= 10 {
                StatisticsTracker.recordGameEnd(victory: true)
                currentView = .results
            } else {
                gameData.currentProgress.currentFloor += 1
                currentView = .map
            }
            
        case .defeat:
            StatisticsTracker.recordGameEnd(victory: false)
            currentView = .results
            
        case .escaped:
            currentView = .map
        }
        
        currentBattle = nil
    }
    
    private func restAtCampfire() {
        // Heal all units
        for unit in gameData.playerData.createUnits() {
            unit.fullRestore()
        }
        
        // Update saved data
        gameData.playerData.partyUnits = gameData.playerData.createUnits().map { UnitData(from: $0) }
        
        currentView = .map
    }
    
    private func findTreasure() {
        // Give random reward
        gameData.playerData.gold += Int.random(in: 50...150)
        
        if let item = GameTemplates.getRandomItem() {
            gameData.playerData.inventory.append(item)
        }
        
        currentView = .map
    }
    
    private func purchaseItem(_ item: ItemData) {
        if gameData.playerData.gold >= item.value {
            gameData.playerData.gold -= item.value
            gameData.playerData.inventory.append(item)
        }
    }
    
    private var winRateString: String {
        let total = gameData.metaProgression.totalRuns
        let victories = gameData.metaProgression.totalVictories
        
        if total == 0 { return "0%" }
        
        let percentage = (Double(victories) / Double(total)) * 100
        return String(format: "%.1f%%", percentage)
    }
}

// MARK: - Supporting Views

struct MenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(10)
        }
    }
}

struct UnitSelectionCard: View {
    let unitClass: UnitClass
    let isSelected: Bool
    let isUnlocked: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Unit icon
                RoundedRectangle(cornerRadius: 8)
                    .fill(unitColor)
                    .frame(height: 80)
                    .overlay(
                        Text(unitClass.rawValue.prefix(1))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text(unitClass.rawValue)
                    .font(.headline)
                    .fontWeight(.medium)
                
                // Stats preview
                let stats = unitClass.baseStats
                VStack(alignment: .leading, spacing: 2) {
                    Text("HP: \(stats.hp)")
                    Text("MP: \(stats.mp)")
                    Text("ATK: \(stats.attack)")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.5)
    }
    
    private var unitColor: Color {
        switch unitClass {
        case .warrior: return .red
        case .mage: return .blue
        case .rogue: return .green
        case .cleric: return .yellow
        }
    }
}

struct MapNodeView: View {
    let node: MapNode
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: nodeIcon)
                    .font(.title)
                    .foregroundColor(nodeColor)
                
                Text(nodeTitle)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(nodeColor, lineWidth: 2)
                    )
            )
        }
    }
    
    private var nodeIcon: String {
        switch node.type {
        case .battle: return "sword.fill"
        case .elite: return "crown.fill"
        case .boss: return "flame.fill"
        case .shop: return "bag.fill"
        case .rest: return "flame"
        case .treasure: return "gift.fill"
        case .upgrade: return "arrow.up.circle.fill"
        case .event: return "questionmark.circle.fill"
        }
    }
    
    private var nodeColor: Color {
        switch node.type {
        case .battle: return .red
        case .elite: return .purple
        case .boss: return .orange
        case .shop: return .yellow
        case .rest: return .green
        case .treasure: return .blue
        case .upgrade: return .cyan
        case .event: return .gray
        }
    }
    
    private var nodeTitle: String {
        switch node.type {
        case .battle: return "Battle"
        case .elite: return "Elite"
        case .boss: return "Boss"
        case .shop: return "Shop"
        case .rest: return "Rest"
        case .treasure: return "Treasure"
        case .upgrade: return "Upgrade"
        case .event: return "Event"
        }
    }
}

struct PartyUnitCard: View {
    let unit: Unit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(unit.name)
                .font(.caption.bold())
                .foregroundColor(.blue)
            
            ProgressView(value: Double(unit.currentHP), total: Double(unit.maxHP))
                .progressViewStyle(LinearProgressViewStyle(tint: .red))
                .scaleEffect(y: 0.5)
            
            Text("HP: \(unit.currentHP)/\(unit.maxHP)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if unit.maxMP > 0 {
                ProgressView(value: Double(unit.currentMP), total: Double(unit.maxMP))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 0.5)
                
                Text("MP: \(unit.currentMP)/\(unit.maxMP)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .frame(width: 100)
    }
}

struct ShopItemRow: View {
    let item: ItemData
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.rarity.rawValue.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            VStack {
                Text("\(item.value)")
                    .font(.headline)
                    .foregroundColor(.yellow)
                
                Button("Buy") {
                    onPurchase()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}