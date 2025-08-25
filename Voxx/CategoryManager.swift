import Foundation
import CoreData

class CategoryManager {
    static let shared = CategoryManager()
    
    private init() {
        initializePredefinedCategories()
    }
    
    // MARK: - Predefined Categories
    
    enum PredefinedCategory: String, CaseIterable {
        case work = "Work"
        case personal = "Personal"
        case ideas = "Ideas"
        case meetings = "Meetings"
        case reflections = "Reflections"
        
        var color: String {
            switch self {
            case .work: return "#007AFF"        // Blue
            case .personal: return "#FF9500"    // Orange
            case .ideas: return "#FFCC00"       // Yellow
            case .meetings: return "#34C759"    // Green
            case .reflections: return "#AF52DE" // Purple
            }
        }
        
        var icon: String {
            switch self {
            case .work: return "briefcase.fill"
            case .personal: return "person.fill"
            case .ideas: return "lightbulb.fill"
            case .meetings: return "person.3.fill"
            case .reflections: return "heart.fill"
            }
        }
    }
    
    // MARK: - Core Data Context
    
    private var context: NSManagedObjectContext {
        return DataManager.shared.persistentContainer.viewContext
    }
    
    // MARK: - Category CRUD Operations
    
    func createCategory(name: String, color: String, icon: String, isCustom: Bool = true) -> Category {
        let category = Category(context: context)
        category.id = UUID()
        category.name = name
        category.color = color
        category.icon = icon
        category.isCustom = isCustom
        category.createdAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to create category: \(error)")
        }
        
        return category
    }
    
    func fetchAllCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Category.isCustom, ascending: true),
            NSSortDescriptor(keyPath: \Category.name, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch categories: \(error)")
            return []
        }
    }
    
    func fetchPredefinedCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == %@", NSNumber(value: false))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch predefined categories: \(error)")
            return []
        }
    }
    
    func fetchCustomCategories() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isCustom == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch custom categories: \(error)")
            return []
        }
    }
    
    func fetchCategory(byName name: String) -> Category? {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch category by name: \(error)")
            return nil
        }
    }
    
    func updateCategory(_ category: Category, name: String?, color: String?, icon: String?) {
        if let name = name {
            category.name = name
        }
        if let color = color {
            category.color = color
        }
        if let icon = icon {
            category.icon = icon
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to update category: \(error)")
        }
    }
    
    func deleteCategory(_ category: Category) {
        // Don't delete predefined categories
        guard category.isCustom else {
            print("Cannot delete predefined category")
            return
        }
        
        // Unassign category from all entries
        if let entries = category.entries {
            for entry in entries {
                if let journalEntry = entry as? JournalEntry {
                    journalEntry.category = nil
                }
            }
        }
        
        context.delete(category)
        
        do {
            try context.save()
        } catch {
            print("Failed to delete category: \(error)")
        }
    }
    
    // MARK: - Entry Category Management
    
    func assignCategory(_ category: Category?, to entry: JournalEntry) {
        entry.category = category
        
        do {
            try context.save()
        } catch {
            print("Failed to assign category to entry: \(error)")
        }
    }
    
    func removeCategory(from entry: JournalEntry) {
        entry.category = nil
        
        do {
            try context.save()
        } catch {
            print("Failed to remove category from entry: \(error)")
        }
    }
    
    // MARK: - Category Statistics
    
    func getCategoryStatistics() -> [CategoryStatistics] {
        let categories = fetchAllCategories()
        var statistics: [CategoryStatistics] = []
        
        for category in categories {
            let entryCount = category.entries?.count ?? 0
            let totalDuration = calculateTotalDuration(for: category)
            let stat = CategoryStatistics(
                category: category,
                entryCount: entryCount,
                totalDuration: totalDuration
            )
            statistics.append(stat)
        }
        
        // Add uncategorized statistics
        let uncategorizedStats = getUncategorizedStatistics()
        statistics.append(uncategorizedStats)
        
        return statistics.sorted { $0.entryCount > $1.entryCount }
    }
    
    private func calculateTotalDuration(for category: Category) -> TimeInterval {
        guard let entries = category.entries else { return 0 }
        
        var totalDuration: TimeInterval = 0
        for entry in entries {
            if let journalEntry = entry as? JournalEntry {
                totalDuration += journalEntry.duration
            }
        }
        return totalDuration
    }
    
    private func getUncategorizedStatistics() -> CategoryStatistics {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "category == nil")
        
        do {
            let uncategorizedEntries = try context.fetch(request)
            let totalDuration = uncategorizedEntries.reduce(0) { $0 + $1.duration }
            
            // Create a virtual "Uncategorized" category
            let uncategorizedCategory = Category(context: context)
            uncategorizedCategory.name = "Uncategorized"
            uncategorizedCategory.color = "#8E8E93" // Gray
            uncategorizedCategory.icon = "folder"
            uncategorizedCategory.isCustom = false
            
            // Don't save this virtual category to Core Data
            context.rollback()
            
            return CategoryStatistics(
                category: uncategorizedCategory,
                entryCount: uncategorizedEntries.count,
                totalDuration: totalDuration
            )
        } catch {
            print("Failed to get uncategorized statistics: \(error)")
            return CategoryStatistics(category: Category(), entryCount: 0, totalDuration: 0)
        }
    }
    
    // MARK: - Filtering
    
    func fetchEntries(for category: Category) -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch entries for category: \(error)")
            return []
        }
    }
    
    func fetchUncategorizedEntries() -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "category == nil")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch uncategorized entries: \(error)")
            return []
        }
    }
    
    // MARK: - Initialization
    
    private func initializePredefinedCategories() {
        // Check if predefined categories already exist
        let existingPredefined = fetchPredefinedCategories()
        let existingNames = existingPredefined.map { $0.name ?? "" }
        
        for predefinedCategory in PredefinedCategory.allCases {
            if !existingNames.contains(predefinedCategory.rawValue) {
                let _ = createCategory(
                    name: predefinedCategory.rawValue,
                    color: predefinedCategory.color,
                    icon: predefinedCategory.icon,
                    isCustom: false
                )
            }
        }
    }
    
    // MARK: - Bulk Operations
    
    func assignCategory(_ category: Category?, to entries: [JournalEntry]) {
        for entry in entries {
            entry.category = category
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to assign category to entries: \(error)")
        }
    }
    
    func moveAllEntries(from sourceCategory: Category, to targetCategory: Category?) {
        guard let entries = sourceCategory.entries else { return }
        
        for entry in entries {
            if let journalEntry = entry as? JournalEntry {
                journalEntry.category = targetCategory
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to move entries between categories: \(error)")
        }
    }
}

// MARK: - Data Models

struct CategoryStatistics {
    let category: Category
    let entryCount: Int
    let totalDuration: TimeInterval
    
    var formattedDuration: String {
        let minutes = Int(totalDuration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
}