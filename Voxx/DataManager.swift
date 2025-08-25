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
        entry.title = "Voice Entry"
        
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
    
    func deleteJournalEntry(_ entry: JournalEntry) {
        context.delete(entry)
        saveContext()
    }
}