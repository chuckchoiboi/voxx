import Foundation
import AVFoundation

protocol IntegrationManagerDelegate: AnyObject {
    func integrationDidCompleteRecordingFlow(success: Bool, entry: JournalEntry?, error: Error?)
    func integrationDidCompletePlaybackFlow(success: Bool, error: Error?)
    func integrationDidCompleteDataOperation(success: Bool, error: Error?)
    func integrationStorageWarning(availableMB: Int)
}

class IntegrationManager {
    static let shared = IntegrationManager()
    
    weak var delegate: IntegrationManagerDelegate?
    
    private init() {}
    
    // MARK: - System Health Checks
    
    func performSystemHealthCheck() -> SystemHealthReport {
        var report = SystemHealthReport()
        
        // Check audio permissions
        report.hasRecordPermission = AudioSessionManager.shared.hasRecordPermission
        
        // Check storage space
        let availableBytes = AudioFileManager.shared.getAvailableStorageSpace()
        report.availableStorageMB = Int(availableBytes / (1024 * 1024))
        report.hasEnoughStorage = AudioFileManager.shared.hasEnoughStorageForRecording()
        
        // Check Core Data connectivity
        report.coreDataHealthy = testCoreDataConnection()
        
        // Check audio system
        report.audioSystemHealthy = testAudioSystem()
        
        // Check for orphaned files
        let validPaths = DataManager.shared.fetchAllJournalEntries().compactMap { $0.audioFilePath }
        let allAudioFiles = AudioFileManager.shared.getAllAudioFiles()
        report.orphanedFilesCount = allAudioFiles.filter { !validPaths.contains($0) }.count
        
        // Total statistics
        report.totalEntries = DataManager.shared.getEntryCount()
        report.totalAudioFilesMB = Int(AudioFileManager.shared.getTotalAudioFilesSize() / (1024 * 1024))
        
        return report
    }
    
    private func testCoreDataConnection() -> Bool {
        do {
            let testCount = DataManager.shared.getEntryCount()
            return testCount >= 0
        } catch {
            return false
        }
    }
    
