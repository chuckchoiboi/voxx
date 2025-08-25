import UIKit
import AVFoundation

class MainViewController: UIViewController {
    
    // MARK: - UI Elements
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
    
    // MARK: - Data
    private var journalEntries: [JournalEntry] = []
    private var isRecording = false
    private var currentlyPlayingEntry: JournalEntry?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAudioRecording()
        loadJournalEntries()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Voxx"
        
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
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "JournalCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
        view.addSubview(tableView)
        view.addSubview(playbackControlsView)
        view.addSubview(recordButton)
        view.addSubview(recordingTimeLabel)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
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
    }
    
    @objc private func recordButtonTapped() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard AudioSessionManager.shared.hasRecordPermission else {
            requestMicrophonePermission()
            return
        }
        
        AudioRecordingManager.shared.startRecording()
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
        tableView.reloadData()
        updateEmptyState()
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !journalEntries.isEmpty
        tableView.isHidden = journalEntries.isEmpty
    }
}

// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return journalEntries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JournalCell", for: indexPath)
        let entry = journalEntries[indexPath.row]
        
        cell.textLabel?.text = entry.title
        cell.detailTextLabel?.text = formatDate(entry.createdAt)
        cell.accessoryType = .disclosureIndicator
        
        return cell
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
        let entry = journalEntries[indexPath.row]
        
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
        
        // Save the recording to Core Data
        let _ = DataManager.shared.createJournalEntry(audioFilePath: audioFilePath, duration: duration)
        loadJournalEntries()
        
        print("Recording saved: \(audioFilePath), duration: \(duration)")
    }
    
    func recordingDidFail(error: Error) {
        isRecording = false
        updateRecordButtonAppearance()
        recordingTimeLabel.isHidden = true
        recordingTimeLabel.text = "00:00"
        
        let alert = UIAlertController(
            title: "Recording Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        showErrorAlert(message: error.localizedDescription)
    }
    
    func playbackTimeDidUpdate(currentTime: TimeInterval, duration: TimeInterval) {
        updatePlaybackTime(currentTime: currentTime, duration: duration)
    }
}