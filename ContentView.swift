import SwiftUI
import SpriteKit

// MARK: - Main Content View for Swift Playgrounds

struct ContentView: View {
    @State private var showingBattle = false
    @State private var selectedUnits: [String] = []
    @State private var gameData = GameData.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Title
                Text("Forever Higher")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Roguelike JRPG")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Unit Selection Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Select Your Team")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(["warrior", "mage", "rogue", "cleric"], id: \.self) { unitId in
                            UnitSelectionCard(
                                unitId: unitId,
                                isSelected: selectedUnits.contains(unitId),
                                onTap: {
                                    toggleUnitSelection(unitId)
                                }
                            )
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button("Start Battle Demo") {
                        showingBattle = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(selectedUnits.isEmpty)
                    
                    Button("Run Unit Tests") {
                        TestBattleDemo.runAllTests()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Show Game Stats") {
                        showGameStats()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                
                Spacer()
                
                // Game Info
                VStack(alignment: .leading, spacing: 5) {
                    Text("Meta Progression")
                        .font(.headline)
                    
                    HStack {
                        Text("Level: \(gameData.metaProgression.level)")
                        Spacer()
                        Text("EXP: \(gameData.metaProgression.totalExp)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Runs: \(gameData.metaProgression.totalRuns)")
                        Spacer()
                        Text("Best Floor: \(gameData.metaProgression.bestFloor)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            .navigationTitle("Forever Higher")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingBattle) {
            BattleDemoView(selectedUnits: selectedUnits)
        }
    }
    
    private func toggleUnitSelection(_ unitId: String) {
        if selectedUnits.contains(unitId) {
            selectedUnits.removeAll { $0 == unitId }
        } else if selectedUnits.count < 4 {
            selectedUnits.append(unitId)
        }
    }
    
    private func showGameStats() {
        print("=== GAME STATISTICS ===")
        print("Level: \(gameData.metaProgression.level)")
        print("Total EXP: \(gameData.metaProgression.totalExp)")
        print("Total Runs: \(gameData.metaProgression.totalRuns)")
        print("Best Floor: \(gameData.metaProgression.bestFloor)")
        print("Unlocked Units: \(gameData.metaProgression.unlockedUnits.joined(separator: ", "))")
        print("Current Run Active: \(gameData.currentRunData.isActive)")
        if gameData.currentRunData.isActive {
            print("Current Floor: \(gameData.currentRunData.floor)")
            print("Current Gold: \(gameData.currentRunData.gold)")
        }
        print("========================")
    }
}

// MARK: - Unit Selection Card

struct UnitSelectionCard: View {
    let unitId: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Unit Icon (placeholder)
                RoundedRectangle(cornerRadius: 8)
                    .fill(unitColor)
                    .frame(height: 60)
                    .overlay(
                        Text(unitId.prefix(1).uppercased())
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Unit Name
                Text(unitId.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                
                // Unit Stats (simplified)
                if let unit = GameData.shared.createUnit(from: unitId) {
                    Text("HP: \(unit.maxHP)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var unitColor: Color {
        switch unitId {
        case "warrior": return .red
        case "mage": return .blue
        case "rogue": return .green
        case "cleric": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Battle Demo View

struct BattleDemoView: View {
    let selectedUnits: [String]
    @State private var battleScene: BattleScene?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let scene = battleScene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                } else {
                    VStack(spacing: 20) {
                        Text("Preparing Battle...")
                            .font(.title)
                        
                        ProgressView()
                        
                        Text("Selected Units:")
                            .font(.headline)
                        
                        ForEach(selectedUnits, id: \.self) { unitId in
                            Text("• \(unitId.capitalized)")
                        }
                    }
                    .onAppear {
                        setupBattle()
                    }
                }
            }
            .navigationTitle("Battle Demo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func setupBattle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let scene = BattleScene()
            scene.size = CGSize(width: 800, height: 600)
            scene.scaleMode = .aspectFit
            
            // Create player team from selected units
            let playerTeam = selectedUnits.compactMap { unitId in
                GameData.shared.createUnit(from: unitId)
            }
            
            // Create enemy team
            let enemyTeam = [
                GameData.shared.createUnit(from: "goblin")!,
                GameData.shared.createUnit(from: "orc")!
            ]
            
            // Start battle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scene.battleManager.startBattle(playerTeam: playerTeam, enemyTeam: enemyTeam)
            }
            
            self.battleScene = scene
        }
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
            .opacity(configuration.isPressed ? 0.8 : 1.0)
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
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}