import Foundation
import Speech
import AVFoundation

/// 语音识别管理器 - 使用 iOS 原生 Speech 框架
@MainActor
class SpeechRecognizer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    @Published var isAuthorized = false
    
    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer: SFSpeechRecognizer?
    
    // 完成回调
    var onTranscriptionComplete: ((String) -> Void)?
    
    // MARK: - Init
    init() {
        // 支持中文和英文
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
            ?? SFSpeechRecognizer(locale: Locale.current)
        
        Task {
            await checkAuthorization()
        }
    }
    
    // MARK: - Authorization
    func checkAuthorization() async {
        // 检查语音识别权限
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        // 检查麦克风权限
        let micStatus: Bool
        if #available(iOS 17.0, *) {
            micStatus = await AVAudioApplication.requestRecordPermission()
        } else {
            micStatus = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        
        isAuthorized = (speechStatus == .authorized) && micStatus
        
        if !isAuthorized {
            if speechStatus != .authorized {
                errorMessage = "请在设置中允许语音识别权限"
            } else if !micStatus {
                errorMessage = "请在设置中允许麦克风权限"
            }
        }
    }
    
    // MARK: - Recording Control
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        guard isAuthorized else {
            Task { await checkAuthorization() }
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "语音识别不可用"
            return
        }
        
        // 重置状态
        transcribedText = ""
        errorMessage = nil
        
        do {
            try setupAudioSession()
            try startRecognition()
            isRecording = true
        } catch {
            errorMessage = "启动录音失败: \(error.localizedDescription)"
            cleanup()
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        
        isRecording = false
        
        // 等待最终结果后回调
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            if !self.transcribedText.isEmpty {
                self.onTranscriptionComplete?(self.transcribedText)
            }
            self.cleanup()
        }
    }
    
    // MARK: - Private Methods
    private func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startRecognition() throws {
        // 取消之前的任务
        recognitionTask?.cancel()
        recognitionTask = nil
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "SpeechRecognizer", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "无法创建音频引擎"])
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "SpeechRecognizer", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "无法创建识别请求"])
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 如果支持，启用设备端识别（更快、更隐私）
        if #available(iOS 13, *) {
            if speechRecognizer?.supportsOnDeviceRecognition == true {
                recognitionRequest.requiresOnDeviceRecognition = true
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    if self.isRecording {
                        self.stopRecording()
                    }
                }
            }
        }
    }
    
    private func cleanup() {
        audioEngine?.stop()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        // 恢复音频会话
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
