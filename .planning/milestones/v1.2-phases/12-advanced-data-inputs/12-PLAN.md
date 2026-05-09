---
phase: 12
plan: "12-PLAN"
requires: [VOIC-01, VOIC-02, SCAN-01, SCAN-02]
depends_on: [12-CONTEXT.md]
estimated_tasks: 10
---

# Phase 12: Advanced Data Inputs — Plan

## Goal
Tích hợp Voice Input (Apple Speech + AI parsing) và Barcode Scan (camera + OpenFoodFacts API) vào flow log bữa ăn để giảm thao tác nhập liệu.

## Tasks

### Task 1: SpeechRecognitionService — Apple Speech wrapper
**File:** `LiiO_EatClean/Services/SpeechRecognitionService.swift` [NEW]

Create `SpeechRecognitionService` using Apple's `Speech` framework:

```swift
import Speech
import AVFoundation

@Observable
class SpeechRecognitionService {
    var transcript: String = ""
    var isListening: Bool = false
    var error: String? = nil
    
    private var recognizer: SFSpeechRecognizer?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    
    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func startListening() {
        // 1. Create audio engine + recognition request
        // 2. Install tap on audio engine input node
        // 3. Start recognition task with Vietnamese locale
        // 4. Update transcript in real-time as results come in
        // 5. Set isListening = true
    }
    
    func stopListening() {
        // 1. Stop audio engine
        // 2. End recognition request
        // 3. Set isListening = false
    }
}
```

**Key details:**
- Locale: `vi-VN` for Vietnamese speech recognition
- Real-time transcription (update `transcript` as user speaks)
- Auto-stop after 3 seconds of silence (or manual stop)
- Handle permission requests for Microphone + Speech
- Must add `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` to Info.plist

**Acceptance:** Service can start listening, show real-time transcript, and stop cleanly.

---

### Task 2: VoiceFoodParserService — AI text→food parsing
**File:** `LiiO_EatClean/Services/VoiceFoodParserService.swift` [NEW]

Create service that converts voice transcript to food items:

```swift
class VoiceFoodParserService {
    private let aiService: AIService
    private let foodRepository: FoodRepositoryProtocol
    
    // Cache to avoid re-parsing same phrases
    private static var parseCache: [String: [AISuggestedFood]] = [:]
    
    func parseTranscript(_ text: String) async throws -> [AISuggestedFood] {
        // 1. Normalize text (lowercase, trim)
        // 2. Check cache → return cached result if exists
        // 3. Try local DB match first (simple text search)
        //    - If exact/close match found → convert to AISuggestedFood, skip AI
        // 4. If no local match → call AI with SHORT prompt:
        //    "Parse thành JSON: [{name, calories, protein, carbs, fat, servingSize, quantity}]
        //     Text: '{transcript}'"
        // 5. Cache result for future use
        // 6. Return [AISuggestedFood]
    }
}
```

**Key details:**
- Local match first: use `foodRepository.searchLocalFoods(query:)` — if top result is close match (Levenshtein or contains), use it directly
- AI fallback: call `aiService.generateText(prompt:)` with minimal prompt to reduce tokens
- Static cache: `[String: [AISuggestedFood]]` in memory — persists within session
- Error handling: if both local + AI fail, return empty array with error message

**Acceptance:** "tôi ăn 1 bát phở bò" → returns `[AISuggestedFood(name: "Phở bò", calories: ~400, ...)]`

---

### Task 3: VoiceInputView — Recording UI overlay
**File:** `LiiO_EatClean/Features/Meals/Components/VoiceInputView.swift` [NEW]

Create the voice recording UI:

```swift
struct VoiceInputView: View {
    @State private var speechService = SpeechRecognitionService()
    @State private var parserService = VoiceFoodParserService()
    @State private var parsedFoods: [AISuggestedFood] = []
    @State private var isParsing = false
    @State private var showResults = false
    @Binding var isPresented: Bool
    var onFoodsConfirmed: ([AISuggestedFood]) -> Void
    
    var body: some View {
        // State 1: Recording
        // - Large pulsing mic icon (animated circle)
        // - Real-time transcript text below
        // - "Đang nghe..." label
        // - Stop button
        
        // State 2: Parsing
        // - ProgressView + "Đang phân tích..."
        
        // State 3: Results
        // - List of parsed foods with name, calories, quantity
        // - Each item has edit (quantity) and remove button
        // - [Xác nhận] green button at bottom
        // - [Sửa] secondary button
    }
}
```

**Key details:**
- Presented as `.sheet` with `.medium` detent
- Pulsing animation on mic icon while recording (scale + opacity)
- Show transcript live as user speaks
- After stop → auto-parse → show results
- Results screen: food name + calories + quantity, editable
- [Xác nhận] → calls `onFoodsConfirmed` callback → dismiss
- [Sửa] → let user modify quantity/remove items
- HapticManager.success() on confirm, .interaction() on start recording

**Acceptance:** Full flow: tap mic → speak → see transcript → see parsed foods → confirm → dismiss with foods.

---

