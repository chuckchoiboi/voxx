import Foundation
import AVFoundation

protocol AudioRecordingManagerDelegate: AnyObject {
    func recordingDidStart()
    func recordingDidStop(audioFilePath: String, duration: TimeInterval)
    func recordingDidFail(error: Error)
    func recordingTimeDidUpdate(currentTime: TimeInterval)
}

class AudioRecordingManager: NSObject {
    static let shared = AudioRecordingManager()
    
    weak var delegate: AudioRecordingManagerDelegate?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    
    var isRecording: Bool {
        return audioRecorder?.isRecording ?? false
    }
    
    var currentRecordingTime: TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Check if there's enough storage space
        guard AudioFileManager.shared.hasEnoughStorageForRecording() else {
            delegate?.recordingDidFail(error: AudioRecordingError.insufficientStorage)
            return
        }
        
        do {
            try AudioSessionManager.shared.setupAudioSession()
            
            let audioFilePath = generateAudioFilePath()
            let audioURL = URL(fileURLWithPath: audioFilePath)
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            if audioRecorder?.record() == true {
                recordingStartTime = Date()
                startRecordingTimer()
                delegate?.recordingDidStart()
            } else {
                throw AudioRecordingError.failedToStartRecording
            }
            
        } catch {
            delegate?.recordingDidFail(error: error)
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        stopRecordingTimer()
        
        do {
            try AudioSessionManager.shared.deactivateAudioSession()
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func generateAudioFilePath() -> String {
        return AudioFileManager.shared.generateAudioFilePath()
    }
    
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.recordingTimeDidUpdate(currentTime: self.currentRecordingTime)
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let duration = currentRecordingTime
        recordingStartTime = nil
        
        if flag {
            delegate?.recordingDidStop(audioFilePath: recorder.url.path, duration: duration)
        } else {
            delegate?.recordingDidFail(error: AudioRecordingError.recordingFailed)
        }
        
        audioRecorder = nil
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        delegate?.recordingDidFail(error: error ?? AudioRecordingError.encodingError)
        audioRecorder = nil
        recordingStartTime = nil
        stopRecordingTimer()
    }
}

// MARK: - Error Types

enum AudioRecordingError: Error {
    case failedToStartRecording
    case recordingFailed
    case encodingError
    case permissionDenied
    case insufficientStorage
    
    var localizedDescription: String {
        switch self {
        case .failedToStartRecording:
            return "Failed to start recording"
        case .recordingFailed:
            return "Recording failed"
        case .encodingError:
            return "Audio encoding error"
        case .permissionDenied:
            return "Microphone permission denied"
        case .insufficientStorage:
            return "Not enough storage space available"
        }
    }
}