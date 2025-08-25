# v0.3.0-core-features Design Document

## Overview
This version focuses on enhancing Voxx with advanced organization, categorization, and content discovery features. Building on the solid foundation of v0.1.0 (basic functionality) and v0.2.0 (AI integration), we now add sophisticated content management capabilities.

## Goals
- Implement a flexible category system for organizing journal entries
- Create detailed entry views with full transcript and summary display
- Add advanced search and filtering capabilities beyond basic text search
- Introduce entry tagging for flexible organization
- Enhance content discovery and navigation

## Current Status Analysis

### ✅ **Already Implemented (v0.1.0-v0.2.0):**
- Entry List View - Chronological display ✓
- Search Functionality - Basic full-text search ✓
- Delete Entries - Swipe and long-press deletion ✓
- Entry Details - Basic playback and content preview ✓

### 🎯 **New Features for v0.3.0:**
- **Categories System** - Predefined and custom categories
- **Enhanced Entry Details** - Full-screen transcript and summary view
- **Advanced Search** - Filter by category, date range, duration, AI status
- **Tagging System** - Flexible labeling and organization
- **Smart Filters** - Quick access to common entry groups

## Architecture

### Core Components

#### 1. Category Management System
**Purpose**: Organize entries into meaningful groups
- **Predefined Categories**: Work, Personal, Ideas, Meetings, Reflections
- **Custom Categories**: User-defined categories with colors and icons
- **Category Assignment**: Single category per entry (upgradeable to multiple)
- **Category Statistics**: Entry counts, total duration per category

**Technical Implementation**:
```swift
enum PredefinedCategory: String, CaseIterable {
    case work = "Work"
    case personal = "Personal"
    case ideas = "Ideas"
    case meetings = "Meetings"
    case reflections = "Reflections"
    case none = "Uncategorized"
}

class CategoryManager {
    // Category CRUD operations
    // Statistics and analytics
    // Color and icon management
}
```

#### 2. Enhanced Entry Details View
**Purpose**: Full-featured entry viewing and editing
- **Full Transcript Display**: Scrollable, selectable text
- **Summary Section**: AI-generated insights prominently displayed
- **Playback Controls**: Integrated audio player with timeline
- **Metadata Display**: Date, duration, category, tags, AI status
- **Action Menu**: Share, delete, re-process, edit category/tags

**UI/UX Design**:
- **Hero Section**: Title, category badge, timestamp
- **Audio Player**: Waveform visualization, playback controls
- **Content Sections**: Summary card, full transcript expandable
- **Action Bar**: Bottom toolbar with primary actions

#### 3. Advanced Search & Filtering
**Purpose**: Powerful content discovery and organization
- **Multi-criteria Search**: Text, category, date range, duration, tags
- **Smart Filters**: Recent, Long entries, AI-processed, Favorites
- **Search Suggestions**: Auto-complete based on content and categories
- **Saved Searches**: Bookmark complex search queries

**Search Architecture**:
```swift
struct SearchCriteria {
    var text: String?
    var categories: [String]
    var dateRange: DateRange?
    var durationRange: DurationRange?
    var tags: [String]
    var hasTranscript: Bool?
    var hasSummary: Bool?
}

class AdvancedSearchManager {
    // Complex search query building
    // Search result ranking and relevance
    // Search history and suggestions
}
```

#### 4. Tagging System
**Purpose**: Flexible, multi-dimensional organization
- **Freeform Tags**: User-defined labels without restrictions
- **Tag Auto-complete**: Suggest existing tags while typing
- **Tag Management**: Rename, merge, delete unused tags
- **Tag-based Filtering**: Quick filtering by single or multiple tags
- **Tag Statistics**: Most used tags, tag combinations

**Implementation Strategy**:
- **Core Data Entity**: Tag with many-to-many relationship to JournalEntry
- **UI Integration**: Tag input field with auto-complete
- **Visual Design**: Pill-style tag display with colors
- **Smart Suggestions**: AI-powered tag suggestions based on content

## Technical Specifications

### Data Model Updates

#### Core Data Schema Changes:
```swift
// New Category entity
entity Category {
    id: UUID
    name: String
    color: String // Hex color code
    icon: String // SF Symbol name
    isCustom: Bool
    createdAt: Date
}

// New Tag entity  
entity Tag {
    id: UUID
    name: String
    color: String
    usageCount: Int32
    createdAt: Date
}

// Updated JournalEntry relationships
entity JournalEntry {
    // ... existing properties
    category: Category? (optional relationship)
    tags: [Tag] (many-to-many relationship)
}
```

#### DataManager Extensions:
```swift
extension DataManager {
    // Category management
    func createCategory(_ name: String, color: String, icon: String) -> Category
    func fetchAllCategories() -> [Category]
    func updateEntryCategory(_ entry: JournalEntry, category: Category?)
    
    // Tag management
    func createTag(_ name: String) -> Tag
    func fetchAllTags() -> [Tag]
    func addTag(_ tag: Tag, to entry: JournalEntry)
    func removeTag(_ tag: Tag, from entry: JournalEntry)
    
    // Advanced search
    func searchEntries(criteria: SearchCriteria) -> [JournalEntry]
}
```

### UI/UX Implementation

