import Foundation
import SwiftUI

// MARK: - Map Node Types
enum MapNodeType: String, CaseIterable, Codable {
    case battle = "battle"
    case shop = "shop"
    case boss = "boss"
    case rest = "rest"
    case elite = "elite"
    case treasure = "treasure"
    case event = "event"
    
    var displayName: String {
        switch self {
        case .battle: return "Battle"
        case .shop: return "Shop"
        case .boss: return "Boss"
        case .rest: return "Rest Site"
        case .elite: return "Elite"
        case .treasure: return "Treasure"
        case .event: return "Event"
        }
    }
    
    var icon: String {
        switch self {
        case .battle: return "sword.fill"
        case .shop: return "bag.fill"
        case .boss: return "crown.fill"
        case .rest: return "flame"
        case .elite: return "star.fill"
        case .treasure: return "gift.fill"
        case .event: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Map Node
class MapNode: Codable, Identifiable, Equatable {
    let id: String
    let type: MapNodeType
    let position: MapPosition
    var isCompleted: Bool
    var isAvailable: Bool
    var connectedNodeIds: [String] = []
    
    // Optional encounter data - removed to maintain Codable compliance
    
    init(id: String, type: MapNodeType, position: MapPosition, connectedNodeIds: [String] = []) {
        self.id = id
        self.type = type
        self.position = position
        self.isCompleted = false
        self.isAvailable = false
        self.connectedNodeIds = connectedNodeIds
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, type, position, isCompleted, isAvailable, connectedNodeIds
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: MapNode, rhs: MapNode) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Map Position
struct MapPosition: Codable, Equatable {
    let x: Int
    let y: Int
    
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
    
    func distance(to other: MapPosition) -> Double {
        let dx = Double(x - other.x)
        let dy = Double(y - other.y)
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Map Path
class MapPath: Codable {
    let id: String
    let floor: Int
    private(set) var nodes: [MapNode]
    private var nodeDict: [String: MapNode] = [:]
    
    init(id: String, floor: Int, nodes: [MapNode]) {
        self.id = id
        self.floor = floor
        self.nodes = nodes
        
        // Build lookup dictionary
        for node in nodes {
            nodeDict[node.id] = node
        }
    }
    
    func getNode(id: String) -> MapNode? {
        return nodeDict[id]
    }
    
    func getConnectedNodes(from nodeId: String) -> [MapNode] {
        guard let node = getNode(id: nodeId) else { return [] }
        return node.connectedNodeIds.compactMap { getNode(id: $0) }
    }
    
    func getNodesAtLayer(y: Int) -> [MapNode] {
        return nodes.filter { $0.position.y == y }
    }
    
    func getStartingNodes() -> [MapNode] {
        return getNodesAtLayer(y: 0)
    }
    
    func getBossNodes() -> [MapNode] {
        return nodes.filter { $0.type == .boss }
    }
}

// MARK: - Map Manager
class MapManager: ObservableObject {
    
    // MARK: - Shared Instance
    static let shared = MapManager()
    
    // MARK: - Properties
    @Published var currentPath: MapPath?
    @Published var currentNodeId: String?
    @Published var visitedNodeIds: Set<String> = []
    
    private let gameData = GameData.shared
    
    // MARK: - Initialization
    private init() {
        loadMapState()
    }
    
    // MARK: - Map Navigation
    func startNewMap(floor: Int) {
        let generator = MapGenerator()
        currentPath = generator.generateMap(floor: floor)
        currentNodeId = nil
        visitedNodeIds.removeAll()
        
        // Make starting nodes available
        updateAvailableNodes()
        saveMapState()
    }
    
    func getCurrentNode() -> MapNode? {
        guard let nodeId = currentNodeId,
              let path = currentPath else { return nil }
        return path.getNode(id: nodeId)
    }
    
    func getAvailableNodes() -> [MapNode] {
        guard let path = currentPath else { return [] }
        
        // If no current node, return starting nodes
        guard let currentNodeId = currentNodeId else {
            return path.getStartingNodes()
        }
        
        // Return connected nodes that aren't completed
        return path.getConnectedNodes(from: currentNodeId)
            .filter { !$0.isCompleted }
    }
    
    func canSelectNode(_ node: MapNode) -> Bool {
        let availableNodes = getAvailableNodes()
        return availableNodes.contains(node)
    }
    
    func selectNode(_ node: MapNode) -> Bool {
        guard canSelectNode(node) else { return false }
        
        // Move to the selected node
        currentNodeId = node.id
        visitedNodeIds.insert(node.id)
        
        // Update available nodes
        updateAvailableNodes()
        
        // Save state
        saveMapState()
        
        return true
    }
    
    func completeCurrentNode() {
        guard let currentNode = getCurrentNode() else { return }
        
        currentNode.isCompleted = true
        updateAvailableNodes()
        saveMapState()
    }
    
    private func updateAvailableNodes() {
        guard let path = currentPath else { return }
        
        // Reset all availability
        for node in path.nodes {
            node.isAvailable = false
        }
        
        // Mark available nodes
        let available = getAvailableNodes()
        for node in available {
            node.isAvailable = true
        }
    }
    
    // MARK: - Map State Persistence
    func saveMapState() {
        guard let path = currentPath else { return }
        
        let mapState = MapState(
            pathId: path.id,
            floor: path.floor,
            currentNodeId: currentNodeId,
            visitedNodeIds: Array(visitedNodeIds),
            nodes: path.nodes
        )
        
        gameData.currentMapState = mapState
    }
    
    func loadMapState() {
        guard let mapState = gameData.currentMapState else { return }
        
        // Reconstruct the map path
        currentPath = MapPath(
            id: mapState.pathId,
            floor: mapState.floor,
            nodes: mapState.nodes
        )
        
        currentNodeId = mapState.currentNodeId
        visitedNodeIds = Set(mapState.visitedNodeIds)
        
        updateAvailableNodes()
    }
    
    // MARK: - Utility Methods
    func getMapProgress() -> (completed: Int, total: Int) {
        guard let path = currentPath else { return (0, 0) }
        
        let completed = path.nodes.filter { $0.isCompleted }.count
        let total = path.nodes.count
        
        return (completed, total)
    }
    
    func isMapComplete() -> Bool {
        guard let path = currentPath else { return false }
        
        // Map is complete when all boss nodes are completed
        let bossNodes = path.getBossNodes()
        return !bossNodes.isEmpty && bossNodes.allSatisfy { $0.isCompleted }
    }
    
    func getNextLayer() -> Int {
        guard let path = currentPath else { return 0 }
        
        let maxY = path.nodes.map { $0.position.y }.max() ?? 0
        return maxY + 1
    }
}

// MARK: - Map Generator
class MapGenerator {
    
    // MARK: - Generation Parameters
    private let layerCount = 8 // Number of layers (excluding boss)
    private let nodesPerLayer = 3 // Base nodes per layer
    private let branchChance = 0.3 // Chance of additional branches
    
    // MARK: - Map Generation
    func generateMap(floor: Int) -> MapPath {
        let pathId = "floor_\(floor)_\(UUID().uuidString.prefix(8))"
        var nodes: [MapNode] = []
        var nodeIdCounter = 0
        
        // Generate layers
        var previousLayerNodes: [MapNode] = []
        
        for layer in 0...layerCount {
            let layerNodes = generateLayer(
                layer: layer,
                floor: floor,
                nodeIdCounter: &nodeIdCounter,
                previousLayerNodes: previousLayerNodes
            )
            
            nodes.append(contentsOf: layerNodes)
            previousLayerNodes = layerNodes
        }
        
        // Connect nodes between layers
        connectLayers(nodes: nodes)
        
        return MapPath(id: pathId, floor: floor, nodes: nodes)
    }
    
    private func generateLayer(
        layer: Int,
        floor: Int,
        nodeIdCounter: inout Int,
        previousLayerNodes: [MapNode]
    ) -> [MapNode] {
        
        var layerNodes: [MapNode] = []
        let nodeCount = calculateNodesForLayer(layer: layer)
        
        for i in 0..<nodeCount {
            let nodeId = "node_\(nodeIdCounter)"
            nodeIdCounter += 1
            
            let nodeType = determineNodeType(layer: layer, position: i, floor: floor)
            let position = MapPosition(i, layer)
            
            let node = MapNode(id: nodeId, type: nodeType, position: position)
            layerNodes.append(node)
        }
        
        return layerNodes
    }
    
    private func calculateNodesForLayer(layer: Int) -> Int {
        if layer == 0 {
            return 1 // Single starting node
        } else if layer == layerCount {
            return 1 // Single boss node
        } else {
            // Vary between 2-4 nodes per layer
            let baseCount = nodesPerLayer
            let variation = Int.random(in: -1...1)
            return max(2, min(4, baseCount + variation))
        }
    }
    
    private func determineNodeType(layer: Int, position: Int, floor: Int) -> MapNodeType {
        // Boss layer
        if layer == layerCount {
            return .boss
        }
        
        // Starting layer
        if layer == 0 {
            return .battle
        }
        
        // Middle layers - distribute node types
        let layerProgress = Double(layer) / Double(layerCount)
        
        // Guaranteed shop every few layers
        if layer % 3 == 0 && position == 0 {
            return .shop
        }
        
        // Rest sites in middle layers
        if layer == layerCount / 2 && position == 1 {
            return .rest
        }
        
        // Elite encounters in later layers
        if layerProgress > 0.6 && Double.random(in: 0...1) < 0.2 {
            return .elite
        }
        
        // Treasure rooms occasionally
        if Double.random(in: 0...1) < 0.1 {
            return .treasure
        }
        
        // Default to battle
        return .battle
    }
    
    private func connectLayers(nodes: [MapNode]) {
        // Group nodes by layer
        let nodesByLayer = Dictionary(grouping: nodes) { $0.position.y }
        let maxLayer = nodes.map { $0.position.y }.max() ?? 0
        
        for layer in 0..<maxLayer {
            guard let currentLayerNodes = nodesByLayer[layer],
                  let nextLayerNodes = nodesByLayer[layer + 1] else { continue }
            
            connectAdjacentLayers(
                currentLayer: currentLayerNodes,
                nextLayer: nextLayerNodes
            )
        }
    }
    
    private func connectAdjacentLayers(currentLayer: [MapNode], nextLayer: [MapNode]) {
        // Ensure each node in current layer connects to at least one node in next layer
        for currentNode in currentLayer {
            let connectionsNeeded = Int.random(in: 1...min(2, nextLayer.count))
            let availableTargets = nextLayer.shuffled()
            
            for i in 0..<connectionsNeeded {
                let targetNode = availableTargets[i]
                currentNode.connectedNodeIds.append(targetNode.id)
            }
        }
        
        // Ensure each node in next layer is reachable
        for nextNode in nextLayer {
            let hasConnection = currentLayer.contains { node in
                node.connectedNodeIds.contains(nextNode.id)
            }
            
            if !hasConnection {
                // Connect from a random current layer node
                let randomCurrentNode = currentLayer.randomElement()!
                randomCurrentNode.connectedNodeIds.append(nextNode.id)
            }
        }
    }
}

// MARK: - Map State (for persistence)
struct MapState: Codable {
    let pathId: String
    let floor: Int
    let currentNodeId: String?
    let visitedNodeIds: [String]
    let nodes: [MapNode]
}

// MARK: - GameTemplates (Simple Implementation)
class GameTemplates {
    
    static func createEnemyFromTemplate(_ type: String, level: Int) -> Unit? {
        switch type.lowercased() {
        case "goblin":
            let goblin = UnitFactory.createGoblin(name: "Goblin")
            scaleUnitToLevel(goblin, level: level)
            return goblin
            
        case "orc":
            let orc = UnitFactory.createOrc(name: "Orc")
            scaleUnitToLevel(orc, level: level)
            return orc
            
        case "skeleton":
            let skeleton = Unit(name: "Skeleton", 
                               unitClass: .rogue,
                               maxHP: 70,
                               maxMP: 20,
                               attack: 12,
                               defense: 6,
                               magic: 4,
                               speed: 10)
            scaleUnitToLevel(skeleton, level: level)
            return skeleton
            
        case "dragon":
            let dragon = Unit(name: "Dragon",
                             unitClass: .mage,
                             maxHP: 200,
                             maxMP: 80,
                             attack: 25,
                             defense: 15,
                             magic: 30,
                             speed: 8)
            scaleUnitToLevel(dragon, level: level)
            return dragon
            
        default:
            return nil
        }
    }
    
    static func getRandomItem() -> ItemData? {
        let itemIds = ["health_potion", "mana_potion", "magic_scroll"]
        guard let randomId = itemIds.randomElement() else { return nil }
        return ItemData.getItem(randomId)
    }
    
    private static func scaleUnitToLevel(_ unit: Unit, level: Int) {
        let multiplier = 1.0 + Double(level - 1) * 0.2
        unit.maxHP = Int(Double(unit.maxHP) * multiplier)
        unit.maxMP = Int(Double(unit.maxMP) * multiplier)
        unit.attack = Int(Double(unit.attack) * multiplier)
        unit.defense = Int(Double(unit.defense) * multiplier)
        unit.magic = Int(Double(unit.magic) * multiplier)
        
        // Initialize current stats to max values
        unit.currentHP = unit.maxHP
        unit.currentMP = unit.maxMP
    }
}

// MARK: - GameData Extension for Player Units and Map State
extension GameData {
    func createPlayerTeam() -> [Unit] {
        return createPlayerTeam(from: currentRun.selectedClasses)
    }
    
    private var mapStateKey: String { "CurrentMapState" }
    
    var currentMapState: MapState? {
        get {
            guard let data = UserDefaults.standard.data(forKey: mapStateKey),
                  let mapState = try? JSONDecoder().decode(MapState.self, from: data) else {
                return nil
            }
            return mapState
        }
        set {
            if let mapState = newValue {
                if let data = try? JSONEncoder().encode(mapState) {
                    UserDefaults.standard.set(data, forKey: mapStateKey)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: mapStateKey)
            }
        }
    }
}

// MARK: - Map Encounter Handler
class MapEncounterHandler {
    
    static func handleNodeSelection(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        switch node.type {
        case .battle:
            handleBattleNode(node, completion: completion)
        case .shop:
            handleShopNode(node, completion: completion)
        case .boss:
            handleBossNode(node, completion: completion)
        case .rest:
            handleRestNode(node, completion: completion)
        case .elite:
            handleEliteNode(node, completion: completion)
        case .treasure:
            handleTreasureNode(node, completion: completion)
        case .event:
            handleEventNode(node, completion: completion)
        }
    }
    
    private static func handleBattleNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        // Create appropriate enemies for battle
        let gameData = GameData.shared
        let floor = gameData.currentRun.floor
        
        let enemies = createEnemiesForFloor(floor)
        let playerUnits = gameData.createPlayerTeam()
        
        // Create and start the battle using the existing BattleManager
        let battleManager = BattleManager()
        battleManager.startBattle(playerTeam: playerUnits, enemyTeam: enemies)
        
        // Monitor battle completion
        // Note: In a real implementation, you'd observe the battle manager's state
        // For now, simulate a battle and then complete the node
        print("Starting battle at node \(node.id) with \(enemies.count) enemies")
        
        // Simulate battle completion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Assume victory for now - in real implementation check battleManager.currentPhase
            let victory = true
            
            if victory {
                // Award experience and gold
                let expGained = enemies.count * 50
                let goldGained = enemies.count * 25
                gameData.addExperience(expGained)
                gameData.currentRun.gold += goldGained
                
                print("Battle won! Gained \(expGained) EXP and \(goldGained) Gold")
                
                // Complete the current map node
                MapManager.shared.completeCurrentNode()
            }
            
            completion(victory)
        }
    }
    
    private static func handleShopNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        print("Entering shop at node \(node.id)")
        // This would open the shop interface
        
        // Complete the current map node
        MapManager.shared.completeCurrentNode()
        
        completion(true)
    }
    
    private static func handleBossNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        print("Starting boss battle at node \(node.id)")
        
        let gameData = GameData.shared
        let floor = gameData.currentRun.floor
        
        // Create a powerful boss enemy
        let bossLevel = floor + 2
        guard let boss = GameTemplates.createEnemyFromTemplate("dragon", level: bossLevel) else {
            completion(false)
            return
        }
        
        let playerUnits = gameData.createPlayerTeam()
        
        // Create and start boss battle
        let battleManager = BattleManager()
        battleManager.startBattle(playerTeam: playerUnits, enemyTeam: [boss])
        
        print("Boss battle started against \(boss.unitName) (Level \(bossLevel))")
        
        // Simulate boss battle completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            let victory = true // Assume victory for now
            
            if victory {
                // Award significant rewards for boss victory
                let expGained = 200
                let goldGained = 150
                gameData.addExperience(expGained)
                gameData.currentRun.gold += goldGained
                
                print("Boss defeated! Gained \(expGained) EXP and \(goldGained) Gold")
                
                // Complete the current map node
                MapManager.shared.completeCurrentNode()
            }
            
            completion(victory)
        }
    }
    
    private static func handleRestNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        print("Resting at node \(node.id)")
        
        // Heal all party members - use the GameData system
        let gameData = GameData.shared
        let playerTeam = gameData.createPlayerTeam()
        
        for unit in playerTeam {
            unit.currentHP = unit.maxHP
            unit.currentMP = unit.maxMP
            print("Healed \(unit.unitName) to full HP/MP")
        }
        
        // Complete the current map node
        MapManager.shared.completeCurrentNode()
        
        completion(true)
    }
    
