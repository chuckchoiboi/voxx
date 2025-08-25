import Foundation
import AVFoundation

protocol AudioPlayerManagerDelegate: AnyObject {
    func playbackDidStart()
    func playbackDidPause()
    func playbackDidStop()
    func playbackDidFinish()
    func playbackDidFail(error: Error)
    func playbackTimeDidUpdate(currentTime: TimeInterval, duration: TimeInterval)
}

class AudioPlayerManager: NSObject {
    static let shared = AudioPlayerManager()
    
    weak var delegate: AudioPlayerManagerDelegate?
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var currentAudioFilePath: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Public Properties
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var isPaused: Bool {
        return audioPlayer != nil && !isPlaying
    }
    
    var currentTime: TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }
    
    var currentFilePath: String? {
        return currentAudioFilePath
    }
    
    // MARK: - Public Methods
    
    func loadAudioFile(at filePath: String) throws {
        guard AudioFileManager.shared.audioFileExists(at: filePath) else {
            throw AudioPlayerError.fileNotFound
        }
        
        let audioURL = URL(fileURLWithPath: filePath)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            currentAudioFilePath = filePath
        } catch {
            throw AudioPlayerError.failedToLoadFile
        }
    }
    
    func play() {
        guard let audioPlayer = audioPlayer else { return }
        
        do {
            try AudioSessionManager.shared.setupAudioSession()
            
            if audioPlayer.play() {
                startPlaybackTimer()
                delegate?.playbackDidStart()
            } else {
                delegate?.playbackDidFail(error: AudioPlayerError.failedToPlay)
            }
        } catch {
            delegate?.playbackDidFail(error: error)
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        stopPlaybackTimer()
        delegate?.playbackDidPause()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        stopPlaybackTimer()
        delegate?.playbackDidStop()
        
        do {
            try AudioSessionManager.shared.deactivateAudioSession()
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
    
    func seek(to time: TimeInterval) {
        guard let audioPlayer = audioPlayer else { return }
        
        let seekTime = max(0, min(time, audioPlayer.duration))
        audioPlayer.currentTime = seekTime
        
        delegate?.playbackTimeDidUpdate(currentTime: seekTime, duration: audioPlayer.duration)
    }
    
    func setPlaybackRate(_ rate: Float) {
        audioPlayer?.rate = rate
    }
    
    func cleanup() {
        stop()
        audioPlayer = nil
        currentAudioFilePath = nil
    }
    
    // MARK: - Private Methods
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let audioPlayer = self.audioPlayer else { return }
            
            self.delegate?.playbackTimeDidUpdate(
                currentTime: audioPlayer.currentTime,
                duration: audioPlayer.duration
            )
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaybackTimer()
        
        do {
            try AudioSessionManager.shared.deactivateAudioSession()
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        if flag {
            delegate?.playbackDidFinish()
        } else {
            delegate?.playbackDidFail(error: AudioPlayerError.playbackFailed)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopPlaybackTimer()
        delegate?.playbackDidFail(error: error ?? AudioPlayerError.decodingError)
    }
}

// MARK: - Error Types

enum AudioPlayerError: Error {
    case fileNotFound
    case failedToLoadFile
    case failedToPlay
    case playbackFailed
    case decodingError
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound:
            return "Audio file not found"
        case .failedToLoadFile:
            return "Failed to load audio file"
        case .failedToPlay:
            return "Failed to start playback"
        case .playbackFailed:
            return "Playback failed"
        case .decodingError:
            return "Audio decoding error"
        }
    }
}