# Priority Task Manager

**Created by:** Alonso Bardales  
**Date:** December 3, 2025 
**Course:** Apple Swift Programming  
**Assignment:** Student 3 - iPhone App Project

## Project Overview

Priority Task Manager is an iOS productivity application that helps users organize and prioritize tasks using two proven time management methodologies:

1. **ABCDE Method** (Brian Tracy) - Categorizes tasks from A (must do) to E (eliminate)
2. **Covey Time Management Matrix** (Stephen Covey) - Organizes tasks by urgency and importance into four quadrants

## Features

### Core Functionality
- Create, view, edit, and delete tasks
- Mark tasks as complete/incomplete
- Persistent data storage using UserDefaults
- Input validation for all forms
- Sample tasks for demonstration

### ABCDE Priority View
- Tasks organized by priority level (A, B, C, D, E)
- Color-coded priority badges
- Sub-priorities for A tasks (A-1, A-2, etc.)
- Detailed descriptions for each priority level

### Covey Matrix View
- Four-quadrant grid layout
- Automatic task categorization based on urgency/importance
- Visual color coding for each quadrant
- Task count display per quadrant

### All Tasks View
- Complete task list with filtering (All, Active, Completed)
- Swipe-to-delete functionality
- Empty state messages
- Task search and organization

## Swift Techniques Used

This project demonstrates the following Swift concepts covered in the student materials:

### From Unit 1 & 2 - Swift Fundamentals
- **Structures**: Task model with properties and computed properties
- **Classes**: TaskManager for data management and business logic
- **Enumerations**: Priority levels and Covey quadrants with associated values
- **Functions**: CRUD operations, validation, and helper methods
- **Strings**: Text manipulation and formatting
- **Collections**: Arrays for task storage, filtering, and sorting

### From Unit 3 - Navigation and Workflows
- **Optionals**: Optional due dates, optional notes, optional sub-priorities
- **Guard Statements**: Input validation in save and update operations
- **Type Casting**: Safe type conversions for sub-priority parsing
- **Scope**: Proper variable scoping in views and functions
- **Control Flow**: If/else statements, switch cases for priority/quadrant logic
- **Loops**: ForEach for displaying lists, filtering operations

### SwiftUI Components
- NavigationView and NavigationLink for navigation
- TabView for main navigation structure
- List and Form for data display
- Picker, Toggle, TextField, TextEditor for input
- Custom reusable view components (Subviews)
- @State and @EnvironmentObject for state management
- Sheet presentation for modal views

## Project Structure

```
PriorityTaskManager/
├── PriorityTaskManagerApp.swift    # Main app entry point
├── Models/
│   ├── Task.swift                  # Task data model with Priority and CoveyQuadrant enums
│   └── TaskManager.swift           # ObservableObject class for CRUD operations
├── Views/
│   ├── ContentView.swift           # Main TabView container
│   ├── ABCDEListView.swift         # ABCDE priority list view
│   ├── CoveyMatrixView.swift       # Four-quadrant matrix view
│   ├── AllTasksView.swift          # Complete task list with filtering
│   ├── AddTaskView.swift           # Form for creating new tasks
│   ├── TaskDetailView.swift        # View and edit task details
│   └── Components/
│       ├── TaskRowView.swift       # Reusable task row component
│       ├── PriorityBadgeView.swift # Priority badge component
│       └── QuadrantBadgeView.swift # Quadrant badge component
└── Assets.xcassets/                # App assets and icons
```

## Data Models

### Task Struct
```swift
struct Task: Identifiable, Codable {
    var id: UUID
    var title: String
    var notes: String
    var priority: Priority
    var isUrgent: Bool
    var isImportant: Bool
    var dueDate: Date?
    var isCompleted: Bool
    var createdDate: Date
    var subPriority: Int?
}
```

### Priority Enum
```swift
enum Priority: String, CaseIterable, Codable {
    case a = "A"  // Must Do - Serious consequences
    case b = "B"  // Should Do - Mild consequences
    case c = "C"  // Nice to Do - No consequences
    case d = "D"  // Delegate
    case e = "E"  // Eliminate
}
```