    private static func handleEliteNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        print("Starting elite battle at node \(node.id)")
        
        let gameData = GameData.shared
        let floor = gameData.currentRun.floor
        
        // Create elite enemies (stronger than regular battles)
        let eliteLevel = floor + 1
        var enemies: [Unit] = []
        
        // Create 1-2 elite enemies
        let enemyCount = Int.random(in: 1...2)
        for i in 0..<enemyCount {
            let enemyTypes = ["orc", "skeleton"]
            let enemyType = enemyTypes.randomElement()!
            
            if let enemy = GameTemplates.createEnemyFromTemplate(enemyType, level: eliteLevel) {
                enemy.unitName = "Elite \(enemy.unitName) \(i + 1)"
                enemies.append(enemy)
            }
        }
        
        let playerUnits = gameData.createPlayerTeam()
        
        // Create and start elite battle
        let battleManager = BattleManager()
        battleManager.startBattle(playerTeam: playerUnits, enemyTeam: enemies)
        
        print("Elite battle started with \(enemies.count) elite enemies")
        
        // Simulate elite battle completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let victory = true // Assume victory for now
            
            if victory {
                // Award better rewards for elite victory
                let expGained = enemies.count * 75
                let goldGained = enemies.count * 50
                gameData.addExperience(expGained)
                gameData.currentRun.gold += goldGained
                
                print("Elite battle won! Gained \(expGained) EXP and \(goldGained) Gold")
                
                // Complete the current map node
                MapManager.shared.completeCurrentNode()
            }
            
