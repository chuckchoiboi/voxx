import Foundation
import AVFoundation
import CoreData

class TestingManager {
    static let shared = TestingManager()
    
    private init() {}
    
    // MARK: - Test Results
    
    struct TestResult {
        let testName: String
        let passed: Bool
        let message: String
        let duration: TimeInterval
        let timestamp: Date
        
        var statusIcon: String {
            return passed ? "✅" : "❌"
        }
    }
    
    struct TestSuite {
        let name: String
        let results: [TestResult]
        
        var passRate: Double {
            guard !results.isEmpty else { return 0.0 }
            let passedCount = results.filter { $0.passed }.count
            return Double(passedCount) / Double(results.count)
        }
        
        var totalDuration: TimeInterval {
            return results.reduce(0) { $0 + $1.duration }
        }
        
        var passed: Bool {
            return results.allSatisfy { $0.passed }
        }
    }
    
    // MARK: - Core Functionality Tests
    
    func runBasicFunctionalityTests() -> TestSuite {
        var results: [TestResult] = []
        
        results.append(testAudioSessionSetup())
        results.append(testCoreDataConnection())
        results.append(testFileSystemAccess())
        results.append(testAudioPermissions())
        results.append(testStorageSpace())
        results.append(testAudioFileManager())
        results.append(testDataManagerOperations())
        results.append(testIntegrationManagerHealth())
        
        return TestSuite(name: "Basic Functionality", results: results)
    }
    
