import AVFoundation
import SwiftUI
import Combine

class BarcodeScannerService: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedBarcode: String? = nil
    @Published var isScanning: Bool = false
    @Published var permissionError: String? = nil
    
    let captureSession = AVCaptureSession()
    private var isConfigured = false
    
    override init() {
        super.init()
    }
    
    func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    func setupCamera() {
        guard !isConfigured else { return }
        
        captureSession.beginConfiguration()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            permissionError = "Thiết bị không có camera."
            captureSession.commitConfiguration()
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            permissionError = "Không thể sử dụng camera: \(error.localizedDescription)"
            captureSession.commitConfiguration()
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            permissionError = "Không thể thêm camera vào session."
            captureSession.commitConfiguration()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128]
        } else {
            permissionError = "Không thể quét mã vạch."
            captureSession.commitConfiguration()
            return
        }
        
        captureSession.commitConfiguration()
        isConfigured = true
    }
    
    func startScanning() {
        guard isConfigured else { return }
        
        scannedBarcode = nil
        isScanning = true
        
        DispatchQueue.global(qos: .background).async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let stringValue = readableObject.stringValue {
            
            // Single-shot: only process if we are currently scanning
            guard isScanning else { return }
            
            // Stop scanning immediately after successful read
            stopScanning()
            HapticManager.success()
            scannedBarcode = stringValue
        }
    }
}
