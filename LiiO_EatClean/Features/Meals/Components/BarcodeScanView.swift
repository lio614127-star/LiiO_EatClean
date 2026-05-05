import SwiftUI
import AVFoundation

struct BarcodeScanView: View {
    @StateObject private var scanner = BarcodeScannerService()
    @State private var resultService = BarcodeResultService()
    @State private var lookupResult: BarcodeResultService.LookupResult?
    @State private var isLookingUp = false
    @State private var quantity: Double = 1.0
    
    @Binding var isPresented: Bool
    var onFoodConfirmed: (FoodItemModel, Double) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                if lookupResult == nil {
                    // Camera phase
                    cameraView
                } else {
                    // Result phase
                    resultScreen
                }
            }
            .navigationTitle(lookupResult == nil ? "Quét mã vạch" : "Kết quả tra cứu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        scanner.stopScanning()
                        isPresented = false
                    }
                }
            }
            .task {
                if await scanner.checkPermission() {
                    scanner.setupCamera()
                    scanner.startScanning()
                } else {
                    scanner.permissionError = "Vui lòng cấp quyền Camera trong Cài đặt."
                }
            }
            .onDisappear {
                scanner.stopScanning()
            }
            .onChange(of: scanner.scannedBarcode) { _, newValue in
                if let barcode = newValue {
                    performLookup(barcode: barcode)
                }
            }
        }
    }
    
    private var cameraView: some View {
        ZStack {
            if let error = scanner.permissionError {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if isLookingUp {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Đang tra cứu...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else {
                CameraPreviewView(session: scanner.captureSession)
                    .ignoresSafeArea()
                
                // Overlay outline
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, dash: [10]))
                        .frame(width: 280, height: 180)
                        .background(Color.black.opacity(0.1))
                    
                    Text("Hướng camera vào mã vạch")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        .padding(.top, 24)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var resultScreen: some View {
        VStack {
            switch lookupResult {
            case .found(let food):
                foodDetailView(food: food, isAI: false)
                
            case .aiEstimated(let food):
                foodDetailView(food: food, isAI: true)
                
            case .notFound(let barcode):
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("Không tìm thấy sản phẩm")
                        .font(.title2.bold())
                    Text("Mã vạch: \(barcode)")
                        .foregroundColor(.secondary)
                    
                    Text("Sản phẩm này chưa có trong cơ sở dữ liệu. Vui lòng tìm kiếm thủ công bằng tên món ăn.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button("Tìm kiếm thủ công") {
                        // Close this sheet so user can search
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    
                    Button("Quét lại") {
                        lookupResult = nil
                        scanner.startScanning()
                    }
                    .padding(.top)
                    
                    Spacer()
                }
                .padding()
                
            case .none:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func foodDetailView(food: FoodItemModel, isAI: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if isAI {
                    HStack {
                        Image(systemName: "bolt.fill")
                        Text("⚡ Ước tính bởi AI")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                
                Text(food.name)
                    .font(.title2.bold())
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(Int(food.calories))")
                            .font(.title.bold())
                            .foregroundColor(.orange)
                        Text("kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 16) {
                        macroView(title: "Protein", value: food.protein, color: .red)
                        macroView(title: "Carbs", value: food.carbs, color: .blue)
                        macroView(title: "Fat", value: food.fat, color: .yellow)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                HStack {
                    Text("Số lượng:")
                        .font(.headline)
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if quantity > 0.5 { quantity -= 0.5 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        
                        Text("\(quantity, specifier: "%.1f")")
                            .font(.title2.bold())
                            .frame(width: 50)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            quantity += 0.5
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        
        Button(action: {
            HapticManager.success()
            onFoodConfirmed(food, quantity)
            isPresented = false
        }) {
            Text("Xác nhận & Thêm")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
        }
        .padding()
    }
    
    private func macroView(title: String, value: Double, color: Color) -> some View {
        VStack {
            Text("\(Int(value))g")
                .font(.headline)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func performLookup(barcode: String) {
        isLookingUp = true
        Task {
            let result = await resultService.lookup(barcode: barcode)
            await MainActor.run {
                self.isLookingUp = false
                self.lookupResult = result
            }
        }
    }
}

// MARK: - Camera Preview Wrapper
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}
