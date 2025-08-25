import UIKit

class MainViewController: UIViewController {
    
    // MARK: - UI Elements
    private let tableView = UITableView()
    private let recordButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()
    
    // MARK: - Data
    private var journalEntries: [JournalEntry] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadJournalEntries()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Voxx"
        
        setupEmptyStateLabel()
        setupTableView()
        setupRecordButton()
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
        recordButton.setTitle("🎤 Record", for: .normal)
        recordButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        recordButton.backgroundColor = .systemRed
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 25
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.addTarget(self, action: #selector(recordButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        view.addSubview(tableView)
        view.addSubview(recordButton)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: recordButton.topAnchor, constant: -16),
            
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
    
    @objc private func recordButtonTapped() {
        print("Record button tapped - Audio recording not implemented yet")
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