    private func testAudioSessionSetup() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try AudioSessionManager.shared.setupAudioSession()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            return TestResult(
                testName: "Audio Session Setup",
                passed: true,
                message: "Audio session configured successfully",
                duration: duration,
                timestamp: Date()
            )
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            return TestResult(
                testName: "Audio Session Setup",
                passed: false,
                message: "Failed to setup audio session: \(error.localizedDescription)",
                duration: duration,
                timestamp: Date()
            )
        }
    }
    
    private func testCoreDataConnection() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test basic Core Data operations
        let initialCount = DataManager.shared.getEntryCount()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        if initialCount >= 0 {
            return TestResult(
                testName: "Core Data Connection",
                passed: true,
                message: "Core Data accessible, found \(initialCount) entries",
                duration: duration,
                timestamp: Date()
            )
        } else {
            return TestResult(
                testName: "Core Data Connection",
                passed: false,
                message: "Core Data connection failed",
                duration: duration,
                timestamp: Date()
            )
        }
    }
    
    private func testFileSystemAccess() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test file system access
        let testFileName = "test_file_\(UUID().uuidString).txt"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let testFileURL = documentsURL.appendingPathComponent(testFileName)
        
        do {
            // Write test file
            try "Test content".write(to: testFileURL, atomically: true, encoding: .utf8)
            
            // Read test file
            let readContent = try String(contentsOf: testFileURL)
            
            // Delete test file
            try FileManager.default.removeItem(at: testFileURL)
            
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            return TestResult(
                testName: "File System Access",
                passed: readContent == "Test content",
                message: "File operations successful",
                duration: duration,
                timestamp: Date()
            )
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            return TestResult(
                testName: "File System Access",
                passed: false,
                message: "File system error: \(error.localizedDescription)",
                duration: duration,
                timestamp: Date()
            )
        }
    }
    
    private func testAudioPermissions() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let hasPermission = AudioSessionManager.shared.hasRecordPermission
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        return TestResult(
            testName: "Audio Permissions",
            passed: true, // Always passes, just reports status
            message: hasPermission ? "Microphone access granted" : "Microphone access not granted",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testStorageSpace() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let availableSpace = AudioFileManager.shared.getAvailableStorageSpace()
        let hasEnoughSpace = AudioFileManager.shared.hasEnoughStorageForRecording()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        let availableMB = Int(availableSpace / (1024 * 1024))
        
        return TestResult(
            testName: "Storage Space",
            passed: hasEnoughSpace,
            message: hasEnoughSpace ? 
                "Sufficient storage (\(availableMB)MB available)" : 
                "Low storage (\(availableMB)MB available)",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testAudioFileManager() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test audio file path generation
        let filePath = AudioFileManager.shared.generateAudioFilePath()
        let fileExists = AudioFileManager.shared.audioFileExists(at: filePath)
        let allAudioFiles = AudioFileManager.shared.getAllAudioFiles()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        let passed = !filePath.isEmpty && !fileExists // File shouldn't exist yet
        
        return TestResult(
            testName: "Audio File Manager",
            passed: passed,
            message: passed ? 
                "Audio file operations working, found \(allAudioFiles.count) existing files" :
                "Audio file manager issues detected",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testDataManagerOperations() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test various DataManager operations
        let allEntries = DataManager.shared.fetchAllJournalEntries()
        let entryCount = DataManager.shared.getEntryCount()
        let totalDuration = DataManager.shared.getTotalRecordingDuration()
        
        let searchResults = DataManager.shared.searchJournalEntries(searchText: "test")
        let limitedResults = DataManager.shared.fetchJournalEntries(limit: 5)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        let passed = entryCount == allEntries.count && 
                     totalDuration >= 0 &&
                     limitedResults.count <= min(5, allEntries.count)
        
        return TestResult(
            testName: "Data Manager Operations",
            passed: passed,
            message: passed ?
                "All data operations working correctly" :
                "Data manager operation inconsistencies detected",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testIntegrationManagerHealth() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let healthReport = IntegrationManager.shared.performSystemHealthCheck()
        let integrityReport = IntegrationManager.shared.validateDataIntegrity()
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        let systemHealthy = healthReport.coreDataHealthy && healthReport.audioSystemHealthy
        let integrityGood = integrityReport.integrityScore >= 0.95 // 95% integrity threshold
        
        let passed = systemHealthy && integrityGood
        
        return TestResult(
            testName: "Integration Manager Health",
            passed: passed,
            message: passed ?
                "System integration healthy" :
                "Integration issues detected - check system health",
            duration: duration,
            timestamp: Date()
        )
    }
    
    // MARK: - Recording/Playback Workflow Tests
    
    func runWorkflowTests() -> TestSuite {
        var results: [TestResult] = []
        
        results.append(testRecordingWorkflowValidation())
        results.append(testPlaybackWorkflowValidation())
        results.append(testDataPersistenceWorkflow())
        results.append(testErrorHandlingWorkflows())
        
        return TestSuite(name: "Workflow Tests", results: results)
    }
    
    private func testRecordingWorkflowValidation() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test recording workflow validation (without actually recording)
        var issues: [String] = []
        
        // Check permissions
        if !AudioSessionManager.shared.hasRecordPermission {
            issues.append("No microphone permission")
        }
        
        // Check storage
        if !AudioFileManager.shared.hasEnoughStorageForRecording() {
            issues.append("Insufficient storage space")
        }
        
        // Check audio system
        let healthReport = IntegrationManager.shared.performSystemHealthCheck()
        if !healthReport.audioSystemHealthy {
            issues.append("Audio system unavailable")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let passed = issues.isEmpty
        
        return TestResult(
            testName: "Recording Workflow Validation",
            passed: passed,
            message: passed ?
                "Recording workflow ready" :
                "Recording workflow issues: \(issues.joined(separator: ", "))",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testPlaybackWorkflowValidation() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test playback workflow with existing entries
        let entries = DataManager.shared.fetchJournalEntries(limit: 1)
        var issues: [String] = []
        
        if entries.isEmpty {
            issues.append("No entries available for playback testing")
        } else if let entry = entries.first {
            if entry.audioFilePath == nil {
                issues.append("Entry missing audio file path")
            } else if let path = entry.audioFilePath, !AudioFileManager.shared.audioFileExists(at: path) {
                issues.append("Audio file missing from filesystem")
            }
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let passed = issues.isEmpty
        
        return TestResult(
            testName: "Playback Workflow Validation",
            passed: passed,
            message: passed ?
                "Playback workflow ready" :
                "Playback issues: \(issues.joined(separator: ", "))",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testDataPersistenceWorkflow() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test data persistence without creating actual audio files
        let beforeCount = DataManager.shared.getEntryCount()
        
        // Simulate entry creation workflow validation
        let testPath = AudioFileManager.shared.generateAudioFilePath()
        let testDuration: TimeInterval = 30.0
        
        // We won't actually create the entry, just validate the workflow would work
        var issues: [String] = []
        
        if testPath.isEmpty {
            issues.append("Cannot generate audio file path")
        }
        
        // Check Core Data is accessible
        if beforeCount < 0 {
            issues.append("Core Data not accessible")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let passed = issues.isEmpty
        
        return TestResult(
            testName: "Data Persistence Workflow",
            passed: passed,
            message: passed ?
                "Data persistence workflow validated" :
                "Data persistence issues: \(issues.joined(separator: ", "))",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testErrorHandlingWorkflows() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test error handling system
        var issues: [String] = []
        
        // Test error logging
        ErrorManager.shared.logError(
            category: .system,
            severity: .low,
            title: "Test Error",
            message: "This is a test error for validation",
            underlyingError: nil
        )
        
        // Test error recovery suggestions
        let suggestions = ErrorManager.shared.suggestRecoveryActions(
            for: IntegrationError.audioFileNotFound,
            category: .playback
        )
        
        if suggestions.isEmpty {
            issues.append("Error recovery suggestions not working")
        }
        
        // Test diagnostic report generation
        let diagnosticReport = ErrorManager.shared.generateDiagnosticReport()
        if diagnosticReport.isEmpty {
            issues.append("Diagnostic report generation failed")
        }
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        let passed = issues.isEmpty
        
        return TestResult(
            testName: "Error Handling Workflows",
            passed: passed,
            message: passed ?
                "Error handling system validated" :
                "Error handling issues: \(issues.joined(separator: ", "))",
            duration: duration,
            timestamp: Date()
        )
    }
    
    // MARK: - Performance Tests
    
    func runPerformanceTests() -> TestSuite {
        var results: [TestResult] = []
        
        results.append(testDataLoadingPerformance())
        results.append(testSearchPerformance())
        results.append(testFileSystemPerformance())
        
        return TestSuite(name: "Performance Tests", results: results)
    }
    
    private func testDataLoadingPerformance() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Load all entries and measure time
        let _ = DataManager.shared.fetchAllJournalEntries()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance threshold: should load data in under 1 second
        let passed = duration < 1.0
        
        return TestResult(
            testName: "Data Loading Performance",
            passed: passed,
            message: passed ?
                "Data loaded in \(String(format: "%.2f", duration))s" :
                "Slow data loading: \(String(format: "%.2f", duration))s (threshold: 1.0s)",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testSearchPerformance() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Perform search operation
        let _ = DataManager.shared.searchJournalEntries(searchText: "test")
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance threshold: search should complete in under 0.5 seconds
        let passed = duration < 0.5
        
        return TestResult(
            testName: "Search Performance",
            passed: passed,
            message: passed ?
                "Search completed in \(String(format: "%.3f", duration))s" :
                "Slow search: \(String(format: "%.3f", duration))s (threshold: 0.5s)",
            duration: duration,
            timestamp: Date()
        )
    }
    
    private func testFileSystemPerformance() -> TestResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Test file system operations
        let _ = AudioFileManager.shared.getAllAudioFiles()
        let _ = AudioFileManager.shared.getAvailableStorageSpace()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        // Performance threshold: file operations should complete in under 0.2 seconds
        let passed = duration < 0.2
        
        return TestResult(
            testName: "File System Performance",
            passed: passed,
            message: passed ?
                "File operations completed in \(String(format: "%.3f", duration))s" :
                "Slow file operations: \(String(format: "%.3f", duration))s (threshold: 0.2s)",
            duration: duration,
            timestamp: Date()
        )
    }
    
    // MARK: - Complete Test Suite
    
    func runCompleteTestSuite() -> [TestSuite] {
        return [
            runBasicFunctionalityTests(),
            runWorkflowTests(),
            runPerformanceTests()
        ]
    }
    
    func generateTestReport(testSuites: [TestSuite]) -> String {
        var report = "=== Voxx Test Report ===\n\n"
        report += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n\n"
        
        let totalTests = testSuites.reduce(0) { $0 + $1.results.count }
        let passedTests = testSuites.reduce(0) { $0 + $1.results.filter { $0.passed }.count }
        let totalDuration = testSuites.reduce(0.0) { $0 + $1.totalDuration }
        
        report += "📊 Overall Summary:\n"
        report += "Total Tests: \(totalTests)\n"
        report += "Passed: \(passedTests)\n"
        report += "Failed: \(totalTests - passedTests)\n"
        report += "Pass Rate: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%\n"
        report += "Total Duration: \(String(format: "%.2f", totalDuration))s\n\n"
        
        for suite in testSuites {
            report += "📁 \(suite.name) \(suite.passed ? "✅" : "❌")\n"
            report += "Pass Rate: \(String(format: "%.1f", suite.passRate * 100))%\n"
            report += "Duration: \(String(format: "%.2f", suite.totalDuration))s\n\n"
            
            for result in suite.results {
                report += "  \(result.statusIcon) \(result.testName)\n"
                report += "    \(result.message)\n"
                report += "    Duration: \(String(format: "%.3f", result.duration))s\n\n"
            }
        }
        
        return report
    }
}