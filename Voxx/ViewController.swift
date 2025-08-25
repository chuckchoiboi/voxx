import UIKit
import AVFoundation

class MainViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let recordButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    private let recordingTimeLabel = UILabel()
    
    // MARK: - Data
    private var journalEntries: [JournalEntry] = []
    private var isRecording = false
    
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
    
    private func setupConstraints() {
        view.addSubview(tableView)
        view.addSubview(recordButton)
        view.addSubview(recordingTimeLabel)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: recordingTimeLabel.topAnchor, constant: -8),
            
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
        print("Selected entry: \(entry.title ?? "Unknown")")
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