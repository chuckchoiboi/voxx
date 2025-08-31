import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // OpenAI Section
    private let openAIHeaderView = UIView()
    private let openAITitleLabel = UILabel()
    private let openAISubtitleLabel = UILabel()
    
    private let apiKeyContainerView = UIView()
    private let apiKeyLabel = UILabel()
    private let apiKeyTextField = UITextField()
    private let apiKeyStatusLabel = UILabel()
    private let validateButton = UIButton(type: .system)
    private let saveButton = UIButton(type: .system)
    private let removeKeyButton = UIButton(type: .system)
    
    private let setupInstructionsView = UIView()
    private let instructionsLabel = UILabel()
    private let getAPIKeyButton = UIButton(type: .system)
    
    // Language Selection Section
    private let languageHeaderView = UIView()
    private let languageTitleLabel = UILabel()
    private let languageSubtitleLabel = UILabel()
    private let languageSelectionView = UIView()
    private let languageButton = UIButton(type: .system)
    
    // App Info Section
    private let appInfoHeaderView = UIView()
    private let appInfoTitleLabel = UILabel()
    private let versionLabel = UILabel()
    private let aboutLabel = UILabel()
    
    private var isValidating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadCurrentAPIKeyStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCurrentAPIKeyStatus()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Settings"
        
        // Navigation
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        setupScrollView()
        setupOpenAISection()
        setupLanguageSection()
        setupAppInfoSection()
        setupConstraints()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }
    
    private func setupOpenAISection() {
        // Header
        openAIHeaderView.backgroundColor = .secondarySystemGroupedBackground
        openAIHeaderView.layer.cornerRadius = 12
        openAIHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        openAITitleLabel.text = "🤖 OpenAI Integration"
        openAITitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        openAITitleLabel.textColor = .label
        openAITitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        openAISubtitleLabel.text = "Enable AI features with your OpenAI API key"
        openAISubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        openAISubtitleLabel.textColor = .secondaryLabel
        openAISubtitleLabel.numberOfLines = 0
        openAISubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        openAIHeaderView.addSubview(openAITitleLabel)
        openAIHeaderView.addSubview(openAISubtitleLabel)
        
        // API Key Container
        apiKeyContainerView.backgroundColor = .secondarySystemGroupedBackground
        apiKeyContainerView.layer.cornerRadius = 12
        apiKeyContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        apiKeyLabel.text = "API Key"
        apiKeyLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        apiKeyLabel.textColor = .label
        apiKeyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        apiKeyTextField.placeholder = "sk-..."
        apiKeyTextField.borderStyle = .roundedRect
        apiKeyTextField.backgroundColor = .systemBackground
        apiKeyTextField.isSecureTextEntry = true
        apiKeyTextField.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        apiKeyTextField.translatesAutoresizingMaskIntoConstraints = false
        apiKeyTextField.addTarget(self, action: #selector(apiKeyTextChanged), for: .editingChanged)
        
        apiKeyStatusLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        apiKeyStatusLabel.numberOfLines = 0
        apiKeyStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        validateButton.setTitle("Validate Key", for: .normal)
        validateButton.backgroundColor = .systemBlue
        validateButton.setTitleColor(.white, for: .normal)
        validateButton.layer.cornerRadius = 8
        validateButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        validateButton.translatesAutoresizingMaskIntoConstraints = false
        validateButton.addTarget(self, action: #selector(validateButtonTapped), for: .touchUpInside)
        
        saveButton.setTitle("Save Key", for: .normal)
        saveButton.backgroundColor = .systemGreen
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        
        removeKeyButton.setTitle("Remove Key", for: .normal)
        removeKeyButton.backgroundColor = .systemRed
        removeKeyButton.setTitleColor(.white, for: .normal)
        removeKeyButton.layer.cornerRadius = 8
        removeKeyButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        removeKeyButton.translatesAutoresizingMaskIntoConstraints = false
        removeKeyButton.addTarget(self, action: #selector(removeKeyButtonTapped), for: .touchUpInside)
        
        apiKeyContainerView.addSubview(apiKeyLabel)
        apiKeyContainerView.addSubview(apiKeyTextField)
        apiKeyContainerView.addSubview(apiKeyStatusLabel)
        apiKeyContainerView.addSubview(validateButton)
        apiKeyContainerView.addSubview(saveButton)
        apiKeyContainerView.addSubview(removeKeyButton)
        
        // Setup Instructions
        setupInstructionsView.backgroundColor = .secondarySystemGroupedBackground
        setupInstructionsView.layer.cornerRadius = 12
        setupInstructionsView.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsLabel.text = """
        How to get your OpenAI API Key:
        
        1. Visit platform.openai.com
        2. Sign in to your OpenAI account
        3. Navigate to API Keys section
        4. Create a new API key
        5. Copy and paste it above
        
        Your API key is stored securely on this device and never shared.
        """
        instructionsLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        instructionsLabel.textColor = .secondaryLabel
        instructionsLabel.numberOfLines = 0
        instructionsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        getAPIKeyButton.setTitle("🌐 Get OpenAI API Key", for: .normal)
        getAPIKeyButton.backgroundColor = .systemBlue
        getAPIKeyButton.setTitleColor(.white, for: .normal)
        getAPIKeyButton.layer.cornerRadius = 8
        getAPIKeyButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        getAPIKeyButton.translatesAutoresizingMaskIntoConstraints = false
        getAPIKeyButton.addTarget(self, action: #selector(getAPIKeyButtonTapped), for: .touchUpInside)
        
        setupInstructionsView.addSubview(instructionsLabel)
        setupInstructionsView.addSubview(getAPIKeyButton)
        
        // Add to content view
        contentView.addSubview(openAIHeaderView)
        contentView.addSubview(apiKeyContainerView)
        contentView.addSubview(setupInstructionsView)
    }
    
    private func setupLanguageSection() {
        // Header
        languageHeaderView.backgroundColor = .secondarySystemGroupedBackground
        languageHeaderView.layer.cornerRadius = 12
        languageHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        languageTitleLabel.text = "🌍 Transcription Language"
        languageTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        languageTitleLabel.textColor = .label
        languageTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        languageSubtitleLabel.text = "Choose the language for AI transcription and translation"
        languageSubtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        languageSubtitleLabel.textColor = .secondaryLabel
        languageSubtitleLabel.numberOfLines = 0
        languageSubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        languageHeaderView.addSubview(languageTitleLabel)
        languageHeaderView.addSubview(languageSubtitleLabel)
        
        // Language Selection
        languageSelectionView.backgroundColor = .secondarySystemGroupedBackground
        languageSelectionView.layer.cornerRadius = 12
        languageSelectionView.translatesAutoresizingMaskIntoConstraints = false
        
        languageButton.backgroundColor = .systemBlue
        languageButton.setTitleColor(.white, for: .normal)
        languageButton.layer.cornerRadius = 8
        languageButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        languageButton.contentHorizontalAlignment = .center
        languageButton.translatesAutoresizingMaskIntoConstraints = false
        languageButton.addTarget(self, action: #selector(languageButtonTapped), for: .touchUpInside)
        
        updateLanguageButton()
        
        languageSelectionView.addSubview(languageButton)
        
        NSLayoutConstraint.activate([
            // Language Header
            languageTitleLabel.topAnchor.constraint(equalTo: languageHeaderView.topAnchor, constant: 16),
            languageTitleLabel.leadingAnchor.constraint(equalTo: languageHeaderView.leadingAnchor, constant: 16),
            languageTitleLabel.trailingAnchor.constraint(equalTo: languageHeaderView.trailingAnchor, constant: -16),
            
            languageSubtitleLabel.topAnchor.constraint(equalTo: languageTitleLabel.bottomAnchor, constant: 4),
            languageSubtitleLabel.leadingAnchor.constraint(equalTo: languageHeaderView.leadingAnchor, constant: 16),
            languageSubtitleLabel.trailingAnchor.constraint(equalTo: languageHeaderView.trailingAnchor, constant: -16),
            languageSubtitleLabel.bottomAnchor.constraint(equalTo: languageHeaderView.bottomAnchor, constant: -16),
            
            // Language Button
            languageButton.topAnchor.constraint(equalTo: languageSelectionView.topAnchor, constant: 16),
            languageButton.leadingAnchor.constraint(equalTo: languageSelectionView.leadingAnchor, constant: 16),
            languageButton.trailingAnchor.constraint(equalTo: languageSelectionView.trailingAnchor, constant: -16),
            languageButton.heightAnchor.constraint(equalToConstant: 44),
            languageButton.bottomAnchor.constraint(equalTo: languageSelectionView.bottomAnchor, constant: -16)
        ])
        
        contentView.addSubview(languageHeaderView)
        contentView.addSubview(languageSelectionView)
    }
    
    private func setupAppInfoSection() {
        appInfoHeaderView.backgroundColor = .secondarySystemGroupedBackground
        appInfoHeaderView.layer.cornerRadius = 12
        appInfoHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        appInfoTitleLabel.text = "📱 App Information"
        appInfoTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        appInfoTitleLabel.textColor = .label
        appInfoTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        versionLabel.text = "Version \(appVersion) (\(buildNumber))"
        versionLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        versionLabel.textColor = .secondaryLabel
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        aboutLabel.text = """
        Voxx is your personal voice journaling companion with AI-powered transcription and insights.
        
        Features:
        • Voice recording with playback
        • AI transcription using OpenAI Whisper
        • Smart summaries and insights
        • Category and tag organization
        • Secure local storage
        """
        aboutLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        aboutLabel.textColor = .secondaryLabel
        aboutLabel.numberOfLines = 0
        aboutLabel.translatesAutoresizingMaskIntoConstraints = false
        
        appInfoHeaderView.addSubview(appInfoTitleLabel)
        appInfoHeaderView.addSubview(versionLabel)
        appInfoHeaderView.addSubview(aboutLabel)
        
        contentView.addSubview(appInfoHeaderView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // OpenAI Header
            openAIHeaderView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            openAIHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            openAIHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            openAITitleLabel.topAnchor.constraint(equalTo: openAIHeaderView.topAnchor, constant: 16),
            openAITitleLabel.leadingAnchor.constraint(equalTo: openAIHeaderView.leadingAnchor, constant: 16),
            openAITitleLabel.trailingAnchor.constraint(equalTo: openAIHeaderView.trailingAnchor, constant: -16),
            
            openAISubtitleLabel.topAnchor.constraint(equalTo: openAITitleLabel.bottomAnchor, constant: 4),
            openAISubtitleLabel.leadingAnchor.constraint(equalTo: openAIHeaderView.leadingAnchor, constant: 16),
            openAISubtitleLabel.trailingAnchor.constraint(equalTo: openAIHeaderView.trailingAnchor, constant: -16),
            openAISubtitleLabel.bottomAnchor.constraint(equalTo: openAIHeaderView.bottomAnchor, constant: -16),
            
            // API Key Container
            apiKeyContainerView.topAnchor.constraint(equalTo: openAIHeaderView.bottomAnchor, constant: 12),
            apiKeyContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            apiKeyContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            apiKeyLabel.topAnchor.constraint(equalTo: apiKeyContainerView.topAnchor, constant: 16),
            apiKeyLabel.leadingAnchor.constraint(equalTo: apiKeyContainerView.leadingAnchor, constant: 16),
            apiKeyLabel.trailingAnchor.constraint(equalTo: apiKeyContainerView.trailingAnchor, constant: -16),
            
            apiKeyTextField.topAnchor.constraint(equalTo: apiKeyLabel.bottomAnchor, constant: 8),
            apiKeyTextField.leadingAnchor.constraint(equalTo: apiKeyContainerView.leadingAnchor, constant: 16),
            apiKeyTextField.trailingAnchor.constraint(equalTo: apiKeyContainerView.trailingAnchor, constant: -16),
            apiKeyTextField.heightAnchor.constraint(equalToConstant: 44),
            
            apiKeyStatusLabel.topAnchor.constraint(equalTo: apiKeyTextField.bottomAnchor, constant: 8),
            apiKeyStatusLabel.leadingAnchor.constraint(equalTo: apiKeyContainerView.leadingAnchor, constant: 16),
            apiKeyStatusLabel.trailingAnchor.constraint(equalTo: apiKeyContainerView.trailingAnchor, constant: -16),
            
            validateButton.topAnchor.constraint(equalTo: apiKeyStatusLabel.bottomAnchor, constant: 16),
            validateButton.leadingAnchor.constraint(equalTo: apiKeyContainerView.leadingAnchor, constant: 16),
            validateButton.widthAnchor.constraint(equalToConstant: 100),
            validateButton.heightAnchor.constraint(equalToConstant: 36),
            
            saveButton.topAnchor.constraint(equalTo: apiKeyStatusLabel.bottomAnchor, constant: 16),
            saveButton.leadingAnchor.constraint(equalTo: validateButton.trailingAnchor, constant: 12),
            saveButton.widthAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 36),
            
            removeKeyButton.topAnchor.constraint(equalTo: apiKeyStatusLabel.bottomAnchor, constant: 16),
            removeKeyButton.trailingAnchor.constraint(equalTo: apiKeyContainerView.trailingAnchor, constant: -16),
            removeKeyButton.widthAnchor.constraint(equalToConstant: 100),
            removeKeyButton.heightAnchor.constraint(equalToConstant: 36),
            removeKeyButton.bottomAnchor.constraint(equalTo: apiKeyContainerView.bottomAnchor, constant: -16),
            
            // Setup Instructions
            setupInstructionsView.topAnchor.constraint(equalTo: apiKeyContainerView.bottomAnchor, constant: 12),
            setupInstructionsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            setupInstructionsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            instructionsLabel.topAnchor.constraint(equalTo: setupInstructionsView.topAnchor, constant: 16),
            instructionsLabel.leadingAnchor.constraint(equalTo: setupInstructionsView.leadingAnchor, constant: 16),
            instructionsLabel.trailingAnchor.constraint(equalTo: setupInstructionsView.trailingAnchor, constant: -16),
            
            getAPIKeyButton.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 16),
            getAPIKeyButton.leadingAnchor.constraint(equalTo: setupInstructionsView.leadingAnchor, constant: 16),
            getAPIKeyButton.trailingAnchor.constraint(equalTo: setupInstructionsView.trailingAnchor, constant: -16),
            getAPIKeyButton.heightAnchor.constraint(equalToConstant: 44),
            getAPIKeyButton.bottomAnchor.constraint(equalTo: setupInstructionsView.bottomAnchor, constant: -16),
            
            // Language Header
            languageHeaderView.topAnchor.constraint(equalTo: setupInstructionsView.bottomAnchor, constant: 24),
            languageHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            languageHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Language Selection
            languageSelectionView.topAnchor.constraint(equalTo: languageHeaderView.bottomAnchor, constant: 12),
            languageSelectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            languageSelectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // App Info
            appInfoHeaderView.topAnchor.constraint(equalTo: languageSelectionView.bottomAnchor, constant: 24),
            appInfoHeaderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            appInfoHeaderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            appInfoHeaderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            appInfoTitleLabel.topAnchor.constraint(equalTo: appInfoHeaderView.topAnchor, constant: 16),
            appInfoTitleLabel.leadingAnchor.constraint(equalTo: appInfoHeaderView.leadingAnchor, constant: 16),
            appInfoTitleLabel.trailingAnchor.constraint(equalTo: appInfoHeaderView.trailingAnchor, constant: -16),
            
            versionLabel.topAnchor.constraint(equalTo: appInfoTitleLabel.bottomAnchor, constant: 4),
            versionLabel.leadingAnchor.constraint(equalTo: appInfoHeaderView.leadingAnchor, constant: 16),
            versionLabel.trailingAnchor.constraint(equalTo: appInfoHeaderView.trailingAnchor, constant: -16),
            
            aboutLabel.topAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 12),
            aboutLabel.leadingAnchor.constraint(equalTo: appInfoHeaderView.leadingAnchor, constant: 16),
            aboutLabel.trailingAnchor.constraint(equalTo: appInfoHeaderView.trailingAnchor, constant: -16),
            aboutLabel.bottomAnchor.constraint(equalTo: appInfoHeaderView.bottomAnchor, constant: -16)
        ])
    }
    
    private func loadCurrentAPIKeyStatus() {
        if KeychainHelper.shared.hasAPIKey() {
            apiKeyStatusLabel.text = "✅ API Key is configured"
            apiKeyStatusLabel.textColor = .systemGreen
            removeKeyButton.isHidden = false
            
            // Don't show the actual key for security
            apiKeyTextField.text = "••••••••••••••••••••••••••••••••••••••••••••••••••"
        } else {
            apiKeyStatusLabel.text = "⚠️ No API Key configured. AI features disabled."
            apiKeyStatusLabel.textColor = .systemOrange
            removeKeyButton.isHidden = true
            apiKeyTextField.text = ""
        }
        
        updateButtonStates()
    }
    
    private func updateButtonStates() {
        let hasText = !(apiKeyTextField.text?.isEmpty ?? true)
        let hasValidFormat = hasText && KeychainHelper.shared.isValidAPIKeyFormat(apiKeyTextField.text ?? "")
        
        validateButton.isEnabled = hasValidFormat && !isValidating
        saveButton.isEnabled = hasValidFormat && !isValidating
        
        if isValidating {
            validateButton.setTitle("Validating...", for: .normal)
        } else {
            validateButton.setTitle("Validate Key", for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func apiKeyTextChanged() {
        updateButtonStates()
    }
    
    @objc private func validateButtonTapped() {
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else { return }
        
        isValidating = true
        updateButtonStates()
        
        Task {
            do {
                let isValid = try await OpenAIManager.shared.validateAPIKey(apiKey)
                
                DispatchQueue.main.async { [weak self] in
                    self?.isValidating = false
                    
                    if isValid {
                        self?.apiKeyStatusLabel.text = "✅ API Key is valid!"
                        self?.apiKeyStatusLabel.textColor = .systemGreen
                        self?.showAlert(title: "Success", message: "Your API key is valid and ready to use!")
                    } else {
                        self?.apiKeyStatusLabel.text = "❌ Invalid API Key"
                        self?.apiKeyStatusLabel.textColor = .systemRed
                        self?.showAlert(title: "Invalid Key", message: "This API key is not valid. Please check and try again.")
                    }
                    
                    self?.updateButtonStates()
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.isValidating = false
                    self?.apiKeyStatusLabel.text = "❌ Validation failed: \(error.localizedDescription)"
                    self?.apiKeyStatusLabel.textColor = .systemRed
                    self?.updateButtonStates()
                }
            }
        }
    }
    
    @objc private func saveButtonTapped() {
        guard let apiKey = apiKeyTextField.text, !apiKey.isEmpty else { return }
        
        let success = KeychainHelper.shared.storeAPIKey(apiKey)
        
        if success {
            showAlert(title: "Saved", message: "Your API key has been securely saved!") { [weak self] in
                self?.loadCurrentAPIKeyStatus()
            }
        } else {
            showAlert(title: "Error", message: "Failed to save API key. Please try again.")
        }
    }
    
    @objc private func removeKeyButtonTapped() {
        let alert = UIAlertController(
            title: "Remove API Key",
            message: "Are you sure you want to remove your OpenAI API key? This will disable all AI features.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { [weak self] _ in
            let success = KeychainHelper.shared.deleteAPIKey()
            
            if success {
                self?.showAlert(title: "Removed", message: "Your API key has been removed.") { [weak self] in
                    self?.loadCurrentAPIKeyStatus()
                }
            } else {
                self?.showAlert(title: "Error", message: "Failed to remove API key. Please try again.")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func getAPIKeyButtonTapped() {
        if let url = URL(string: "https://platform.openai.com/api-keys") {
            UIApplication.shared.open(url)
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
    // MARK: - Language Selection
    
    private func updateLanguageButton() {
        let selectedLanguage = LanguagePreferences.shared.getSelectedLanguage()
        languageButton.setTitle("\(selectedLanguage.flag) \(selectedLanguage.name)", for: .normal)
    }
    
    @objc private func languageButtonTapped() {
        showLanguageSelection()
    }
    
    private func showLanguageSelection() {
        let alert = UIAlertController(
            title: "Select Transcription Language",
            message: "Choose the language for AI transcription. Audio will be transcribed and translated to this language.",
            preferredStyle: .actionSheet
        )
        
        let languages = LanguagePreferences.Language.supportedLanguages
        let currentLanguage = LanguagePreferences.shared.getSelectedLanguage()
        
        for language in languages {
            let action = UIAlertAction(title: "\(language.flag) \(language.name)", style: .default) { [weak self] _ in
                LanguagePreferences.shared.setSelectedLanguage(language)
                self?.updateLanguageButton()
            }
            
            // Mark current selection
            if language.code == currentLanguage.code {
                action.setValue(true, forKey: "checked")
            }
            
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = languageButton
            popover.sourceRect = languageButton.bounds
        }
        
        present(alert, animated: true)
    }
}