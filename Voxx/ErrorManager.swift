import Foundation
import UIKit

class ErrorManager {
    static let shared = ErrorManager()
    
    private init() {}
    
    // MARK: - Error Categories
    
    enum ErrorCategory {
        case recording
        case playback
        case storage
        case permissions
        case network
        case data
        case system
        
        var icon: String {
            switch self {
            case .recording: return "🎤"
            case .playback: return "▶️"
            case .storage: return "💾"
            case .permissions: return "🔒"
            case .network: return "🌐"
            case .data: return "💿"
            case .system: return "⚠️"
            }
        }
    }
    
    enum ErrorSeverity {
        case low       // Minor issues, app continues normally
        case medium    // Some features affected, user should be notified
        case high      // Major features broken, requires user action
        case critical  // App functionality severely impacted
        
        var title: String {
            switch self {
            case .low: return "Notice"
            case .medium: return "Warning"
            case .high: return "Error"
            case .critical: return "Critical Error"
            }
        }
    }
    
    struct AppError {
        let category: ErrorCategory
        let severity: ErrorSeverity
        let title: String
        let message: String
        let underlyingError: Error?
        let timestamp: Date
        let userInfo: [String: Any]
        
        var formattedMessage: String {
            return "\(category.icon) \(title)\n\n\(message)"
        }
    }
    
    // MARK: - Error Logging
    
    private var errorLog: [AppError] = []
    private let maxLogEntries = 100
    
    func logError(
        category: ErrorCategory,
        severity: ErrorSeverity,
        title: String,
        message: String,
        underlyingError: Error? = nil,
        userInfo: [String: Any] = [:]
    ) {
        let error = AppError(
            category: category,
            severity: severity,
            title: title,
            message: message,
            underlyingError: underlyingError,
            timestamp: Date(),
            userInfo: userInfo
        )
        
        errorLog.append(error)
        
        // Keep log size manageable
        if errorLog.count > maxLogEntries {
            errorLog.removeFirst()
        }
        
        // Print to console for debugging
        print("[\(severity.title)] \(category): \(title) - \(message)")
        if let underlying = underlyingError {
            print("  Underlying error: \(underlying)")
        }
    }
    
    // MARK: - Error Handling Strategies
    
    func handleError(
        _ error: Error,
        category: ErrorCategory,
        context: String,
        presentingViewController: UIViewController? = nil
    ) {
        let severity = determineSeverity(for: error, category: category)
        let (title, message, actions) = generateErrorInfo(for: error, category: category, context: context)
        
        logError(
            category: category,
            severity: severity,
            title: title,
            message: message,
            underlyingError: error
        )
        
        // Show user notification for medium+ severity errors
        if severity.rawValue >= ErrorSeverity.medium.rawValue,
           let presentingVC = presentingViewController {
            showErrorAlert(
                title: "\(severity.title)",
                message: "\(category.icon) \(title)\n\n\(message)",
                actions: actions,
                on: presentingVC
            )
        }
    }
    
    private func determineSeverity(for error: Error, category: ErrorCategory) -> ErrorSeverity {
        // Analyze error type and context to determine severity
        if let integrationError = error as? IntegrationError {
            switch integrationError {
            case .noRecordPermission, .audioSystemUnavailable:
                return .high
            case .coreDataSaveFailed, .audioFileNotCreated:
                return .high
            case .audioFileNotFound, .emptyAudioFile:
                return .medium
            case .noAudioFile:
                return .low
            case .storageSpaceLow:
                return .medium
            }
        }
        
        if let audioError = error as? AudioPlayerError {
            switch audioError {
            case .fileNotFound, .failedToLoadFile:
                return .medium
            case .failedToPlay, .playbackFailed:
                return .low
            case .decodingError:
                return .medium
            }
        }
        
        // Default severity based on category
        switch category {
        case .recording, .data:
            return .high
        case .playback, .storage:
            return .medium
        case .permissions, .system:
            return .high
        case .network:
            return .low
        }
    }
    
    private func generateErrorInfo(
        for error: Error,
        category: ErrorCategory,
        context: String
    ) -> (title: String, message: String, actions: [ErrorAction]) {
        
        var actions: [ErrorAction] = [.dismiss]
        
        if let integrationError = error as? IntegrationError {
            switch integrationError {
            case .noRecordPermission:
                return (
                    title: "Microphone Permission Required",
                    message: "Voxx needs microphone access to record your voice entries. Please grant permission in Settings.",
                    actions: [.openSettings, .dismiss]
                )
                
            case .audioSystemUnavailable:
                return (
                    title: "Audio System Unavailable",
                    message: "The audio system is currently unavailable. Please close other audio apps and try again.",
                    actions: [.retry, .dismiss]
                )
                
            case .coreDataSaveFailed:
                return (
                    title: "Failed to Save Entry",
                    message: "Your recording couldn't be saved to the database. Please try recording again.",
                    actions: [.retry, .dismiss]
                )
                
            case .audioFileNotCreated, .emptyAudioFile:
                return (
                    title: "Recording Error",
                    message: "The audio recording couldn't be created or is empty. Please try recording again.",
                    actions: [.retry, .dismiss]
                )
                
            case .audioFileNotFound:
                return (
                    title: "Audio File Missing",
                    message: "The audio file for this entry could not be found. It may have been deleted or moved.",
                    actions: [.dismiss]
                )
                
            case .storageSpaceLow:
                return (
                    title: "Storage Space Low",
                    message: "Your device is running low on storage space. Consider deleting old entries or freeing up space.",
                    actions: [.manageStorage, .dismiss]
                )
                
            case .noAudioFile:
                return (
                    title: "No Audio File",
                    message: "This entry doesn't have an associated audio file.",
                    actions: [.dismiss]
                )
            }
        }
        
        // Generic error handling
        let localizedDescription = error.localizedDescription
        return (
            title: "Unexpected Error",
            message: "An error occurred in \(context): \(localizedDescription)",
            actions: [.retry, .dismiss]
        )
    }
    
