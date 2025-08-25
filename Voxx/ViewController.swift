import UIKit
import AVFoundation

class MainViewController: UIViewController {
    
    // MARK: - UI Elements
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView = UITableView()
    private let recordButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    private let recordingTimeLabel = UILabel()
    private let playbackControlsView = UIView()
    private let playButton = UIButton(type: .system)
    private let pauseButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let playbackTimeLabel = UILabel()
    private let playbackSlider = UISlider()
    private let playbackTitleLabel = UILabel()
    private let statsHeaderView = UIView()
    private let statsLabel = UILabel()
    
    // MARK: - Data
    private var journalEntries: [JournalEntry] = []
    private var filteredEntries: [JournalEntry] = []
    private var isRecording = false
    private var currentlyPlayingEntry: JournalEntry?
    private var isSearchActive: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    private var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioRecording()
        setupErrorHandling()
        loadJournalEntries()
        
        // Setup refresh control
        setupRefreshControl()
        
        // Setup long press gesture for additional entry actions
        setupLongPressGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data when view appears to catch any external changes
        loadJournalEntries()
        
        // Update navigation bar appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Add debug menu (only in debug builds)
        #if DEBUG
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Debug",
            style: .plain,
            target: self,
            action: #selector(showDebugMenu)
        )
        #endif
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Voxx"
        
        setupSearchController()
        setupStatsHeader()
        setupEmptyStateLabel()
        setupTableView()
        setupRecordButton()
        setupRecordingTimeLabel()
        setupPlaybackControls()
        setupConstraints()
    }
    
    private func setupEmptyStateLabel() {
        emptyStateLabel.text = "No voice entries yet.\nTap the record button to get started!"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search entries..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupStatsHeader() {
        statsHeaderView.backgroundColor = .systemGray6
        statsHeaderView.layer.cornerRadius = 8
        statsHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        statsLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statsLabel.textColor = .secondaryLabel
        statsLabel.textAlignment = .center
        statsLabel.numberOfLines = 2
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        statsHeaderView.addSubview(statsLabel)
        NSLayoutConstraint.activate([
            statsLabel.topAnchor.constraint(equalTo: statsHeaderView.topAnchor, constant: 8),
            statsLabel.leadingAnchor.constraint(equalTo: statsHeaderView.leadingAnchor, constant: 16),
            statsLabel.trailingAnchor.constraint(equalTo: statsHeaderView.trailingAnchor, constant: -16),
            statsLabel.bottomAnchor.constraint(equalTo: statsHeaderView.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(JournalEntryCell.self, forCellReuseIdentifier: "JournalCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
    }
    
    private func setupRecordButton() {
        updateRecordButtonAppearance()
        recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        recordButton.layer.cornerRadius = 25
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
    }
    
    private func setupRecordingTimeLabel() {
        recordingTimeLabel.text = "00:00"
        recordingTimeLabel.textAlignment = .center
        recordingTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        recordingTimeLabel.textColor = .systemRed
        recordingTimeLabel.isHidden = true
        recordingTimeLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupPlaybackControls() {
        // Container view
        playbackControlsView.backgroundColor = .systemBackground
        playbackControlsView.layer.borderWidth = 1
        playbackControlsView.layer.borderColor = UIColor.systemGray4.cgColor
        playbackControlsView.layer.cornerRadius = 12
        playbackControlsView.isHidden = true
        playbackControlsView.translatesAutoresizingMaskIntoConstraints = false
        
        // Title label
        playbackTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        playbackTitleLabel.text = "Now Playing"
        playbackTitleLabel.textAlignment = .center
        playbackTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Control buttons
        playButton.setTitle("▶️", for: .normal)
        playButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        pauseButton.setTitle("⏸", for: .normal)
        pauseButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        
        stopButton.setTitle("⏹", for: .normal)
        stopButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        stopButton.addTarget(self, action: #selector(stopButtonTapped), for: .touchUpInside)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Time label
        playbackTimeLabel.text = "00:00 / 00:00"
        playbackTimeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        playbackTimeLabel.textAlignment = .center
        playbackTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Progress slider
        playbackSlider.minimumValue = 0
        playbackSlider.maximumValue = 1
        playbackSlider.value = 0
        playbackSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        playbackSlider.addTarget(self, action: #selector(sliderTouchBegan), for: .touchDown)
        playbackSlider.addTarget(self, action: #selector(sliderTouchEnded), for: [.touchUpInside, .touchUpOutside])
        playbackSlider.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to container
        playbackControlsView.addSubview(playbackTitleLabel)
        playbackControlsView.addSubview(playButton)
        playbackControlsView.addSubview(pauseButton)
        playbackControlsView.addSubview(stopButton)
        playbackControlsView.addSubview(playbackTimeLabel)
        playbackControlsView.addSubview(playbackSlider)
        
        // Setup constraints within container
        NSLayoutConstraint.activate([
            playbackTitleLabel.topAnchor.constraint(equalTo: playbackControlsView.topAnchor, constant: 12),
            playbackTitleLabel.leadingAnchor.constraint(equalTo: playbackControlsView.leadingAnchor, constant: 16),
            playbackTitleLabel.trailingAnchor.constraint(equalTo: playbackControlsView.trailingAnchor, constant: -16),
            
            playButton.topAnchor.constraint(equalTo: playbackTitleLabel.bottomAnchor, constant: 12),
            playButton.centerXAnchor.constraint(equalTo: playbackControlsView.centerXAnchor, constant: -30),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44),
            
            pauseButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            pauseButton.centerXAnchor.constraint(equalTo: playbackControlsView.centerXAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 44),
            pauseButton.heightAnchor.constraint(equalToConstant: 44),
            
            stopButton.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
            stopButton.centerXAnchor.constraint(equalTo: playbackControlsView.centerXAnchor, constant: 30),
            stopButton.widthAnchor.constraint(equalToConstant: 44),
            stopButton.heightAnchor.constraint(equalToConstant: 44),
            
            playbackSlider.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 12),
            playbackSlider.leadingAnchor.constraint(equalTo: playbackControlsView.leadingAnchor, constant: 20),
            playbackSlider.trailingAnchor.constraint(equalTo: playbackControlsView.trailingAnchor, constant: -20),
            
            playbackTimeLabel.topAnchor.constraint(equalTo: playbackSlider.bottomAnchor, constant: 8),
            playbackTimeLabel.leadingAnchor.constraint(equalTo: playbackControlsView.leadingAnchor, constant: 16),
            playbackTimeLabel.trailingAnchor.constraint(equalTo: playbackControlsView.trailingAnchor, constant: -16),
            playbackTimeLabel.bottomAnchor.constraint(equalTo: playbackControlsView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupConstraints() {
        view.addSubview(statsHeaderView)
        view.addSubview(tableView)
        view.addSubview(playbackControlsView)
        view.addSubview(recordButton)
        view.addSubview(recordingTimeLabel)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            // Stats Header
            statsHeaderView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statsHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statsHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: statsHeaderView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: playbackControlsView.topAnchor, constant: -8),
            
            // Playback Controls
            playbackControlsView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            playbackControlsView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            playbackControlsView.bottomAnchor.constraint(equalTo: recordingTimeLabel.topAnchor, constant: -8),
            
            // Recording Time Label
            recordingTimeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingTimeLabel.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -8),
            
            // Record Button
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            recordButton.widthAnchor.constraint(equalToConstant: 120),
            recordButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Empty State Label
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        
        updateEmptyState()
    }
    
    private func setupAudioRecording() {
        AudioRecordingManager.shared.delegate = self
        AudioPlayerManager.shared.delegate = self
        IntegrationManager.shared.delegate = self
        
        // Perform initial system health check
        performSystemHealthCheck()
    }
    
    private func setupErrorHandling() {
        // Listen for error retry requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleErrorRetry),
            name: .errorRetryRequested,
            object: nil
        )
        
        // Listen for storage management requests
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStorageManagement),
            name: .storageManagementRequested,
            object: nil
        )
    }
    
    @objc private func handleErrorRetry() {
        // Implement context-aware retry logic
        print("Error retry requested - implementing context-aware retry")
        
        // For now, refresh the data and UI
        loadJournalEntries()
        performSystemHealthCheck()
    }
    
    @objc private func handleStorageManagement() {
        showStorageManagement()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        // Check for microphone permission first
        if !AudioSessionManager.shared.hasRecordPermission {
            requestMicrophonePermission()
            return
        }
        
        // Use integrated recording workflow
        IntegrationManager.shared.startCompleteRecordingWorkflow()
    }
    
    private func performSystemHealthCheck() {
        let healthReport = IntegrationManager.shared.performSystemHealthCheck()
        
        if !healthReport.isHealthy {
            showSystemHealthWarning(report: healthReport)
        }
        
        // Check for maintenance needs
        if healthReport.orphanedFilesCount > 0 {
            print("Found \(healthReport.orphanedFilesCount) orphaned audio files")
            // Optionally clean them up automatically or notify user
        }
        
        // Show storage warning if low
        if healthReport.availableStorageMB < 100 {
            showStorageWarning(availableMB: healthReport.availableStorageMB)
        }
    }
    
    private func showSystemHealthWarning(report: SystemHealthReport) {
        var message = "System Health Check:\n"
        
        if !report.hasRecordPermission {
            message += "• Microphone permission required\n"
        }
        if !report.hasEnoughStorage {
            message += "• Low storage space (\(report.availableStorageMB)MB available)\n"
        }
        if !report.audioSystemHealthy {
            message += "• Audio system issues detected\n"
        }
        if !report.coreDataHealthy {
            message += "• Database connectivity issues\n"
        }
        
        let alert = UIAlertController(
            title: "⚠️ System Check",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showStorageWarning(availableMB: Int) {
        let alert = UIAlertController(
            title: "💾 Storage Warning",
            message: "Only \(availableMB)MB of storage remaining. Consider deleting old entries to free up space.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Manage Storage", style: .default) { [weak self] _ in
            self?.showStorageManagement()
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showStorageManagement() {
        let healthReport = IntegrationManager.shared.performSystemHealthCheck()
        let integrityReport = IntegrationManager.shared.validateDataIntegrity()
        
        let message = """
        Storage: \(healthReport.availableStorageMB)MB available
        Entries: \(healthReport.totalEntries)
        Audio Files: \(healthReport.totalAudioFilesMB)MB
        Orphaned Files: \(integrityReport.orphanedAudioFiles)
        """
        
        let alert = UIAlertController(
            title: "Storage Management",
            message: message,
            preferredStyle: .alert
        )
        
        if integrityReport.orphanedAudioFiles > 0 {
            alert.addAction(UIAlertAction(title: "Clean Up Orphaned Files", style: .default) { [weak self] _ in
                self?.performMaintenanceCleanup()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Delete Old Entries", style: .destructive) { [weak self] _ in
            self?.showDeleteOldEntriesOptions()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func performMaintenanceCleanup() {
        IntegrationManager.shared.performMaintenanceCleanup()
        
        let alert = UIAlertController(
            title: "✅ Cleanup Complete",
            message: "Orphaned audio files have been removed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Refresh data
        loadJournalEntries()
    }
    
    private func showDeleteOldEntriesOptions() {
        let alert = UIAlertController(
            title: "Delete Old Entries",
            message: "This will permanently delete entries and cannot be undone.",
            preferredStyle: .actionSheet
        )
        
        // Get entry counts by age
        let allEntries = DataManager.shared.fetchAllJournalEntries()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let oldEntries30 = allEntries.filter { ($0.createdAt ?? Date()) < thirtyDaysAgo }
        let oldEntries7 = allEntries.filter { ($0.createdAt ?? Date()) < sevenDaysAgo }
        
        if oldEntries30.count > 0 {
            alert.addAction(UIAlertAction(title: "Delete Entries Older Than 30 Days (\(oldEntries30.count))", style: .destructive) { [weak self] _ in
                self?.deleteEntriesOlderThan(days: 30)
            })
        }
        
        if oldEntries7.count > 0 {
            alert.addAction(UIAlertAction(title: "Delete Entries Older Than 7 Days (\(oldEntries7.count))", style: .destructive) { [weak self] _ in
                self?.deleteEntriesOlderThan(days: 7)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func deleteEntriesOlderThan(days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let oldEntries = DataManager.shared.fetchAllJournalEntries().filter { ($0.createdAt ?? Date()) < cutoffDate }
        
        for entry in oldEntries {
            DataManager.shared.deleteJournalEntry(entry)
        }
        
        loadJournalEntries()
        
        let alert = UIAlertController(
            title: "✅ Cleanup Complete",
            message: "Deleted \(oldEntries.count) old entries.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func stopRecording() {
        AudioRecordingManager.shared.stopRecording()
    }
    
    private func requestMicrophonePermission() {
        AudioSessionManager.shared.requestRecordPermission { [weak self] granted in
            if granted {
                self?.startRecording()
            } else {
                self?.showPermissionDeniedAlert()
            }
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Microphone Access Required",
            message: "Voxx needs microphone access to record your voice entries. Please enable it in Settings.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func updateRecordButtonAppearance() {
        if isRecording {
            recordButton.setTitle("⏹ Stop", for: .normal)
            recordButton.backgroundColor = .systemGray
        } else {
            recordButton.setTitle("🎤 Record", for: .normal)
            recordButton.backgroundColor = .systemRed
        }
        recordButton.setTitleColor(.white, for: .normal)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Playback Controls
    
    @objc private func playButtonTapped() {
        AudioPlayerManager.shared.play()
    }
    
    @objc private func pauseButtonTapped() {
        AudioPlayerManager.shared.pause()
    }
    
    @objc private func stopButtonTapped() {
        AudioPlayerManager.shared.stop()
        hidePlaybackControls()
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        let duration = AudioPlayerManager.shared.duration
        let newTime = Double(slider.value) * duration
        AudioPlayerManager.shared.seek(to: newTime)
    }
    
    @objc private func sliderTouchBegan(_ slider: UISlider) {
        // User started dragging, we'll handle this if needed
    }
    
    @objc private func sliderTouchEnded(_ slider: UISlider) {
        // User finished dragging, we'll handle this if needed
    }
    
    private func showPlaybackControls(for entry: JournalEntry) {
        currentlyPlayingEntry = entry
        playbackTitleLabel.text = formatDate(entry.createdAt)
        playbackControlsView.isHidden = false
        
        // Load the audio file
        guard let audioFilePath = entry.audioFilePath else { return }
        
        do {
            try AudioPlayerManager.shared.loadAudioFile(at: audioFilePath)
            updatePlaybackControls()
        } catch {
            showErrorAlert(message: error.localizedDescription)
        }
    }
    
    private func hidePlaybackControls() {
        playbackControlsView.isHidden = true
        currentlyPlayingEntry = nil
        AudioPlayerManager.shared.cleanup()
    }
    
    private func updatePlaybackControls() {
        let isPlaying = AudioPlayerManager.shared.isPlaying
        let isPaused = AudioPlayerManager.shared.isPaused
        
        playButton.isHidden = isPlaying
        pauseButton.isHidden = !isPlaying
        
        playButton.isEnabled = !isPlaying
        pauseButton.isEnabled = isPlaying
        stopButton.isEnabled = isPlaying || isPaused
    }
    
    private func updatePlaybackTime(currentTime: TimeInterval, duration: TimeInterval) {
        let currentTimeString = formatTime(currentTime)
        let durationString = formatTime(duration)
        playbackTimeLabel.text = "\(currentTimeString) / \(durationString)"
        
        if duration > 0 {
            playbackSlider.value = Float(currentTime / duration)
        }
    }
    
    private func showErrorAlert(message: String) {
        // Deprecated - use ErrorManager instead
        ErrorManager.shared.logError(
            category: .playback,
            severity: .medium,
            title: "Playback Error",
            message: message
        )
        
        let alert = UIAlertController(
            title: "Playback Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func loadJournalEntries() {
        journalEntries = DataManager.shared.fetchAllJournalEntries()
        filteredEntries = journalEntries
        updateStatsDisplay()
        
        // Animate table view updates
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }
    }
    
    @objc private func handleRefresh() {
        // Simulate network refresh delay (if we had cloud sync)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadJournalEntries()
            self?.tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let point = gesture.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        
        let entries = isSearchActive ? filteredEntries : journalEntries
        let entry = entries[indexPath.row]
        
        showEntryActionSheet(for: entry, at: indexPath)
    }
    
    private func showEntryActionSheet(for entry: JournalEntry, at indexPath: IndexPath) {
        let actionSheet = UIAlertController(title: entry.title, message: nil, preferredStyle: .actionSheet)
        
        // Play action
        actionSheet.addAction(UIAlertAction(title: "Play Recording", style: .default) { [weak self] _ in
            self?.playEntry(entry)
        })
        
        // Share action (if transcript is available)
        if let transcript = entry.transcript, !transcript.isEmpty {
            actionSheet.addAction(UIAlertAction(title: "Share Transcript", style: .default) { [weak self] _ in
                self?.shareTranscript(transcript, title: entry.title ?? "Voice Entry")
            })
        }
        
        // Delete action
        actionSheet.addAction(UIAlertAction(title: "Delete Entry", style: .destructive) { [weak self] _ in
            self?.confirmDeleteEntry(entry)
        })
        
        // Cancel action
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            let cell = tableView.cellForRow(at: indexPath)
            popover.sourceView = cell
            popover.sourceRect = cell?.bounds ?? CGRect.zero
        }
        
        present(actionSheet, animated: true)
    }
    
    private func playEntry(_ entry: JournalEntry) {
        // Stop any current playback
        if AudioPlayerManager.shared.isPlaying || AudioPlayerManager.shared.isPaused {
            AudioPlayerManager.shared.stop()
        }
        
        // Use integrated playback workflow
        IntegrationManager.shared.startCompletePlaybackWorkflow(for: entry)
        
        // Show playback controls for selected entry (if workflow succeeds)
        showPlaybackControls(for: entry)
    }
    
    private func shareTranscript(_ transcript: String, title: String) {
        let shareText = "Voice Entry: \(title)\n\n\(transcript)"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true)
    }
    
    private func confirmDeleteEntry(_ entry: JournalEntry) {
        let alert = UIAlertController(
            title: "Delete Entry",
            message: "Are you sure you want to delete '\(entry.title ?? "this entry")'? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.deleteEntry(entry)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        // Stop playback if this entry is currently playing
        if let currentEntry = currentlyPlayingEntry, currentEntry == entry {
            stopButtonTapped()
        }
        
        // Delete from Core Data
        DataManager.shared.deleteJournalEntry(entry)
        
        // Refresh data with animation
        loadJournalEntries()
        
        // Show success feedback
        showDeleteSuccessMessage()
    }
    
    private func showDeleteSuccessMessage() {
        let alert = UIAlertController(title: "Entry Deleted", message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        
        // Auto-dismiss after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            alert.dismiss(animated: true)
        }
    }
    
    private func updateStatsDisplay() {
        let totalEntries = DataManager.shared.getEntryCount()
        let totalDuration = DataManager.shared.getTotalRecordingDuration()
        let durationString = formatTime(totalDuration)
        
        let firstLine = "\(totalEntries) entries • \(durationString) total"
        let secondLine: String
        
        if let earliestDate = DataManager.shared.getEarliestEntryDate() {
            let daysSince = Calendar.current.dateComponents([.day], from: earliestDate, to: Date()).day ?? 0
            secondLine = "Started \(daysSince) days ago"
        } else {
            secondLine = "No entries yet"
        }
        
        statsLabel.text = "\(firstLine)\n\(secondLine)"
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        if searchText.isEmpty {
            filteredEntries = journalEntries
        } else {
            filteredEntries = DataManager.shared.searchJournalEntries(searchText: searchText)
        }
        tableView.reloadData()
    }
    
    private func updateEmptyState() {
        let entriesToShow = isSearchActive ? filteredEntries : journalEntries
        let isEmpty = entriesToShow.isEmpty
        
        emptyStateLabel.isHidden = !isEmpty
        statsHeaderView.isHidden = isEmpty
        
        if isEmpty {
            if isSearchActive {
                emptyStateLabel.text = "No entries found.\nTry adjusting your search."
            } else {
                emptyStateLabel.text = "No voice entries yet.\nTap the record button to get started!"
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearchActive ? filteredEntries.count : journalEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JournalCell", for: indexPath) as! JournalEntryCell
        let entries = isSearchActive ? filteredEntries : journalEntries
        let entry = entries[indexPath.row]
        
        cell.configure(with: entry)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let entries = isSearchActive ? filteredEntries : journalEntries
            let entryToDelete = entries[indexPath.row]
            
            // Show confirmation alert
            let alert = UIAlertController(
                title: "Delete Entry",
                message: "Are you sure you want to delete this voice entry? This action cannot be undone.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                // Delete from Core Data
                DataManager.shared.deleteJournalEntry(entryToDelete)
                
                // Reload entries
                self?.loadJournalEntries()
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entries = isSearchActive ? filteredEntries : journalEntries
        let entry = entries[indexPath.row]
        
        // Stop any current playback
        if AudioPlayerManager.shared.isPlaying || AudioPlayerManager.shared.isPaused {
            AudioPlayerManager.shared.stop()
        }
        
        // Show playback controls for selected entry
        showPlaybackControls(for: entry)
    }
}

// MARK: - AudioRecordingManagerDelegate
extension MainViewController: AudioRecordingManagerDelegate {
    func recordingDidStart() {
        isRecording = true
        updateRecordButtonAppearance()
        recordingTimeLabel.isHidden = false
    }
    
    func recordingDidStop(audioFilePath: String, duration: TimeInterval) {
        isRecording = false
        updateRecordButtonAppearance()
        recordingTimeLabel.isHidden = true
        recordingTimeLabel.text = "00:00"
        
        // Use integrated workflow for complete recording processing
        IntegrationManager.shared.completeRecordingWorkflow(audioFilePath: audioFilePath, duration: duration)
        
        print("Recording completed: \(audioFilePath), duration: \(duration)")
    }
    
    private func showRecordingSuccessMessage(for entry: JournalEntry) {
        let durationString = formatTime(entry.duration)
        let message = "Recording saved (\(durationString))"
        
        let alert = UIAlertController(title: "✅ Success", message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Play Now", style: .default) { [weak self] _ in
            self?.playEntry(entry)
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
        
        // Auto-dismiss after 3 seconds if no interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if alert.presentingViewController != nil {
                alert.dismiss(animated: true)
            }
        }
    }
    
    func recordingDidFail(error: Error) {
        isRecording = false
        updateRecordButtonAppearance()
        recordingTimeLabel.isHidden = true
        recordingTimeLabel.text = "00:00"
        
        // Use comprehensive error handling
        ErrorManager.shared.handleError(
            error,
            category: .recording,
            context: "Audio Recording",
            presentingViewController: self
        )
    }
    
    func recordingTimeDidUpdate(currentTime: TimeInterval) {
        recordingTimeLabel.text = formatTime(currentTime)
    }
}

// MARK: - AudioPlayerManagerDelegate
extension MainViewController: AudioPlayerManagerDelegate {
    func playbackDidStart() {
        updatePlaybackControls()
    }
    
    func playbackDidPause() {
        updatePlaybackControls()
    }
    
    func playbackDidStop() {
        updatePlaybackControls()
    }
    
    func playbackDidFinish() {
        updatePlaybackControls()
        hidePlaybackControls()
    }
    
    func playbackDidFail(error: Error) {
        updatePlaybackControls()
        
        // Use comprehensive error handling
        ErrorManager.shared.handleError(
            error,
            category: .playback,
            context: "Audio Playback",
            presentingViewController: self
        )
    }
    
    func playbackTimeDidUpdate(currentTime: TimeInterval, duration: TimeInterval) {
        updatePlaybackTime(currentTime: currentTime, duration: duration)
    }
}

// MARK: - UISearchResultsUpdating
extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let searchText = searchController.searchBar.text ?? ""
        filterContentForSearchText(searchText)
        updateEmptyState()
    }
}

// MARK: - Custom Table View Cell
class JournalEntryCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let durationLabel = UILabel()
    private let transcriptPreviewLabel = UILabel()
    private let playIconImageView = UIImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .default
        accessoryType = .none
        
        // Title label
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Date label
        dateLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.numberOfLines = 1
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Duration label
        durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        durationLabel.textColor = .systemBlue
        durationLabel.numberOfLines = 1
        durationLabel.textAlignment = .right
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Transcript preview label
        transcriptPreviewLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        transcriptPreviewLabel.textColor = .tertiaryLabel
        transcriptPreviewLabel.numberOfLines = 2
        transcriptPreviewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Play icon
        playIconImageView.image = UIImage(systemName: "play.circle")
        playIconImageView.tintColor = .systemBlue
        playIconImageView.contentMode = .scaleAspectFit
        playIconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add subviews
        contentView.addSubview(titleLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(durationLabel)
        contentView.addSubview(transcriptPreviewLabel)
        contentView.addSubview(playIconImageView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Play icon
            playIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playIconImageView.widthAnchor.constraint(equalToConstant: 24),
            playIconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // Title label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: playIconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            
            // Duration label
            durationLabel.topAnchor.constraint(equalTo: titleLabel.topAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            // Date label
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: durationLabel.trailingAnchor),
            
            // Transcript preview label
            transcriptPreviewLabel.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 4),
            transcriptPreviewLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            transcriptPreviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            transcriptPreviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with entry: JournalEntry) {
        titleLabel.text = entry.title ?? "Untitled Entry"
        dateLabel.text = formatDate(entry.createdAt)
        durationLabel.text = formatDuration(entry.duration)
        
        // Show transcript preview if available
        if let transcript = entry.transcript, !transcript.isEmpty {
            transcriptPreviewLabel.text = transcript
            transcriptPreviewLabel.isHidden = false
        } else if let summary = entry.summary, !summary.isEmpty {
            transcriptPreviewLabel.text = summary
            transcriptPreviewLabel.isHidden = false
        } else {
            transcriptPreviewLabel.text = "Tap to play recording"
            transcriptPreviewLabel.isHidden = false
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            formatter.timeStyle = .short
            return "Yesterday, \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - IntegrationManagerDelegate
extension MainViewController: IntegrationManagerDelegate {
    func integrationDidCompleteRecordingFlow(success: Bool, entry: JournalEntry?, error: Error?) {
        if success, let entry = entry {
            // Recording workflow completed successfully
            loadJournalEntries()
            showRecordingSuccessMessage(for: entry)
        } else {
            // Recording workflow failed
            isRecording = false
            updateRecordButtonAppearance()
            recordingTimeLabel.isHidden = true
            recordingTimeLabel.text = "00:00"
            
            if let error = error {
                ErrorManager.shared.handleError(
                    error,
                    category: .recording,
                    context: "Recording Workflow",
                    presentingViewController: self
                )
            }
        }
    }
    
    func integrationDidCompletePlaybackFlow(success: Bool, error: Error?) {
        if !success, let error = error {
            ErrorManager.shared.handleError(
                error,
                category: .playback,
                context: "Playback Workflow",
                presentingViewController: self
            )
        }
    }
    
    func integrationDidCompleteDataOperation(success: Bool, error: Error?) {
        if !success, let error = error {
            ErrorManager.shared.handleError(
                error,
                category: .data,
                context: "Data Operation",
                presentingViewController: self
            )
        }
    }
    
    func integrationStorageWarning(availableMB: Int) {
        showStorageWarning(availableMB: availableMB)
    }
    
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    #if DEBUG
    @objc private func showDebugMenu() {
        let alert = UIAlertController(title: "🛠 Debug Menu", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "View Error Log", style: .default) { [weak self] _ in
            self?.showErrorLog()
        })
        
        alert.addAction(UIAlertAction(title: "System Health Check", style: .default) { [weak self] _ in
            self?.showSystemHealthReport()
        })
        
        alert.addAction(UIAlertAction(title: "Data Integrity Check", style: .default) { [weak self] _ in
            self?.showDataIntegrityReport()
        })
        
        alert.addAction(UIAlertAction(title: "Trigger Test Error", style: .destructive) { [weak self] _ in
            self?.triggerTestError()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alert, animated: true)
    }
    
    private func showErrorLog() {
        let errorLogVC = ErrorLogViewController()
        let navController = UINavigationController(rootViewController: errorLogVC)
        present(navController, animated: true)
    }
    
    private func showSystemHealthReport() {
        let healthReport = IntegrationManager.shared.performSystemHealthCheck()
        
        let message = """
        🎤 Record Permission: \(healthReport.hasRecordPermission ? "✅" : "❌")
        💾 Storage: \(healthReport.availableStorageMB)MB available
        📊 Core Data: \(healthReport.coreDataHealthy ? "✅" : "❌")
        🎵 Audio System: \(healthReport.audioSystemHealthy ? "✅" : "❌")
        📁 Orphaned Files: \(healthReport.orphanedFilesCount)
        📝 Total Entries: \(healthReport.totalEntries)
        💿 Audio Files: \(healthReport.totalAudioFilesMB)MB
        """
        
        let alert = UIAlertController(
            title: healthReport.isHealthy ? "✅ System Healthy" : "⚠️ System Issues",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showDataIntegrityReport() {
        let integrityReport = IntegrationManager.shared.validateDataIntegrity()
        
        let message = """
        📊 Data Integrity Score: \(String(format: "%.1f%%", integrityReport.integrityScore * 100))
        
        📝 Total Entries: \(integrityReport.totalEntries)
        ✅ Valid Entries: \(integrityReport.validEntries)
        ❌ Missing Files: \(integrityReport.entriesWithMissingFiles)
        ⚠️ No Audio Path: \(integrityReport.entriesWithoutAudioPath)
        💿 Total Audio Files: \(integrityReport.totalAudioFiles)
        🗂 Orphaned Files: \(integrityReport.orphanedAudioFiles)
        """
        
        let alert = UIAlertController(
            title: "📊 Data Integrity Report",
            message: message,
            preferredStyle: .alert
        )
        
        if integrityReport.orphanedAudioFiles > 0 {
            alert.addAction(UIAlertAction(title: "Clean Up Orphans", style: .destructive) { [weak self] _ in
                self?.performMaintenanceCleanup()
            })
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func triggerTestError() {
        let testError = IntegrationError.audioFileNotFound
        ErrorManager.shared.handleError(
            testError,
            category: .playback,
            context: "Debug Test",
            presentingViewController: self
        )
    }
    #endif
}