### Task 4: Voice button integration — Home + AddMealView
**Files:**
- `LiiO_EatClean/Features/Home/HomeView.swift` [MODIFY]
- `LiiO_EatClean/Features/Meals/AddMealView.swift` [MODIFY]

**HomeView changes:**
- Add mic button in `headerSection`, next to greeting text (trailing position)
- On tap → present `VoiceInputView` as sheet
- On foods confirmed → present `AddMealView` with foods pre-filled in cart

```swift
// In headerSection HStack:
Button(action: { showVoiceInput = true }) {
    Image(systemName: "mic.fill")
        .font(.title3)
        .foregroundColor(.white)
        .frame(width: 40, height: 40)
        .background(Color.green)
        .clipShape(Circle())
}
```

**AddMealView changes:**
- Add mic button next to "✨ Hỏi AI" button in `aiSuggestionBar`
- On tap → present `VoiceInputView`
- On foods confirmed → add each food to `viewModel.cartItems`

```swift
// In aiSuggestionBar, before the AI button:
Button(action: { showVoiceInput = true }) {
    Image(systemName: "mic.fill")
        .font(.subheadline.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue)
        .clipShape(Capsule())
}
```

**Acceptance:** Mic button visible on both Home and AddMealView. Tapping opens VoiceInputView sheet.

---

### Task 5: Info.plist permissions
**File:** `LiiO_EatClean/Info.plist` [NEW or MODIFY]

Add required privacy descriptions:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>LiiO EatClean cần truy cập microphone để ghi âm giọng nói khi bạn log bữa ăn bằng voice.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>LiiO EatClean sử dụng nhận diện giọng nói để chuyển lời nói thành văn bản khi log bữa ăn.</string>
<key>NSCameraUsageDescription</key>
<string>LiiO EatClean cần truy cập camera để quét mã vạch sản phẩm thực phẩm.</string>
```

**Acceptance:** App shows Vietnamese permission dialog when first accessing mic/camera.

---

### Task 6: BarcodeScannerService — Camera + barcode detection
**File:** `LiiO_EatClean/Services/BarcodeScannerService.swift` [NEW]

Create barcode scanner using AVFoundation:

```swift
import AVFoundation
import SwiftUI

class BarcodeScannerService: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedBarcode: String? = nil
    @Published var isScanning: Bool = false
    
    let captureSession = AVCaptureSession()
    
    func setupCamera() {
        // 1. Create AVCaptureDeviceInput (back camera)
        // 2. Create AVCaptureMetadataOutput
        // 3. Set metadata object types: [.ean8, .ean13, .upce, .code128]
        // 4. Add input + output to session
        // 5. Set delegate to self
    }
    
    func startScanning() {
        // Start capture session on background queue
        isScanning = true
    }
    
    func stopScanning() {
        captureSession.stopRunning()
        isScanning = false
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Single-shot: capture first valid barcode → stop scanning
        // Set scannedBarcode
        // HapticManager.success()
    }
}
```

**Key details:**
- Support barcode types: EAN-8, EAN-13, UPC-E, Code 128 (covers most food products)
- Single-shot: stop scanning after first successful read
- Haptic feedback on successful scan
- Camera preview layer exposed for SwiftUI via UIViewRepresentable

**Acceptance:** Camera opens, detects barcode, returns barcode string, stops scanning.

---

### Task 7: OpenFoodFactsService — Barcode lookup API
**File:** `LiiO_EatClean/Services/OpenFoodFactsService.swift` [NEW]

Create service to query OpenFoodFacts:

```swift
struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let nutriments: Nutriments?
    let brands: String?
    
    struct Nutriments: Codable {
        let energyKcal100g: Double?
        let proteins100g: Double?
        let carbohydrates100g: Double?
        let fat100g: Double?
        
        enum CodingKeys: String, CodingKey {
            case energyKcal100g = "energy-kcal_100g"
            case proteins100g = "proteins_100g"
            case carbohydrates100g = "carbohydrates_100g"
            case fat100g = "fat_100g"
        }
    }
}

class OpenFoodFactsService {
    func lookupBarcode(_ barcode: String) async throws -> FoodItemModel? {
        // 1. GET https://world.openfoodfacts.org/api/v2/product/{barcode}
        // 2. Parse response → OpenFoodFactsProduct
        // 3. If product found + has nutrition → convert to FoodItemModel
        // 4. If product found but no nutrition → return FoodItemModel with name only (AI will estimate)
        // 5. If not found → return nil
    }
}
```

**Key details:**
- API: `https://world.openfoodfacts.org/api/v2/product/{barcode}` (GET, no auth)
- Parse `product_name`, `nutriments.energy-kcal_100g`, `proteins_100g`, `carbohydrates_100g`, `fat_100g`
- Convert per-100g values to per-serving (assume 1 serving ≈ 100g as default, or use `serving_quantity` if available)
- Timeout: 10 seconds
- Cache results in memory: `[String: FoodItemModel]`

**Acceptance:** Given valid barcode → returns FoodItemModel with name + nutrition. Invalid barcode → returns nil.

---

### Task 8: BarcodeResultService — Fallback 2 tầng
**File:** `LiiO_EatClean/Services/BarcodeResultService.swift` [NEW]

