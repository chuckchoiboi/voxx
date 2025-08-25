# Feature Backlog

This document lists features and enhancements derived from the plan. It is a living document that will evolve throughout the project. It is grouped by release, with the Backlog tracking all features not added to a release yet.  It is used to create releases to work on.


| Status |  | Priority |  |
|--------|-------------|---------|-------------|
| 🔴 | Not Started | High | High priority items |
| 🟡 | In Progress | Medium | Medium priority items |
| 🟢 | Completed | Low | Low priority items |


## Backlog

| ID  | Feature             | Description                               | Priority | Status |
|-----|---------------------|-------------------------------------------|----------|--------|
| B01 | Advanced Analytics   | Detailed mood tracking and advanced insights | Low | 🔴 Not Started |
| B02 | Cloud Sync          | Cloud storage and multi-device sync      | Medium | 🔴 Not Started |
| B03 | Export Features     | Export audio, transcripts, summaries     | Low | 🔴 Not Started |
| B04 | Privacy & Security  | Advanced encryption and privacy features | Medium | 🔴 Not Started |

## v0.1.0-mvp-foundation - 🟢 Completed
Core voice recording and playback functionality with local storage. **Released: August 2025**

| ID  | Feature                 | Description                              | Priority | Status |
|-----|-------------------------|------------------------------------------|----------|--------|
| F01 | iOS Project Setup       | Create Xcode project with Core Data     | High | 🟢 Completed |
| F02 | Audio Recording         | Voice recording with unlimited length    | High | 🟢 Completed |
| F03 | Audio Playback          | Play recorded audio entries              | High | 🟢 Completed |
| F04 | Local Storage           | Core Data setup for journal entries     | High | 🟢 Completed |
| F05 | Basic UI                | Simple recording interface               | High | 🟢 Completed |

**Bonus Features Delivered:**
- Advanced Error Handling & Recovery
- Comprehensive Testing Framework  
- Professional iOS UI with Search
- Storage Management & System Health
- Entry Management (List, Delete, Share)
- iPhone Deployment & Permissions

## v0.2.0-ai-integration - 🟢 Completed
Integrate OpenAI for transcription and summarization capabilities. **Released: August 2025**

| ID  | Feature                 | Description                              | Priority | Status |
|-----|-------------------------|------------------------------------------|----------|--------|
| F06 | OpenAI API Client       | Setup API integration for transcription | High | 🟢 Completed |
| F07 | Speech-to-Text          | Transcribe audio recordings              | High | 🟢 Completed |
| F08 | AI Summarization        | Generate summaries from transcripts      | High | 🟢 Completed |
| F09 | Error Handling          | Handle API failures gracefully          | Medium | 🟢 Completed |

**Bonus Features Delivered:**
- Automatic AI processing after recordings
- Manual AI processing via long-press menus
- Smart UI with summary/transcript prioritization
- Comprehensive API key setup guidance
- Background processing with loading states

## v0.3.0-core-features - 🟡 In Progress  
Advanced categorization, tagging system, and enhanced entry management. **Currently Implementing: August 2025**

| ID  | Feature                 | Description                              | Priority | Status |
|-----|-------------------------|------------------------------------------|----------|--------|
| F10 | Entry List View         | Display chronological list of entries   | High | 🟢 Completed (delivered in v0.1.0) |
| F11 | Search Functionality    | Full-text search across content          | High | 🟢 Completed (delivered in v0.1.0) |
| F12 | Category System         | Complete category system with predefined + custom | High | 🟢 Completed |
| F13 | Entry Details View      | Full-screen entry view with audio player | High | 🟢 Completed |
| F14 | Delete Entries          | Remove unwanted journal entries          | Medium | 🟢 Completed (delivered in v0.1.0) |
| F15 | Tag System              | Flexible tagging with AI suggestions    | High | 🟢 Completed |
| F16 | Category Filter UI      | Horizontal category filter bar           | Medium | 🟢 Completed |
| F17 | Enhanced Entry Cells    | Rich cells with category badges and tags | Medium | 🟢 Completed |
| F18 | Advanced Search         | Multi-criteria filtering system          | Medium | 🟡 In Progress |

**Major Features Delivered:**
- **CategoryManager**: Complete CRUD operations for predefined categories (Work, Personal, Ideas, Meetings, Reflections)
- **TagManager**: Advanced tag system with usage tracking, AI-powered suggestions, auto-complete
- **EntryDetailsViewController**: Full-screen modal with integrated audio player, transcript, and tag editing
- **Enhanced Main UI**: Category filter bar, rich table cells with visual category badges and tag pills
- **Core Data Integration**: Proper entity relationships and optimized queries for categories and tags
- **Color System**: Hex color support with visual category and tag identification

## v0.4.0-enhanced-ux - 🔴 Not Started
Polish user experience with analytics and workflow enhancements.

| ID  | Feature                 | Description                              | Priority | Status |
|-----|-------------------------|------------------------------------------|----------|--------|
| F19 | Recording Workflow      | Category selection during recording      | Medium | 🔴 Not Started |
| F20 | Tag Input UI            | Auto-complete tag input interface        | Medium | 🔴 Not Started |  
| F21 | Analytics Dashboard     | Journaling streaks and usage statistics  | Medium | 🔴 Not Started |
| F22 | Smart Presets           | Saved search filters and smart presets   | Low | 🔴 Not Started |
| F23 | Settings Screen         | App preferences and configuration        | Low | 🔴 Not Started |
| F24 | Export Features         | Export entries in various formats        | Low | 🔴 Not Started |

**Note**: Custom Categories and Category Management were delivered ahead of schedule in v0.3.0
