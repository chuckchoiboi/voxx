import Foundation
import CoreData
import UIKit

class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Voxx")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Operations
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Journal Entry Operations
    func createJournalEntry(audioFilePath: String, duration: Double) -> JournalEntry {
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.audioFilePath = audioFilePath
        entry.duration = duration
        entry.createdAt = Date()
        entry.title = generateEntryTitle()
        
        saveContext()
        return entry
    }
    
    func fetchAllJournalEntries() -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching journal entries: \(error)")
            return []
        }
    }
    
    func fetchJournalEntries(limit: Int? = nil) -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        if let limit = limit {
            request.fetchLimit = limit
        }
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching journal entries: \(error)")
            return []
        }
    }
    
    func fetchJournalEntries(from startDate: Date, to endDate: Date) -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        let predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        request.predicate = predicate
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching journal entries by date: \(error)")
            return []
        }
    }
    
    func searchJournalEntries(searchText: String) -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR transcript CONTAINS[cd] %@ OR summary CONTAINS[cd] %@", 
                                   searchText, searchText, searchText)
        request.predicate = predicate
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error searching journal entries: \(error)")
            return []
        }
    }
    
    func updateJournalEntry(_ entry: JournalEntry, transcript: String? = nil, summary: String? = nil, title: String? = nil) {
        if let transcript = transcript {
            entry.transcript = transcript
        }
        if let summary = summary {
            entry.summary = summary
        }
        if let title = title {
            entry.title = title
        }
        
        saveContext()
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        // Clean up associated audio file
        if let audioFilePath = entry.audioFilePath {
            _ = AudioFileManager.shared.deleteAudioFile(at: audioFilePath)
        }
        
        context.delete(entry)
        saveContext()
    }
    
    func deleteAllJournalEntries() {
        let request: NSFetchRequest<NSFetchRequestResult> = JournalEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            saveContext()
            
            // Clean up all audio files
            let allAudioFiles = AudioFileManager.shared.getAllAudioFiles()
            for audioFile in allAudioFiles {
                _ = AudioFileManager.shared.deleteAudioFile(at: audioFile)
            }
        } catch {
            print("Error deleting all journal entries: \(error)")
        }
    }
    
    // MARK: - Statistics
    func getEntryCount() -> Int {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        
        do {
            return try context.count(for: request)
        } catch {
            print("Error counting journal entries: \(error)")
            return 0
        }
    }
    
    func getTotalRecordingDuration() -> TimeInterval {
        let entries = fetchAllJournalEntries()
        return entries.reduce(0) { $0 + $1.duration }
    }
    
    func getEarliestEntryDate() -> Date? {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        request.fetchLimit = 1
        
        do {
            let entries = try context.fetch(request)
            return entries.first?.createdAt
        } catch {
            print("Error fetching earliest entry: \(error)")
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func generateEntryTitle() -> String {
        let count = getEntryCount() + 1
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let dateString = formatter.string(from: Date())
        return "Entry #\(count) - \(dateString)"
    }
}