Orchestrates the 2-tier fallback:

```swift
class BarcodeResultService {
    private let openFoodFacts = OpenFoodFactsService()
    private let aiService = AIService.shared
    
    enum LookupResult {
        case found(FoodItemModel)           // Full data from OpenFoodFacts
        case aiEstimated(FoodItemModel)      // Name from OFF + AI estimated nutrition
        case notFound(barcode: String)       // Nothing found → suggest manual search
    }
    
    func lookup(barcode: String) async -> LookupResult {
        // Tier 1: OpenFoodFacts
        if let product = try? await openFoodFacts.lookupBarcode(barcode) {
            if product.calories > 0 {
                return .found(product)
            } else {
                // Has name but no nutrition → AI estimate
                let estimated = try? await estimateNutrition(name: product.name)
                if let est = estimated {
                    return .aiEstimated(est)
                }
            }
        }
        
        // Tier 2: Nothing found
        return .notFound(barcode: barcode)
    }
    
    private func estimateNutrition(name: String) async throws -> FoodItemModel {
        // Call AI: "Estimate calories for: {name}. Return JSON."
    }
}
```

**Acceptance:** Barcode → tries OpenFoodFacts → if missing nutrition uses AI → if all fails returns `.notFound`.

---

### Task 9: BarcodeScanView — Camera UI + result screen
**File:** `LiiO_EatClean/Features/Meals/Components/BarcodeScanView.swift` [NEW]

Create the scan UI:

```swift
struct BarcodeScanView: View {
    @StateObject private var scanner = BarcodeScannerService()
    @State private var resultService = BarcodeResultService()
    @State private var lookupResult: BarcodeResultService.LookupResult?
    @State private var isLookingUp = false
    @State private var quantity: String = "1"
    @Binding var isPresented: Bool
    var onFoodConfirmed: (FoodItemModel, Double) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                if lookupResult == nil {
                    // Camera preview (UIViewRepresentable)
                    CameraPreviewView(session: scanner.captureSession)
                        .overlay {
                            // Scan guide overlay (rectangle outline)
                            // "Hướng camera vào mã vạch" label
                        }
                    
                    if isLookingUp {
                        ProgressView("Đang tra cứu...")
                    }
                } else {
                    // Result screen
                    switch lookupResult {
                    case .found(let food):
                        // Show: name, calories, macros
                        // Quantity input
                        // [Xác nhận] [Sửa]
                    case .aiEstimated(let food):
                        // Show same + "⚡ Ước tính bởi AI" badge
                    case .notFound(let barcode):
                        // "Không tìm thấy sản phẩm"
                        // [Tìm kiếm thủ công] → fills search bar
                    }
                }
            }
            .navigationTitle("Quét mã vạch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") { isPresented = false }
                }
            }
        }
    }
}

// Camera preview wrapper
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView { ... }
    func updateUIView(_ uiView: UIView, context: Context) { }
}
```

**Key details:**
- Presented as sheet with `.medium` → `.large` detent (starts half-screen camera)
- Scan guide overlay: dashed rectangle + label "Hướng camera vào mã vạch"
- Auto-lookup after scan → show loading → show result
- Result found: product name, calories, protein/carbs/fat, quantity input, [Xác nhận]
- AI estimated: same but with "⚡ Ước tính bởi AI" badge (orange)
- Not found: message + [Tìm kiếm thủ công] button
- HapticManager.success() on successful scan

**Acceptance:** Full scan flow: open camera → scan barcode → see result → confirm → get food item.

---

### Task 10: Barcode button integration — AddMealView
**File:** `LiiO_EatClean/Features/Meals/AddMealView.swift` [MODIFY]

Add scan button to `AddMealView`:

```swift
// In aiSuggestionBar, add barcode button before mic button:
Button(action: { showBarcodeScanner = true }) {
    Image(systemName: "barcode.viewfinder")
        .font(.subheadline.bold())
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange)
        .clipShape(Capsule())
}

// Sheet presentation:
.sheet(isPresented: $showBarcodeScanner) {
    BarcodeScanView(isPresented: $showBarcodeScanner) { food, qty in
        viewModel.addToCart(food: food, quantity: qty)
    }
}
```

**Key details:**
- Barcode button: orange capsule with `barcode.viewfinder` icon
- Mic button: blue capsule with `mic.fill` icon
- AI button: green capsule (existing)
- Order: [📸 Scan] [🎤 Voice] [✨ AI] (left to right)
- On food confirmed from scan → add to cart just like manual/AI items

**Acceptance:** AddMealView has 3 action buttons. Scan opens camera, voice opens recorder, AI stays as-is.

## Verification

### Build check
```bash
xcodebuild -scheme LiiO_EatClean -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build 2>&1 | tail -5
```

### Manual UAT
1. Voice: Home mic → speak Vietnamese → see parsed food → confirm → appears in cart
2. Voice: AddMealView mic → same flow
3. Barcode: Scan known product → see nutrition → confirm → added to cart
4. Barcode: Scan unknown barcode → see "Không tìm thấy" → tap search → food search opens
5. Permissions: First-time mic/camera access shows Vietnamese permission dialogs