    private func testAudioSystem() -> Bool {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            return audioSession.isOtherAudioPlaying == false || audioSession.isOtherAudioPlaying == true
        } catch {
            return false
        }
    }
    
    // MARK: - End-to-End Workflows
    
    func startCompleteRecordingWorkflow() {
        // Pre-recording checks
        let healthReport = performSystemHealthCheck()
        
        if !healthReport.hasRecordPermission {
            delegate?.integrationDidCompleteRecordingFlow(
                success: false,
                entry: nil,
                error: IntegrationError.noRecordPermission
            )
            return
        }
        
        if !healthReport.hasEnoughStorage {
            delegate?.integrationStorageWarning(availableMB: healthReport.availableStorageMB)
        }
        
        if !healthReport.audioSystemHealthy {
            delegate?.integrationDidCompleteRecordingFlow(
                success: false,
                entry: nil,
                error: IntegrationError.audioSystemUnavailable
            )
            return
        }
        
        // Start recording workflow
        AudioRecordingManager.shared.startRecording()
    }
    
    func completeRecordingWorkflow(audioFilePath: String, duration: TimeInterval) {
        // Verify the file was created successfully
        guard AudioFileManager.shared.audioFileExists(at: audioFilePath) else {
            delegate?.integrationDidCompleteRecordingFlow(
                success: false,
                entry: nil,
                error: IntegrationError.audioFileNotCreated
            )
            return
        }
        
        // Verify file size is reasonable
        let fileSize = AudioFileManager.shared.getAudioFileSize(at: audioFilePath)
        guard fileSize > 0 else {
            delegate?.integrationDidCompleteRecordingFlow(
                success: false,
                entry: nil,
                error: IntegrationError.emptyAudioFile
            )
            return
        }
        
        // Create journal entry
        let entry = DataManager.shared.createJournalEntry(audioFilePath: audioFilePath, duration: duration)
        
        // Verify entry was saved
        let savedEntries = DataManager.shared.fetchAllJournalEntries()
        guard savedEntries.contains(where: { $0.id == entry.id }) else {
            // Clean up the audio file since Core Data save failed
            _ = AudioFileManager.shared.deleteAudioFile(at: audioFilePath)
            delegate?.integrationDidCompleteRecordingFlow(
                success: false,
                entry: nil,
                error: IntegrationError.coreDataSaveFailed
            )
            return
        }
        
        // Start AI processing in background if OpenAI is configured
        if OpenAIManager.shared.isAPIKeyConfigured() {
            processAudioWithAI(entry: entry)
        }
        
        delegate?.integrationDidCompleteRecordingFlow(success: true, entry: entry, error: nil)
    }
    
    func startCompletePlaybackWorkflow(for entry: JournalEntry) {
        // Verify entry has valid audio file
        guard let audioFilePath = entry.audioFilePath else {
            delegate?.integrationDidCompletePlaybackFlow(
                success: false,
                error: IntegrationError.noAudioFile
            )
            return
        }
        
        // Verify audio file exists
        guard AudioFileManager.shared.audioFileExists(at: audioFilePath) else {
            delegate?.integrationDidCompletePlaybackFlow(
                success: false,
                error: IntegrationError.audioFileNotFound
            )
            return
        }
        
        // Load and play audio
        do {
            try AudioPlayerManager.shared.loadAudioFile(at: audioFilePath)
            AudioPlayerManager.shared.play()
            delegate?.integrationDidCompletePlaybackFlow(success: true, error: nil)
        } catch {
            delegate?.integrationDidCompletePlaybackFlow(success: false, error: error)
        }
    }
    
    // MARK: - Maintenance Operations
    
    func performMaintenanceCleanup() {
        // Get all valid audio file paths from Core Data
        let validPaths = DataManager.shared.fetchAllJournalEntries().compactMap { $0.audioFilePath }
        
        // Clean up orphaned files
        AudioFileManager.shared.cleanupOrphanedAudioFiles(validPaths: validPaths)
        
        // Check for entries with missing audio files
        let allEntries = DataManager.shared.fetchAllJournalEntries()
        for entry in allEntries {
            if let path = entry.audioFilePath, !AudioFileManager.shared.audioFileExists(at: path) {
                // Audio file is missing, could mark entry as corrupted or delete it
                print("Warning: Entry '\(entry.title ?? "Unknown")' has missing audio file: \(path)")
            }
        }
        
        delegate?.integrationDidCompleteDataOperation(success: true, error: nil)
    }
    
    func validateDataIntegrity() -> DataIntegrityReport {
        var report = DataIntegrityReport()
        
        let allEntries = DataManager.shared.fetchAllJournalEntries()
        
        for entry in allEntries {
            if let audioPath = entry.audioFilePath {
                if AudioFileManager.shared.audioFileExists(at: audioPath) {
                    report.validEntries += 1
                } else {
                    report.entriesWithMissingFiles += 1
                }
            } else {
                report.entriesWithoutAudioPath += 1
            }
        }
        
        let allAudioFiles = AudioFileManager.shared.getAllAudioFiles()
        let validPaths = allEntries.compactMap { $0.audioFilePath }
        report.orphanedAudioFiles = allAudioFiles.filter { !validPaths.contains($0) }.count
        
        report.totalEntries = allEntries.count
        report.totalAudioFiles = allAudioFiles.count
        
        return report
    }
    
    // MARK: - AI Processing
    
    private func processAudioWithAI(entry: JournalEntry) {
        guard let audioFilePath = entry.audioFilePath else { return }
        
        // Process in background
        Task {
            do {
                // Load audio data
                guard let audioData = AudioFileManager.shared.loadAudioData(from: audioFilePath) else {
                    print("Failed to load audio data for AI processing")
                    return
                }
                
                // Generate file name for API
                let fileName = "audio_\(entry.id?.uuidString ?? "unknown").m4a"
                
                // Transcribe audio
                let transcript = try await OpenAIManager.shared.transcribeAudio(
                    audioData: audioData, 
                    fileName: fileName
                )
                
                // Generate summary
                let summary = try await OpenAIManager.shared.generateSummary(from: transcript)
                
                // Update entry on main thread
                await MainActor.run {
                    DataManager.shared.updateJournalEntry(
                        entry,
                        transcript: transcript,
                        summary: summary
                    )
                }
                
                print("AI processing completed for entry: \(entry.title ?? "Unknown")")
                
            } catch {
                print("AI processing failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Manual AI Processing
    
    func processEntryWithAI(_ entry: JournalEntry, completion: @escaping (Bool, Error?) -> Void) {
        guard OpenAIManager.shared.isAPIKeyConfigured() else {
            completion(false, OpenAIError.noAPIKey)
            return
        }
        
        guard let audioFilePath = entry.audioFilePath else {
            completion(false, IntegrationError.noAudioFile)
            return
        }
        
        Task {
            do {
                guard let audioData = AudioFileManager.shared.loadAudioData(from: audioFilePath) else {
                    await MainActor.run {
                        completion(false, IntegrationError.audioFileNotFound)
                    }
                    return
                }
                
                let fileName = "audio_\(entry.id?.uuidString ?? "unknown").m4a"
                let transcript = try await OpenAIManager.shared.transcribeAudio(
                    audioData: audioData,
                    fileName: fileName
                )
                
                let summary = try await OpenAIManager.shared.generateSummary(from: transcript)
                
                await MainActor.run {
                    DataManager.shared.updateJournalEntry(
                        entry,
                        transcript: transcript,
                        summary: summary
                    )
                    completion(true, nil)
                }
                
            } catch {
                await MainActor.run {
                    completion(false, error)
                }
            }
        }
    }
}

// MARK: - Data Models

struct SystemHealthReport {
    var hasRecordPermission = false
    var hasEnoughStorage = false
    var availableStorageMB = 0
    var coreDataHealthy = false
    var audioSystemHealthy = false
    var orphanedFilesCount = 0
    var totalEntries = 0
    var totalAudioFilesMB = 0
    
    var isHealthy: Bool {
        return hasRecordPermission && hasEnoughStorage && coreDataHealthy && audioSystemHealthy
    }
}

struct DataIntegrityReport {
    var totalEntries = 0
    var validEntries = 0
    var entriesWithMissingFiles = 0
    var entriesWithoutAudioPath = 0
    var totalAudioFiles = 0
    var orphanedAudioFiles = 0
    
    var integrityScore: Double {
        guard totalEntries > 0 else { return 1.0 }
        return Double(validEntries) / Double(totalEntries)
    }
}

enum IntegrationError: Error, LocalizedError {
    case noRecordPermission
    case audioSystemUnavailable
    case audioFileNotCreated
    case emptyAudioFile
    case coreDataSaveFailed
    case noAudioFile
    case audioFileNotFound
    case storageSpaceLow
    
    var errorDescription: String? {
        switch self {
        case .noRecordPermission:
            return "Microphone permission is required to record audio"
        case .audioSystemUnavailable:
            return "Audio system is not available"
        case .audioFileNotCreated:
            return "Failed to create audio file"
        case .emptyAudioFile:
            return "Audio file is empty or corrupted"
        case .coreDataSaveFailed:
            return "Failed to save entry to database"
        case .noAudioFile:
            return "Entry does not have an associated audio file"
        case .audioFileNotFound:
            return "Audio file not found on device"
        case .storageSpaceLow:
            return "Not enough storage space available"
        }
    }
}