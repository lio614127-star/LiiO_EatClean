import SwiftUI
import CoreData
struct GoalSetupView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @Environment(\.managedObjectContext) private var viewContext
    
    enum SetupStep: Int, CaseIterable {
        case basicInfo = 0
        case bodyMetrics = 1
        case goalSelection = 2
        
        var title: String {
            switch self {
            case .basicInfo: return "Thông tin"
            case .bodyMetrics: return "Số đo"
            case .goalSelection: return "Mục tiêu"
            }
        }
    }
    
    @State private var currentStep: SetupStep = .basicInfo
    @State private var navigateToHome = false
    
    // Step 1: Basic Info
    @State private var name = ""
    @State private var age = ""
    @State private var gender = "male"
    
    // Step 2: Body Metrics
    @State private var height = ""
    @State private var weight = ""
    
    // Step 3: Goal
    @State private var selectedGoal = ""
    
    private var isNextEnabled: Bool {
        switch currentStep {
        case .basicInfo:
            return !age.isEmpty && (Double(age) ?? 0) > 0
        case .bodyMetrics:
            return !height.isEmpty && !weight.isEmpty && (Double(height) ?? 0) > 0 && (Double(weight) ?? 0) > 0
        case .goalSelection:
            return !selectedGoal.isEmpty
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep.rawValue + 1), total: Double(SetupStep.allCases.count))
                .tint(.green)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            
            // Step indicator
            Text("Bước \(currentStep.rawValue + 1)/\(SetupStep.allCases.count)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            // Step content
            Group {
                switch currentStep {
                case .basicInfo:
                    BasicInfoStepView(name: $name, age: $age, gender: $gender)
                case .bodyMetrics:
                    BodyMetricsStepView(height: $height, weight: $weight)
                case .goalSelection:
                    GoalSelectionStepView(
                        selectedGoal: $selectedGoal,
                        weight: Double(weight) ?? 65,
                        height: Double(height) ?? 165,
                        age: Double(age) ?? 25,
                        gender: gender
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            
            // Navigation buttons
            HStack(spacing: 16) {
                // Back button
                if currentStep.rawValue > 0 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let prev = SetupStep(rawValue: currentStep.rawValue - 1) {
                                currentStep = prev
                            }
                        }
                    }) {
                        Text("Quay lại")
                            .font(.headline)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.green, lineWidth: 1.5)
                            )
                    }
                }
                
                // Next / Get Started button
                Button(action: {
                    if currentStep == .goalSelection {
                        saveAndFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if let next = SetupStep(rawValue: currentStep.rawValue + 1) {
                                currentStep = next
                            }
                        }
                    }
                }) {
                    Text(currentStep == .goalSelection ? "Bắt đầu ngay!" : "Tiếp tục")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isNextEnabled ? Color.green : Color.gray.opacity(0.4))
                        .cornerRadius(14)
                }
                .disabled(!isNextEnabled)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $navigateToHome) {
            ContentView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func saveAndFinish() {
        let userAge = Double(age) ?? 25
        let userHeight = Double(height) ?? 165
        let userWeight = Double(weight) ?? 65
        
        let dailyCalories = CalorieCalculator.calculateDailyCalories(
            weight: userWeight,
            height: userHeight,
            age: userAge,
            gender: gender,
            goal: selectedGoal
        )
        
        let user = UserModel(
            name: name,
            age: userAge,
            gender: gender,
            height: userHeight,
            weight: userWeight,
            goalType: selectedGoal,
            dailyCalorieTarget: dailyCalories
        )
        
        let repository = UserRepository(context: PersistenceController.shared.container.newBackgroundContext())
        
        Task {
            do {
                try await repository.saveUser(user)
                await MainActor.run {
                    hasCompletedOnboarding = true
                    navigateToHome = true
                }
            } catch {
                print("Error saving user: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        GoalSetupView()
    }
}