            completion(victory)
        }
    }
    
    private static func handleTreasureNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        print("Finding treasure at node \(node.id)")
        
        // Give random rewards using the existing system
        let gameData = GameData.shared
        let goldReward = Int.random(in: 50...150)
        gameData.currentRun.gold += goldReward
        
        if let item = GameTemplates.getRandomItem() {
            gameData.addItemToInventory(item.id)
            print("Found \(item.name)!")
        }
        
        print("Found \(goldReward) gold!")
        
        // Complete the current map node
        MapManager.shared.completeCurrentNode()
        
        completion(true)
    }
    
    private static func handleEventNode(_ node: MapNode, completion: @escaping (Bool) -> Void) {
        print("Random event at node \(node.id)")
        // This would trigger a random event with choices
        
        // Complete the current map node
        MapManager.shared.completeCurrentNode()
        
        completion(true)
    }
    
    private static func createEnemiesForFloor(_ floor: Int) -> [Unit] {
        var enemies: [Unit] = []
        
        // Create enemies based on floor level
        let enemyCount = Int.random(in: 1...3)
        let enemyLevel = max(1, floor)
        
        for i in 0..<enemyCount {
            let enemyTypes = ["goblin", "orc", "skeleton"]
            let enemyType = enemyTypes.randomElement()!
            
            if let enemy = GameTemplates.createEnemyFromTemplate(enemyType, level: enemyLevel) {
                enemy.name = "\(enemy.name) \(i + 1)"
                enemies.append(enemy)
            }
        }
        
        return enemies
    }
}

// MARK: - Map Utilities
extension MapManager {
    
    func getNodesByType(_ type: MapNodeType) -> [MapNode] {
        guard let path = currentPath else { return [] }
        return path.nodes.filter { $0.type == type }
    }
    
    func getCompletedNodes() -> [MapNode] {
        guard let path = currentPath else { return [] }
        return path.nodes.filter { $0.isCompleted }
    }
    
    func getAvailableNodesByType(_ type: MapNodeType) -> [MapNode] {
        return getAvailableNodes().filter { $0.type == type }
    }
    
    func hasVisitedNodeType(_ type: MapNodeType) -> Bool {
        guard let path = currentPath else { return false }
        
        return visitedNodeIds.contains { nodeId in
            guard let node = path.getNode(id: nodeId) else { return false }
            return node.type == type
        }
    }
    
    func getPathSummary() -> String {
        guard let path = currentPath else { return "No active path" }
        
        let progress = getMapProgress()
        let currentNodeType = getCurrentNode()?.type.displayName ?? "None"
        
        return "Floor \(path.floor): \(progress.completed)/\(progress.total) completed, Current: \(currentNodeType)"
    }
}