import SwiftUI

// MARK: - Battle UI View
struct BattleView: View {
    @StateObject private var battleManager: BattleManager
    @State private var selectedUnit: Unit?
    @State private var selectedSkill: Skill?
    @State private var selectedTargets: [Unit] = []
    @State private var showingSkillSelection = false
    @State private var showingTargetSelection = false
    @State private var battleLog: [String] = []
    @State private var showingBattleResults = false
    @State private var battleResult: BattleManager.BattleResult?
    
    init(playerUnits: [Unit], enemyUnits: [Unit]) {
        self._battleManager = StateObject(wrappedValue: BattleManager(playerUnits: playerUnits, enemyUnits: enemyUnits))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Battle Field
                    battleFieldView
                        .frame(height: geometry.size.height * 0.6)
                    
                    // Battle Log
                    battleLogView
                        .frame(height: geometry.size.height * 0.2)
                    
                    // Action Panel
                    actionPanelView
                        .frame(height: geometry.size.height * 0.2)
                }
            }
        }
        .onAppear {
            setupBattleCallbacks()
        }
        .sheet(isPresented: $showingSkillSelection) {
            skillSelectionView
        }
        .sheet(isPresented: $showingTargetSelection) {
            targetSelectionView
        }
        .alert("Battle Complete", isPresented: $showingBattleResults) {
            Button("Continue") {
                // Handle battle end
            }
        } message: {
            if let result = battleResult {
                Text(battleResultMessage(result))
            }
        }
    }
    
    // MARK: - Battle Field View
    private var battleFieldView: some View {
        HStack(spacing: 20) {
            // Player Units
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Team")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                ForEach(battleManager.playerUnits, id: \.id) { unit in
                    UnitCardView(
                        unit: unit,
                        isSelected: selectedUnit?.id == unit.id,
                        isPlayerUnit: true
                    ) {
                        if battleManager.canPlanAction(for: unit) {
                            selectedUnit = unit
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Enemy Units
            VStack(alignment: .trailing, spacing: 10) {
                Text("Enemies")
                    .font(.headline)
                    .foregroundColor(.red)
                
                ForEach(battleManager.enemyUnits, id: \.id) { unit in
                    UnitCardView(
                        unit: unit,
                        isSelected: selectedTargets.contains { $0.id == unit.id },
                        isPlayerUnit: false
                    ) {
                        if showingTargetSelection {
                            toggleTargetSelection(unit)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
    
    // MARK: - Battle Log View
    private var battleLogView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Battle Log")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(battleLog.enumerated()), id: \.offset) { index, message in
                            Text(message)
                                .font(.caption)
                                .padding(.horizontal)
                                .id(index)
                        }
                    }
                }
                .onChange(of: battleLog.count) { _ in
                    if !battleLog.isEmpty {
                        proxy.scrollTo(battleLog.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Action Panel View
    private var actionPanelView: some View {
        VStack {
            if battleManager.currentPhase == .playerTurn {
                if let currentUnit = selectedUnit {
                    playerActionButtons(for: currentUnit)
                } else {
                    Text("Select a unit to plan their action")
                        .foregroundColor(.secondary)
                }
            } else {
                phaseIndicatorView
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    private func playerActionButtons(for unit: Unit) -> some View {
        VStack(spacing: 10) {
            Text("\(unit.name)'s Turn")
                .font(.headline)
            
            HStack(spacing: 15) {
                // Attack Button
                ActionButton(
                    title: "Attack",
                    icon: "sword.fill",
                    color: .red
                ) {
                    selectedSkill = nil
                    selectedTargets = []
                    showingTargetSelection = true
                }
                .disabled(!canAttack(unit))
                
                // Skills Button
                ActionButton(
                    title: "Skills",
                    icon: "sparkles",
                    color: .blue
                ) {
                    showingSkillSelection = true
                }
                .disabled(unit.availableSkills.isEmpty)
                
                // Defend Button
                ActionButton(
                    title: "Defend",
                    icon: "shield.fill",
                    color: .green
                ) {
                    planDefendAction(for: unit)
                }
                
                // Flee Button
                ActionButton(
                    title: "Flee",
                    icon: "figure.run",
                    color: .yellow
                ) {
                    planFleeAction(for: unit)
                }
            }
            
            // Execute Turn Button
            if hasPlannedActions() {
                Button("Execute Turn") {
                    battleManager.executePlayerTurn()
                    selectedUnit = nil
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
    
    private var phaseIndicatorView: some View {
        VStack {
            switch battleManager.currentPhase {
            case .setup:
                Text("Preparing battle...")
            case .enemyTurn:
                Text("Enemy turn in progress...")
                ProgressView()
            case .victory:
                Text("🎉 Victory!")
                    .foregroundColor(.green)
            case .defeat:
                Text("💀 Defeat!")
                    .foregroundColor(.red)
            case .escaped:
                Text("🏃 Escaped!")
                    .foregroundColor(.yellow)
            default:
                EmptyView()
            }
        }
        .font(.headline)
    }
    
    // MARK: - Skill Selection View
    private var skillSelectionView: some View {
        NavigationView {
            VStack {
                if let unit = selectedUnit {
                    Text("Select Skill for \(unit.name)")
                        .font(.headline)
                        .padding()
                    
                    List(unit.availableSkills, id: \.id) { skill in
                        SkillRowView(skill: skill, unit: unit) {
                            selectedSkill = skill
                            selectedTargets = []
                            showingSkillSelection = false
                            showingTargetSelection = true
                        }
                    }
                }
            }
            .navigationTitle("Skills")
            .navigationBarItems(trailing: Button("Cancel") {
                showingSkillSelection = false
            })
        }
    }
    
    // MARK: - Target Selection View
    private var targetSelectionView: some View {
        NavigationView {
            VStack {
                if let unit = selectedUnit {
                    if let skill = selectedSkill {
                        Text("Select targets for \(skill.name)")
                    } else {
                        Text("Select attack target")
                    }
                    
                    List {
                        Section("Enemies") {
                            ForEach(battleManager.enemyUnits.filter { $0.isAlive }, id: \.id) { enemy in
                                TargetRowView(unit: enemy, isSelected: selectedTargets.contains { $0.id == enemy.id }) {
                                    toggleTargetSelection(enemy)
                                }
                            }
                        }
                        
                        if let skill = selectedSkill, skill.targetType == .single_ally || skill.targetType == .all_allies {
                            Section("Allies") {
                                ForEach(battleManager.playerUnits.filter { $0.isAlive }, id: \.id) { ally in
                                    TargetRowView(unit: ally, isSelected: selectedTargets.contains { $0.id == ally.id }) {
                                        toggleTargetSelection(ally)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("Confirm Action") {
                        confirmAction(for: unit)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedTargets.isEmpty)
                    .padding()
                }
            }
            .navigationTitle("Select Target")
            .navigationBarItems(trailing: Button("Cancel") {
                showingTargetSelection = false
                selectedTargets = []
            })
        }
    }
    
    // MARK: - Helper Methods
    private func setupBattleCallbacks() {
        battleManager.onPhaseChanged = { phase in
            addToBattleLog("Phase changed to: \(phase)")
        }
        
        battleManager.onUnitActionCompleted = { unit, action, result in
            addToBattleLog("\(unit.name) \(result.description)")
        }
        
        battleManager.onBattleEnded = { result in
            self.battleResult = result
            self.showingBattleResults = true
        }
    }
    
    private func addToBattleLog(_ message: String) {
        battleLog.append(message)
    }
    
    private func canAttack(_ unit: Unit) -> Bool {
        return battleManager.enemyUnits.contains { $0.isAlive }
    }
    
    private func hasPlannedActions() -> Bool {
        // Check if all living player units have planned actions
        let livingPlayers = battleManager.playerUnits.filter { $0.isAlive }
        // This would need to be exposed by BattleManager
        return true // Simplified for now
    }
    
    private func toggleTargetSelection(_ unit: Unit) {
        if selectedTargets.contains(where: { $0.id == unit.id }) {
            selectedTargets.removeAll { $0.id == unit.id }
        } else {
            if let skill = selectedSkill {
                // Handle multi-target vs single-target skills
                if skill.targetType == .all_enemies || skill.targetType == .all_allies {
                    selectedTargets = getValidTargetsForSkill(skill)
                } else {
                    selectedTargets = [unit]
                }
            } else {
                // Basic attack - single target
                selectedTargets = [unit]
            }
        }
    }
    
    private func getValidTargetsForSkill(_ skill: Skill) -> [Unit] {
        switch skill.targetType {
        case .all_enemies:
            return battleManager.enemyUnits.filter { $0.isAlive }
        case .all_allies:
            return battleManager.playerUnits.filter { $0.isAlive }
        default:
            return []
        }
    }
    
    private func confirmAction(for unit: Unit) {
        if let skill = selectedSkill {
            let action = BattleAction(actor: unit, type: .useSkill(skill), targets: selectedTargets)
            _ = battleManager.planAction(unit: unit, action: action)
        } else {
            // Basic attack
            if let target = selectedTargets.first {
                let action = BattleAction(actor: unit, type: .attack, targets: [target])
                _ = battleManager.planAction(unit: unit, action: action)
            }
        }
        
        showingTargetSelection = false
        selectedTargets = []
        selectedSkill = nil
        selectedUnit = nil
    }
    
    private func planDefendAction(for unit: Unit) {
        let action = BattleAction(actor: unit, type: .defend, targets: [])
        _ = battleManager.planAction(unit: unit, action: action)
        selectedUnit = nil
    }
    
    private func planFleeAction(for unit: Unit) {
        let action = BattleAction(actor: unit, type: .flee, targets: [])
        _ = battleManager.planAction(unit: unit, action: action)
        selectedUnit = nil
    }
    
    private func battleResultMessage(_ result: BattleManager.BattleResult) -> String {
        switch result {
        case .victory(let rewards):
            return "Victory! Gained \(rewards.experience) EXP and \(rewards.gold) gold."
        case .defeat:
            return "Your party has been defeated..."
        case .escaped:
            return "Successfully escaped from battle!"
        }
    }
}

// MARK: - Supporting Views

struct UnitCardView: View {
    let unit: Unit
    let isSelected: Bool
    let isPlayerUnit: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(unit.name)
                        .font(.caption.bold())
                        .foregroundColor(isPlayerUnit ? .blue : .red)
                    
                    Spacer()
                    
                    if !unit.isAlive {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                
                // HP Bar
                ProgressView(value: Double(unit.currentHP), total: Double(unit.maxHP))
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .scaleEffect(y: 0.5)
                
                Text("HP: \(unit.currentHP)/\(unit.maxHP)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // MP Bar
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
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(!unit.isAlive)
        .opacity(unit.isAlive ? 1.0 : 0.6)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(8)
            .background(color)
            .cornerRadius(8)
        }
    }
}

struct SkillRowView: View {
    let skill: Skill
    let unit: Unit
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(skill.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("MP: \(skill.mpCost)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Text(skill.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if skill.power > 0 {
                    Text("Power: \(skill.power)")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(!unit.canUseSkill(skill))
        .opacity(unit.canUseSkill(skill) ? 1.0 : 0.6)
    }
}

struct TargetRowView: View {
    let unit: Unit
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading) {
                    Text(unit.name)
                        .font(.headline)
                    
                    Text("HP: \(unit.currentHP)/\(unit.maxHP)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }
}