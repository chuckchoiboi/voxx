import Foundation

class AudioFileManager {
    static let shared = AudioFileManager()
    
    private init() {}
    
    private var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - File Operations
    
    func generateAudioFilePath() -> String {
        let audioFileName = "voice_entry_\(UUID().uuidString).m4a"
        let audioURL = documentsDirectory.appendingPathComponent(audioFileName)
        return audioURL.path
    }
    
    func audioFileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    func deleteAudioFile(at path: String) -> Bool {
        guard audioFileExists(at: path) else { return true }
        
        do {
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            print("Failed to delete audio file: \(error)")
            return false
        }
    }
    
    func getAudioFileSize(at path: String) -> Int64 {
        guard audioFileExists(at: path) else { return 0 }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            print("Failed to get file size: \(error)")
            return 0
        }
    }
    
    func getAllAudioFiles() -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path)
            return files.filter { $0.hasSuffix(".m4a") }.map { documentsDirectory.appendingPathComponent($0).path }
        } catch {
            print("Failed to get audio files: \(error)")
            return []
        }
    }
    
    func getTotalAudioFilesSize() -> Int64 {
        let audioFiles = getAllAudioFiles()
        return audioFiles.reduce(0) { total, path in
            total + getAudioFileSize(at: path)
        }
    }
    
    func cleanupOrphanedAudioFiles(validPaths: [String]) {
        let allAudioFiles = getAllAudioFiles()
        let orphanedFiles = allAudioFiles.filter { !validPaths.contains($0) }
        
        for orphanedFile in orphanedFiles {
            _ = deleteAudioFile(at: orphanedFile)
            print("Cleaned up orphaned file: \(orphanedFile)")
        }
    }
    
    // MARK: - Storage Management
    
    func getAvailableStorageSpace() -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: documentsDirectory.path)
            return attributes[.systemFreeSize] as? Int64 ?? 0
        } catch {
            print("Failed to get available storage: \(error)")
            return 0
        }
    }
    
    func hasEnoughStorageForRecording(estimatedMB: Int = 10) -> Bool {
        let availableBytes = getAvailableStorageSpace()
        let requiredBytes = Int64(estimatedMB * 1024 * 1024)
        return availableBytes > requiredBytes
    }
    
    // MARK: - Audio Data Loading (for AI Processing)
    
    func loadAudioData(from filePath: String) -> Data? {
        let url = URL(fileURLWithPath: filePath)
        
        do {
            let audioData = try Data(contentsOf: url)
            return audioData
        } catch {
            print("Failed to load audio data from \(filePath): \(error)")
            return nil
        }
    }
}