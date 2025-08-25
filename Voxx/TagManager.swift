import Foundation
import CoreData

class TagManager {
    static let shared = TagManager()
    
    private init() {}
    
    // MARK: - Core Data Context
    
    private var context: NSManagedObjectContext {
        return DataManager.shared.persistentContainer.viewContext
    }
    
    // MARK: - Tag CRUD Operations
    
    func createTag(name: String, color: String? = nil) -> Tag {
        // Check if tag already exists
        if let existingTag = fetchTag(byName: name) {
            return existingTag
        }
        
        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        tag.color = color ?? generateRandomColor()
        tag.usageCount = 0
        tag.createdAt = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to create tag: \(error)")
        }
        
        return tag
    }
    
    func fetchAllTags() -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch tags: \(error)")
            return []
        }
    }
    
    func fetchTag(byName name: String) -> Tag? {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", name.trimmingCharacters(in: .whitespacesAndNewlines))
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch tag by name: \(error)")
            return nil
        }
    }
    
    func searchTags(matching query: String) -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[c] %@", query)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        request.fetchLimit = 10 // Limit for auto-complete
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to search tags: \(error)")
            return []
        }
    }
    
    func updateTag(_ tag: Tag, name: String?, color: String?) {
        if let name = name {
            tag.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let color = color {
            tag.color = color
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to update tag: \(error)")
        }
    }
    
    func deleteTag(_ tag: Tag) {
        // Remove tag from all entries
        if let entries = tag.entries {
            for entry in entries {
                if let journalEntry = entry as? JournalEntry {
                    journalEntry.removeFromTags(tag)
                }
            }
        }
        
        context.delete(tag)
        
        do {
            try context.save()
        } catch {
            print("Failed to delete tag: \(error)")
        }
    }
    
    // MARK: - Entry Tag Management
    
    func addTag(_ tag: Tag, to entry: JournalEntry) {
        entry.addToTags(tag)
        
        // Update usage count
        tag.usageCount += 1
        
        do {
            try context.save()
        } catch {
            print("Failed to add tag to entry: \(error)")
        }
    }
    
    func addTags(_ tags: [Tag], to entry: JournalEntry) {
        for tag in tags {
            entry.addToTags(tag)
            tag.usageCount += 1
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to add tags to entry: \(error)")
        }
    }
    
    func removeTag(_ tag: Tag, from entry: JournalEntry) {
        entry.removeFromTags(tag)
        
        // Update usage count
        if tag.usageCount > 0 {
            tag.usageCount -= 1
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to remove tag from entry: \(error)")
        }
    }
    
    func setTags(_ tags: [Tag], for entry: JournalEntry) {
        // Remove existing tags and update their usage counts
        if let existingTags = entry.tags {
            for existingTag in existingTags {
                if let tag = existingTag as? Tag {
                    if tag.usageCount > 0 {
                        tag.usageCount -= 1
                    }
                }
            }
        }
        
        // Clear existing tags
        entry.tags = NSSet()
        
        // Add new tags and update their usage counts
        for tag in tags {
            entry.addToTags(tag)
            tag.usageCount += 1
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to set tags for entry: \(error)")
        }
    }
    
    // MARK: - Tag Creation from Strings
    
    func createOrFetchTags(from tagNames: [String]) -> [Tag] {
        var tags: [Tag] = []
        
        for tagName in tagNames {
            let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                let tag = createTag(name: trimmedName)
                tags.append(tag)
            }
        }
        
        return tags
    }
    
    func parseTagString(_ tagString: String) -> [String] {
        // Parse tags from a string like "tag1, tag2, tag3" or "#tag1 #tag2"
        let cleanString = tagString.replacingOccurrences(of: "#", with: "")
        let components = cleanString.components(separatedBy: CharacterSet(charactersIn: ",\n"))
        
        return components
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Tag Statistics
    
    func getTagStatistics() -> [TagStatistics] {
        let tags = fetchAllTags()
        var statistics: [TagStatistics] = []
        
        for tag in tags {
            let entryCount = tag.entries?.count ?? 0
            let totalDuration = calculateTotalDuration(for: tag)
            let stat = TagStatistics(
                tag: tag,
                entryCount: entryCount,
                totalDuration: totalDuration
            )
            statistics.append(stat)
        }
        
        return statistics.sorted { $0.usageCount > $1.usageCount }
    }
    
    private func calculateTotalDuration(for tag: Tag) -> TimeInterval {
        guard let entries = tag.entries else { return 0 }
        
        var totalDuration: TimeInterval = 0
        for entry in entries {
            if let journalEntry = entry as? JournalEntry {
                totalDuration += journalEntry.duration
            }
        }
        return totalDuration
    }
    
    func getMostUsedTags(limit: Int = 10) -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.usageCount, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch most used tags: \(error)")
            return []
        }
    }
    
    func getRecentTags(limit: Int = 10) -> [Tag] {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.createdAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch recent tags: \(error)")
            return []
        }
    }
    
    // MARK: - Filtering
    
    func fetchEntries(withTag tag: Tag) -> [JournalEntry] {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "ANY tags == %@", tag)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch entries with tag: \(error)")
            return []
        }
    }
    
    func fetchEntries(withTags tags: [Tag]) -> [JournalEntry] {
        guard !tags.isEmpty else { return [] }
        
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "ALL %@ IN tags", tags)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch entries with tags: \(error)")
            return []
        }
    }
    
    func fetchEntries(withAnyTags tags: [Tag]) -> [JournalEntry] {
        guard !tags.isEmpty else { return [] }
        
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "ANY tags IN %@", tags)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch entries with any tags: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup Operations
    
    func cleanupUnusedTags() {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "usageCount == 0")
        
        do {
            let unusedTags = try context.fetch(request)
            for tag in unusedTags {
                context.delete(tag)
            }
            try context.save()
            print("Cleaned up \(unusedTags.count) unused tags")
        } catch {
            print("Failed to cleanup unused tags: \(error)")
        }
    }
    
    func mergeTags(_ sourceTags: [Tag], into targetTag: Tag) {
        for sourceTag in sourceTags {
            if sourceTag == targetTag { continue }
            
            // Move all entries from source tag to target tag
            if let entries = sourceTag.entries {
                for entry in entries {
                    if let journalEntry = entry as? JournalEntry {
                        journalEntry.removeFromTags(sourceTag)
                        journalEntry.addToTags(targetTag)
                    }
                }
            }
            
            // Update usage count
            targetTag.usageCount += sourceTag.usageCount
            
            // Delete source tag
            context.delete(sourceTag)
        }
        
        do {
            try context.save()
        } catch {
            print("Failed to merge tags: \(error)")
        }
    }
    
    // MARK: - AI-Powered Tag Suggestions
    
    func generateTagSuggestions(for entry: JournalEntry) -> [String] {
        var suggestions: [String] = []
        
        // Extract from transcript if available
        if let transcript = entry.transcript, !transcript.isEmpty {
            suggestions.append(contentsOf: extractKeywordsFromText(transcript))
        }
        
        // Extract from summary if available  
        if let summary = entry.summary, !summary.isEmpty {
            suggestions.append(contentsOf: extractKeywordsFromText(summary))
        }
        
        // Add category-based suggestions
        if let category = entry.category, let categoryName = category.name {
            suggestions.append(categoryName.lowercased())
        }
        
        // Filter out existing tags
        let existingTagNames = (entry.tags?.compactMap { ($0 as? Tag)?.name?.lowercased() }) ?? []
        suggestions = suggestions.filter { !existingTagNames.contains($0.lowercased()) }
        
        // Remove duplicates and limit
        return Array(Set(suggestions)).prefix(5).map { $0 }
    }
    
    private func extractKeywordsFromText(_ text: String) -> [String] {
        // Simple keyword extraction - in a real app you might use NLP
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 } // Only words longer than 3 characters
            .filter { !commonStopWords.contains($0) }
        
        // Return most frequent words
        let wordCounts = Dictionary(grouping: words, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        return Array(wordCounts.prefix(3).map { $0.key })
    }
    
    private let commonStopWords = Set([
        "the", "and", "for", "are", "but", "not", "you", "all", "can", "had", 
        "her", "was", "one", "our", "out", "day", "get", "has", "him", "his", 
        "how", "its", "may", "new", "now", "old", "see", "two", "who", "boy",
        "did", "that", "with", "have", "this", "will", "your", "from", "they",
        "know", "want", "been", "good", "much", "some", "time", "very", "when"
    ])
    
    // MARK: - Utilities
    
    private func generateRandomColor() -> String {
        let colors = [
            "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
            "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E9"
        ]
        return colors.randomElement() ?? "#4ECDC4"
    }
}

// MARK: - Data Models

struct TagStatistics {
    let tag: Tag
    let entryCount: Int
    let totalDuration: TimeInterval
    
    var usageCount: Int32 {
        return tag.usageCount
    }
    
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