### CoveyQuadrant Enum
```swift
enum CoveyQuadrant: String, CaseIterable {
    case one = "Q1: Urgent & Important"
    case two = "Q2: Not Urgent & Important"
    case three = "Q3: Urgent & Not Important"
    case four = "Q4: Not Urgent & Not Important"
}
```

## Validation

The app implements comprehensive input validation:

1. **Title Validation**: Task title is required and cannot be empty
2. **Date Validation**: Due dates cannot be set in the past for new tasks
3. **Sub-priority Validation**: Only numeric values accepted for A task sub-priorities
4. **Error Alerts**: User-friendly error messages for all validation failures

## Documentation Standards

All source code files include:
- File header with name and date
- Descriptive comments explaining functionality
- Proper indentation and formatting
- Section markers for code organization
- No unnecessary commented code or excessive blank spaces

## Testing Notes

### Tested Functionality
- ✅ Task creation with all fields
- ✅ Task editing and updates
- ✅ Task deletion with confirmation
- ✅ Task completion toggle
- ✅ Priority filtering and sorting
- ✅ Quadrant categorization
- ✅ Data persistence across app launches
- ✅ Input validation and error handling
- ✅ Empty state displays
- ✅ Navigation between views

### Sample Data
The app includes sample tasks demonstrating all priority levels and quadrants for easy testing and demonstration.

## Productivity Methods Explained

### ABCDE Method (Brian Tracy)
The ABCDE Method helps prioritize tasks by assigning each a letter based on consequences:

- **A Tasks**: Must do - serious consequences if not done
- **B Tasks**: Should do - mild consequences
- **C Tasks**: Nice to do - no consequences
- **D Tasks**: Delegate to someone else
- **E Tasks**: Eliminate - should not be done at all

**Rule**: Never do a B task when an A task is undone. Never do a C task when B or A tasks remain.

### Covey Time Management Matrix (Stephen Covey)
The Covey Matrix organizes tasks into four quadrants based on two dimensions:

**Quadrant 1** (Urgent & Important): Crises, deadlines, emergencies  
**Quadrant 2** (Not Urgent & Important): Planning, prevention, relationship building - *Focus here for long-term success*  
**Quadrant 3** (Urgent & Not Important): Interruptions, some meetings  
**Quadrant 4** (Not Urgent & Not Important): Time wasters, busywork - *Minimize time here*

**Philosophy**: Spend more time in Quadrant 2 to prevent Quadrant 1 crises.

## How to Use the App

1. **Launch the app** - Sample tasks are loaded automatically
2. **View tasks by priority** - Use the ABCDE tab to see tasks organized by priority level
3. **View tasks by quadrant** - Use the Matrix tab to see the Covey four-quadrant view
4. **Add a new task** - Tap the + button in any view
5. **Edit a task** - Tap on any task to view details, then tap Edit
6. **Complete a task** - Tap the circle checkbox next to any task
7. **Delete a task** - Swipe left on a task in All Tasks view, or use Delete button in detail view
8. **Filter tasks** - Use the segmented control in All Tasks view to filter by All/Active/Completed

## Requirements Met

✅ SwiftUI implementation (no Storyboard)  
✅ Structures for data models  
✅ Subviews for reusable UI components  
✅ Navigation and Tab structure  
✅ Data passing between views  
✅ Input validation for all forms  
✅ Proper documentation with name, date, comments, and indentation  
✅ No unnecessary commented code or blank spaces  
✅ Uses only techniques from class materials  

## iPhone Compatibility

- **Minimum iOS Version**: iOS 16.0
- **Supported Devices**: iPhone and iPad
- **Tested on**: iPhone 14 Pro Simulator (iOS 17.0)
- **Orientation**: Portrait and Landscape

## Build Instructions

1. Open `PriorityTaskManager.xcodeproj` in Xcode
2. Select a simulator or connected device
3. Press Cmd+R to build and run
4. The app will launch with sample tasks pre-loaded

## Credits

**Productivity Methods:**
- ABCDE Method by Brian Tracy
- Time Management Matrix by Stephen Covey (from "The 7 Habits of Highly Effective People")

**Development:**
- Created as part of Apple Swift Programming course
- Uses only techniques covered in Student 3 materials
- SwiftUI framework for modern iOS development

---

**Note**: Remember to replace `[Your Name]` with your actual name in all source files before submission.