#### 1. Enhanced Main View
- **Category Filter Bar**: Horizontal scrollable category chips
- **Search Enhancement**: Advanced search button with filter count badge
- **Entry Cell Updates**: Category badge, tag pills, enhanced content preview

#### 2. Entry Details View (New)
- **Modal Presentation**: Full-screen modal for immersive experience
- **Scrollable Content**: Smooth scrolling through all entry content
- **Interactive Elements**: Tappable categories/tags, shareable content
- **Edit Mode**: In-place editing of categories and tags

#### 3. Category Management (New)
- **Category List**: All categories with statistics and customization
- **Category Creation**: Name, color picker, icon selector
- **Category Editing**: Rename, recolor, change icon
- **Bulk Operations**: Assign category to multiple entries

#### 4. Advanced Search Interface (New)
- **Search Filters Panel**: Expandable filter options
- **Date Range Picker**: Custom date range selection
- **Tag Selector**: Multi-select tag filtering
- **Search Results**: Enhanced results with filter highlights

## User Experience Design

### Information Architecture
```
Main View (Enhanced)
├── Category Filter Bar
├── Advanced Search Button
├── Entry List (with categories/tags)
└── Floating Action Button (Record)

Entry Details View (New)
├── Header (title, category, timestamp)
├── Audio Player Section
├── AI Summary Card
├── Full Transcript Section
├── Tags Section
└── Action Toolbar

Category Management (New)
├── Category List
├── Create New Category
├── Edit Existing Categories
└── Category Statistics

Advanced Search (New)
├── Search Text Field
├── Category Filters
├── Date Range Picker
├── Tag Filters
├── Duration Filters
└── Smart Filter Presets
```

### User Workflows

#### Category Assignment Workflow:
1. **Entry Creation** → Optional category selection during recording
2. **Post-Creation** → Edit category via entry details or long-press menu
3. **Bulk Assignment** → Select multiple entries, assign category

#### Tagging Workflow:
1. **Manual Tagging** → Add tags in entry details view
2. **AI-Suggested Tags** → AI analyzes content and suggests relevant tags
3. **Auto-complete** → Start typing, see existing tag suggestions

#### Advanced Search Workflow:
1. **Quick Filters** → Tap category chips or preset filters
2. **Advanced Search** → Open full search interface with all criteria
3. **Saved Searches** → Save complex searches for repeated use

## Implementation Plan

### Phase 1: Core Data & Backend (T38-T41)
- Update Core Data model with Category and Tag entities
- Implement CategoryManager and TagManager
- Create advanced search functionality
- Add data migration for existing entries

### Phase 2: Category System (T42-T44)
- Create category management UI
- Implement category assignment and editing
- Add category filtering to main view
- Design category statistics and insights

### Phase 3: Entry Details Enhancement (T45-T47)
- Build full-screen entry details view
- Implement enhanced audio player with timeline
- Add transcript and summary display
- Create entry editing capabilities

### Phase 4: Tagging System (T48-T50)
- Implement tag input and auto-complete
- Create tag management interface
- Add tag-based filtering and search
- Design tag statistics and insights

### Phase 5: Advanced Search (T51-T53)
- Build advanced search interface
- Implement multi-criteria search
- Add saved searches functionality
- Create smart filter presets

## Technical Challenges & Solutions

### Challenge 1: Core Data Migration
**Problem**: Adding new entities and relationships to existing data
**Solution**: Implement progressive Core Data migration with data preservation

### Challenge 2: Search Performance
**Problem**: Complex search queries may be slow on large datasets
**Solution**: Implement search indexing and query optimization

### Challenge 3: UI Responsiveness
**Problem**: Rich UI with categories, tags, and filters may impact performance
**Solution**: Lazy loading, view recycling, and background processing

### Challenge 4: Data Consistency
**Problem**: Maintaining consistency between categories, tags, and entries
**Solution**: Proper Core Data relationships and cascade delete rules

## Success Metrics

### Functional Success
- ✅ Categories can be created, assigned, and managed
- ✅ Tags can be added, removed, and used for filtering
- ✅ Entry details view displays all content properly
- ✅ Advanced search returns accurate, relevant results
- ✅ All existing functionality remains intact

### Performance Success
- ✅ Search results return in under 500ms for typical queries
- ✅ Category/tag filtering is instantaneous
- ✅ Entry details view loads smoothly
- ✅ App remains responsive during data operations

### User Experience Success
- ✅ Intuitive category and tag management
- ✅ Discoverable advanced search features
- ✅ Enhanced content organization capabilities
- ✅ Seamless integration with existing workflows

## Future Extensibility

### Advanced Features (v0.4.0+)
- **Smart Categories**: AI-powered automatic categorization
- **Tag Hierarchies**: Nested tag structures
- **Cross-Entry Insights**: Pattern recognition across categories/tags
- **Export/Import**: Category and tag data portability

### Analytics & Insights
- **Usage Patterns**: Most used categories and tags
- **Content Analysis**: Topic clustering and trend analysis
- **Productivity Metrics**: Category-based time tracking
- **Recommendation Engine**: Suggest categories/tags for new entries

This comprehensive enhancement transforms Voxx from a simple voice recorder into a sophisticated personal knowledge management system while maintaining the intuitive experience users love.