    enum ErrorAction {
        case dismiss
        case retry
        case openSettings
        case manageStorage
        case contactSupport
        
        var title: String {
            switch self {
            case .dismiss: return "OK"
            case .retry: return "Try Again"
            case .openSettings: return "Open Settings"
            case .manageStorage: return "Manage Storage"
            case .contactSupport: return "Get Help"
            }
        }
        
        var style: UIAlertAction.Style {
            switch self {
            case .dismiss: return .default
            case .retry: return .default
            case .openSettings: return .default
            case .manageStorage: return .destructive
            case .contactSupport: return .default
            }
        }
    }
    
    private func showErrorAlert(
        title: String,
        message: String,
        actions: [ErrorAction],
        on viewController: UIViewController
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: action.style) { _ in
                self.handleErrorAction(action, on: viewController)
            }
            alert.addAction(alertAction)
        }
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true)
        }
    }
    
    private func handleErrorAction(_ action: ErrorAction, on viewController: UIViewController) {
        switch action {
        case .dismiss:
            break // Do nothing
            
        case .retry:
            // Post notification for retry
            NotificationCenter.default.post(name: .errorRetryRequested, object: nil)
            
        case .openSettings:
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
            
        case .manageStorage:
            // Post notification for storage management
            NotificationCenter.default.post(name: .storageManagementRequested, object: nil)
            
        case .contactSupport:
            // Open support resources
            showSupportOptions(on: viewController)
        }
    }
    
    private func showSupportOptions(on viewController: UIViewController) {
        let supportVC = ErrorLogViewController()
        supportVC.errorLog = errorLog
        
        let navController = UINavigationController(rootViewController: supportVC)
        viewController.present(navController, animated: true)
    }
    
    // MARK: - Recovery Suggestions
    
    func suggestRecoveryActions(for error: Error, category: ErrorCategory) -> [String] {
        var suggestions: [String] = []
        
        switch category {
        case .recording:
            suggestions = [
                "Check that microphone access is granted",
                "Close other audio apps",
                "Restart the app",
                "Ensure you have enough storage space"
            ]
            
        case .playback:
            suggestions = [
                "Check that the audio file exists",
                "Try playing a different entry",
                "Restart the app"
            ]
            
        case .storage:
            suggestions = [
                "Free up storage space on your device",
                "Delete old voice entries",
                "Clean up orphaned audio files"
            ]
            
        case .permissions:
            suggestions = [
                "Grant microphone permission in Settings",
                "Check privacy settings for the app"
            ]
            
        case .data:
            suggestions = [
                "Restart the app to refresh data",
                "Check available storage space",
                "Try the operation again"
            ]
            
        case .system:
            suggestions = [
                "Restart the app",
                "Restart your device",
                "Update to the latest iOS version"
            ]
            
        case .network:
            suggestions = [
                "Check your internet connection",
                "Try again in a moment",
                "Switch between WiFi and cellular"
            ]
        }
        
        return suggestions
    }
    
    // MARK: - Diagnostics
    
    func generateDiagnosticReport() -> String {
        var report = "=== Voxx Error Diagnostic Report ===\n\n"
        
        report += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n"
        report += "Total Errors: \(errorLog.count)\n\n"
        
        if errorLog.isEmpty {
            report += "No errors recorded.\n"
        } else {
            report += "Recent Errors:\n"
            let recentErrors = Array(errorLog.suffix(10))
            
            for error in recentErrors {
                report += "\n[\(error.category)] \(error.severity.title)\n"
                report += "Time: \(DateFormatter.localizedString(from: error.timestamp, dateStyle: .short, timeStyle: .medium))\n"
                report += "Title: \(error.title)\n"
                report += "Message: \(error.message)\n"
                if let underlying = error.underlyingError {
                    report += "Details: \(underlying)\n"
                }
                report += "---\n"
            }
        }
        
        return report
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let errorRetryRequested = Notification.Name("errorRetryRequested")
    static let storageManagementRequested = Notification.Name("storageManagementRequested")
}

// MARK: - Error Log View Controller

class ErrorLogViewController: UIViewController {
    var errorLog: [ErrorManager.AppError] = []
    
    private let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Error Log"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissViewController)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareErrorLog)
        )
        
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.text = ErrorManager.shared.generateDiagnosticReport()
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    @objc private func shareErrorLog() {
        let report = ErrorManager.shared.generateDiagnosticReport()
        let activityVC = UIActivityViewController(activityItems: [report], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(activityVC, animated: true)
    }
}

// MARK: - Error Severity Extension

extension ErrorManager.ErrorSeverity: Comparable {
    var rawValue: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
    
    static func < (lhs: ErrorManager.ErrorSeverity, rhs: ErrorManager.ErrorSeverity) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}