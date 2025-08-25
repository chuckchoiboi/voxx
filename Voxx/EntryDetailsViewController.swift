import UIKit
import AVFoundation

class EntryDetailsViewController: UIViewController {
    
    // MARK: - Properties
    
    var entry: JournalEntry!
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    private var isPlaying = false
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let categoryBadge = UILabel()
    private let timestampLabel = UILabel()
    private let durationLabel = UILabel()
    
    private let audioPlayerView = UIView()
    private let playPauseButton = UIButton()
    private let progressSlider = UISlider()
    private let currentTimeLabel = UILabel()
    private let totalTimeLabel = UILabel()
    
    private let summaryCard = UIView()
    private let summaryHeaderLabel = UILabel()
    private let summaryTextLabel = UILabel()
    
    private let transcriptSection = UIView()
    private let transcriptHeaderLabel = UILabel()
    private let transcriptTextView = UITextView()
    
    private let tagsSection = UIView()
    private let tagsHeaderLabel = UILabel()
    private let tagsCollectionView: UICollectionView
    private let addTagButton = UIButton()
    
    private let actionToolbar = UIToolbar()
    private var tags: [Tag] = []
    
    // MARK: - Initialization
    
    init(entry: JournalEntry) {
        self.entry = entry
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        self.tagsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureContent()
        loadTags()
        setupAudioPlayer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayback()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation
        navigationItem.title = "Entry Details"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissViewController)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(showActionMenu)
        )
        
        // Scroll view setup
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Header setup
        headerView.backgroundColor = .secondarySystemBackground
        headerView.layer.cornerRadius = 12
        contentView.addSubview(headerView)
        
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.numberOfLines = 0
        headerView.addSubview(titleLabel)
        
        categoryBadge.font = .systemFont(ofSize: 12, weight: .medium)
        categoryBadge.textAlignment = .center
        categoryBadge.layer.cornerRadius = 8
        categoryBadge.clipsToBounds = true
        headerView.addSubview(categoryBadge)
        
        timestampLabel.font = .systemFont(ofSize: 16, weight: .medium)
        timestampLabel.textColor = .secondaryLabel
        headerView.addSubview(timestampLabel)
        
        durationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        durationLabel.textColor = .secondaryLabel
        headerView.addSubview(durationLabel)
        
        // Audio player setup
        setupAudioPlayerView()
        
        // Summary card setup
        setupSummaryCard()
        
        // Transcript section setup
        setupTranscriptSection()
        
        // Tags section setup
        setupTagsSection()
        
        // Action toolbar setup
        setupActionToolbar()
    }
    
    private func setupAudioPlayerView() {
        audioPlayerView.backgroundColor = .tertiarySystemBackground
        audioPlayerView.layer.cornerRadius = 12
        contentView.addSubview(audioPlayerView)
        
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .systemBlue
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        audioPlayerView.addSubview(playPauseButton)
        
        progressSlider.minimumValue = 0
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        audioPlayerView.addSubview(progressSlider)
        
        currentTimeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        currentTimeLabel.textColor = .secondaryLabel
        currentTimeLabel.text = "0:00"
        audioPlayerView.addSubview(currentTimeLabel)
        
        totalTimeLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        totalTimeLabel.textColor = .secondaryLabel
        audioPlayerView.addSubview(totalTimeLabel)
    }
    
    private func setupSummaryCard() {
        summaryCard.backgroundColor = .systemBackground
        summaryCard.layer.cornerRadius = 12
        summaryCard.layer.borderWidth = 1
        summaryCard.layer.borderColor = UIColor.separator.cgColor
        contentView.addSubview(summaryCard)
        
        summaryHeaderLabel.text = "📝 AI Summary"
        summaryHeaderLabel.font = .boldSystemFont(ofSize: 18)
        summaryCard.addSubview(summaryHeaderLabel)
        
        summaryTextLabel.font = .systemFont(ofSize: 16)
        summaryTextLabel.numberOfLines = 0
        summaryTextLabel.textColor = .label
        summaryCard.addSubview(summaryTextLabel)
    }
    
    private func setupTranscriptSection() {
        transcriptSection.backgroundColor = .systemBackground
        transcriptSection.layer.cornerRadius = 12
        transcriptSection.layer.borderWidth = 1
        transcriptSection.layer.borderColor = UIColor.separator.cgColor
        contentView.addSubview(transcriptSection)
        
        transcriptHeaderLabel.text = "💬 Full Transcript"
        transcriptHeaderLabel.font = .boldSystemFont(ofSize: 18)
        transcriptSection.addSubview(transcriptHeaderLabel)
        
        transcriptTextView.font = .systemFont(ofSize: 16)
        transcriptTextView.backgroundColor = .clear
        transcriptTextView.isEditable = false
        transcriptTextView.isSelectable = true
        transcriptTextView.textContainerInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        transcriptSection.addSubview(transcriptTextView)
    }
    
    private func setupTagsSection() {
        tagsSection.backgroundColor = .systemBackground
        tagsSection.layer.cornerRadius = 12
        tagsSection.layer.borderWidth = 1
        tagsSection.layer.borderColor = UIColor.separator.cgColor
        contentView.addSubview(tagsSection)
        
        tagsHeaderLabel.text = "🏷️ Tags"
        tagsHeaderLabel.font = .boldSystemFont(ofSize: 18)
        tagsSection.addSubview(tagsHeaderLabel)
        
        tagsCollectionView.backgroundColor = .clear
        tagsCollectionView.showsHorizontalScrollIndicator = false
        tagsCollectionView.delegate = self
        tagsCollectionView.dataSource = self
        tagsCollectionView.register(TagCell.self, forCellWithReuseIdentifier: "TagCell")
        tagsSection.addSubview(tagsCollectionView)
        
        addTagButton.setTitle("+ Add Tag", for: .normal)
        addTagButton.setTitleColor(.systemBlue, for: .normal)
        addTagButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addTagButton.addTarget(self, action: #selector(addTagButtonTapped), for: .touchUpInside)
        tagsSection.addSubview(addTagButton)
    }
    
    private func setupActionToolbar() {
        actionToolbar.backgroundColor = .systemBackground
        view.addSubview(actionToolbar)
        
        let shareButton = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareEntry)
        )
        
        let editButton = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(editEntry)
        )
        
        let deleteButton = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(deleteEntry)
        )
        deleteButton.tintColor = .systemRed
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        actionToolbar.items = [shareButton, flexibleSpace, editButton, flexibleSpace, deleteButton]
    }
    
    // MARK: - Constraints
    
    private func setupConstraints() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        audioPlayerView.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.translatesAutoresizingMaskIntoConstraints = false
        summaryHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryTextLabel.translatesAutoresizingMaskIntoConstraints = false
        transcriptSection.translatesAutoresizingMaskIntoConstraints = false
        transcriptHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        transcriptTextView.translatesAutoresizingMaskIntoConstraints = false
        tagsSection.translatesAutoresizingMaskIntoConstraints = false
        tagsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        tagsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        addTagButton.translatesAutoresizingMaskIntoConstraints = false
        actionToolbar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: actionToolbar.topAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header view
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Header content
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: categoryBadge.leadingAnchor, constant: -12),
            
            categoryBadge.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            categoryBadge.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            categoryBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            categoryBadge.heightAnchor.constraint(equalToConstant: 24),
            
            timestampLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            timestampLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            durationLabel.centerYAnchor.constraint(equalTo: timestampLabel.centerYAnchor),
            durationLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Audio player view
            audioPlayerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            audioPlayerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            audioPlayerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            audioPlayerView.heightAnchor.constraint(equalToConstant: 80),
            
            // Audio player content
            playPauseButton.centerYAnchor.constraint(equalTo: audioPlayerView.centerYAnchor),
            playPauseButton.leadingAnchor.constraint(equalTo: audioPlayerView.leadingAnchor, constant: 16),
            playPauseButton.widthAnchor.constraint(equalToConstant: 44),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),
            
            currentTimeLabel.centerYAnchor.constraint(equalTo: audioPlayerView.centerYAnchor),
            currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 12),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 50),
            
            totalTimeLabel.centerYAnchor.constraint(equalTo: audioPlayerView.centerYAnchor),
            totalTimeLabel.trailingAnchor.constraint(equalTo: audioPlayerView.trailingAnchor, constant: -16),
            totalTimeLabel.widthAnchor.constraint(equalToConstant: 50),
            
            progressSlider.centerYAnchor.constraint(equalTo: audioPlayerView.centerYAnchor),
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 12),
            progressSlider.trailingAnchor.constraint(equalTo: totalTimeLabel.leadingAnchor, constant: -12),
            
            // Summary card
            summaryCard.topAnchor.constraint(equalTo: audioPlayerView.bottomAnchor, constant: 20),
            summaryCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            summaryCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            summaryHeaderLabel.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 16),
            summaryHeaderLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            summaryHeaderLabel.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            
            summaryTextLabel.topAnchor.constraint(equalTo: summaryHeaderLabel.bottomAnchor, constant: 8),
            summaryTextLabel.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            summaryTextLabel.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -16),
            summaryTextLabel.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -16),
            
            // Transcript section
            transcriptSection.topAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: 20),
            transcriptSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            transcriptSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            transcriptHeaderLabel.topAnchor.constraint(equalTo: transcriptSection.topAnchor, constant: 16),
            transcriptHeaderLabel.leadingAnchor.constraint(equalTo: transcriptSection.leadingAnchor, constant: 16),
            transcriptHeaderLabel.trailingAnchor.constraint(equalTo: transcriptSection.trailingAnchor, constant: -16),
            
            transcriptTextView.topAnchor.constraint(equalTo: transcriptHeaderLabel.bottomAnchor, constant: 8),
            transcriptTextView.leadingAnchor.constraint(equalTo: transcriptSection.leadingAnchor, constant: 16),
            transcriptTextView.trailingAnchor.constraint(equalTo: transcriptSection.trailingAnchor, constant: -16),
            transcriptTextView.bottomAnchor.constraint(equalTo: transcriptSection.bottomAnchor, constant: -16),
            transcriptTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Tags section
            tagsSection.topAnchor.constraint(equalTo: transcriptSection.bottomAnchor, constant: 20),
            tagsSection.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tagsSection.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tagsSection.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            tagsHeaderLabel.topAnchor.constraint(equalTo: tagsSection.topAnchor, constant: 16),
            tagsHeaderLabel.leadingAnchor.constraint(equalTo: tagsSection.leadingAnchor, constant: 16),
            tagsHeaderLabel.trailingAnchor.constraint(equalTo: tagsSection.trailingAnchor, constant: -16),
            
            tagsCollectionView.topAnchor.constraint(equalTo: tagsHeaderLabel.bottomAnchor, constant: 12),
            tagsCollectionView.leadingAnchor.constraint(equalTo: tagsSection.leadingAnchor, constant: 16),
            tagsCollectionView.trailingAnchor.constraint(equalTo: tagsSection.trailingAnchor, constant: -16),
            tagsCollectionView.heightAnchor.constraint(equalToConstant: 40),
            
            addTagButton.topAnchor.constraint(equalTo: tagsCollectionView.bottomAnchor, constant: 12),
            addTagButton.leadingAnchor.constraint(equalTo: tagsSection.leadingAnchor, constant: 16),
            addTagButton.bottomAnchor.constraint(equalTo: tagsSection.bottomAnchor, constant: -16),
            
            // Action toolbar
            actionToolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            actionToolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            actionToolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    // MARK: - Content Configuration
    
    private func configureContent() {
        titleLabel.text = entry.title ?? "Untitled Entry"
        
        // Configure category badge
        if let category = entry.category {
            categoryBadge.text = category.name
            categoryBadge.backgroundColor = UIColor(hex: category.color ?? "#4ECDC4")
            categoryBadge.textColor = .white
            categoryBadge.isHidden = false
        } else {
            categoryBadge.isHidden = true
        }
        
        // Configure timestamps
        if let createdAt = entry.createdAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            timestampLabel.text = formatter.string(from: createdAt)
        }
        
        // Configure duration
        let minutes = Int(entry.duration) / 60
        let seconds = Int(entry.duration) % 60
        durationLabel.text = String(format: "%d:%02d", minutes, seconds)
        totalTimeLabel.text = String(format: "%d:%02d", minutes, seconds)
        progressSlider.maximumValue = Float(entry.duration)
        
        // Configure summary
        if let summary = entry.summary, !summary.isEmpty {
            summaryTextLabel.text = summary
            summaryCard.isHidden = false
        } else {
            summaryCard.isHidden = true
        }
        
        // Configure transcript
        if let transcript = entry.transcript, !transcript.isEmpty {
            transcriptTextView.text = transcript
            transcriptSection.isHidden = false
        } else {
            transcriptTextView.text = "No transcript available. Try processing with AI!"
            transcriptSection.isHidden = false
        }
    }
    
    private func loadTags() {
        if let entryTags = entry.tags {
            tags = entryTags.compactMap { $0 as? Tag }
            tagsCollectionView.reloadData()
        }
    }
    
    // MARK: - Audio Player Setup
    
    private func setupAudioPlayer() {
        guard let audioFilePath = entry.audioFilePath,
              let audioData = AudioFileManager.shared.loadAudioData(from: audioFilePath) else {
            playPauseButton.isEnabled = false
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to setup audio player: \(error)")
            playPauseButton.isEnabled = false
        }
    }
    
    // MARK: - Actions
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
    
    @objc private func showActionMenu() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if OpenAIManager.shared.isAPIKeyConfigured() {
            actionSheet.addAction(UIAlertAction(title: "🤖 Re-process with AI", style: .default) { _ in
                self.processWithAI()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "Edit Category", style: .default) { _ in
            self.editCategory()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    @objc private func playPauseButtonTapped() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    @objc private func progressSliderChanged() {
        audioPlayer?.currentTime = TimeInterval(progressSlider.value)
        updateCurrentTimeLabel()
    }
    
    @objc private func addTagButtonTapped() {
        let alertController = UIAlertController(title: "Add Tags", message: "Enter tags separated by commas", preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "tag1, tag2, tag3"
        }
        
        alertController.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            if let tagText = alertController.textFields?.first?.text, !tagText.isEmpty {
                let tagNames = TagManager.shared.parseTagString(tagText)
                let newTags = TagManager.shared.createOrFetchTags(from: tagNames)
                TagManager.shared.addTags(newTags, to: self.entry)
                self.loadTags()
            }
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    @objc private func shareEntry() {
        var textToShare = entry.title ?? "Voice Entry"
        
        if let summary = entry.summary, !summary.isEmpty {
            textToShare += "\n\nSummary:\n\(summary)"
        }
        
        if let transcript = entry.transcript, !transcript.isEmpty {
            textToShare += "\n\nTranscript:\n\(transcript)"
        }
        
        let activityVC = UIActivityViewController(activityItems: [textToShare], applicationActivities: nil)
        present(activityVC, animated: true)
    }
    
    @objc private func editEntry() {
        // Could open edit mode for title, category, tags, etc.
        editCategory()
    }
    
    @objc private func deleteEntry() {
        let alert = UIAlertController(
            title: "Delete Entry",
            message: "Are you sure you want to delete this entry? This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DataManager.shared.deleteJournalEntry(self.entry)
            self.dismiss(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func processWithAI() {
        let loadingAlert = UIAlertController(
            title: "🤖 Processing with AI",
            message: "Transcribing and summarizing...",
            preferredStyle: .alert
        )
        present(loadingAlert, animated: true)
        
        IntegrationManager.shared.processEntryWithAI(entry) { [weak self] success, error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    if success {
                        self?.configureContent()
                    } else {
                        // Show error message
                        let errorAlert = UIAlertController(
                            title: "Processing Failed",
                            message: error?.localizedDescription ?? "Unknown error",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                }
            }
        }
    }
    
    private func editCategory() {
        let categories = CategoryManager.shared.fetchAllCategories()
        let actionSheet = UIAlertController(title: "Select Category", message: nil, preferredStyle: .actionSheet)
        
        // Add "None" option
        actionSheet.addAction(UIAlertAction(title: "None", style: .default) { _ in
            CategoryManager.shared.assignCategory(nil, to: self.entry)
            self.configureContent()
        })
        
        // Add existing categories
        for category in categories {
            actionSheet.addAction(UIAlertAction(title: category.name, style: .default) { _ in
                CategoryManager.shared.assignCategory(category, to: self.entry)
                self.configureContent()
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - Audio Playback
    
    private func startPlayback() {
        audioPlayer?.play()
        isPlaying = true
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateProgress()
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.pause()
        isPlaying = false
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        progressSlider.value = Float(player.currentTime)
        updateCurrentTimeLabel()
    }
    
    private func updateCurrentTimeLabel() {
        guard let player = audioPlayer else { return }
        let minutes = Int(player.currentTime) / 60
        let seconds = Int(player.currentTime) % 60
        currentTimeLabel.text = String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioPlayerDelegate

extension EntryDetailsViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayback()
        progressSlider.value = 0
        currentTimeLabel.text = "0:00"
    }
}

// MARK: - Collection View

extension EntryDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCell
        cell.configure(with: tags[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tag = tags[indexPath.item]
        let width = (tag.name?.count ?? 0) * 8 + 32 // Approximate width
        return CGSize(width: max(width, 60), height: 32)
    }
}

// MARK: - Tag Cell

class TagCell: UICollectionViewCell {
    private let tagLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .systemGray5
        layer.cornerRadius = 16
        
        tagLabel.font = .systemFont(ofSize: 14, weight: .medium)
        tagLabel.textAlignment = .center
        addSubview(tagLabel)
        
        tagLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tagLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            tagLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            tagLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            tagLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with tag: Tag) {
        tagLabel.text = tag.name
        if let color = tag.color {
            backgroundColor = UIColor(hex: color)?.withAlphaComponent(0.2)
            tagLabel.textColor = UIColor(hex: color)
        }
    }
}

// MARK: - UIColor Extension

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: 1)
                    return
                }
            }
        }
        
        return nil
    }
}