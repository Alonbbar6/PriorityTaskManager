# Priority Task Manager - Submission Checklist

## Before You Submit

Please complete the following tasks before submitting your project:

### 1. Personalization (REQUIRED)
- [ ] Open all `.swift` files in the project
- [ ] Replace `[Your Name]` with your actual name in the file headers
- [ ] Verify the date is correct (December 3, 2024)
- [ ] Save all files after making changes

**Files to update:**
- PriorityTaskManagerApp.swift
- Task.swift
- TaskManager.swift
- ContentView.swift
- ABCDEListView.swift
- CoveyMatrixView.swift
- AllTasksView.swift
- AddTaskView.swift
- TaskDetailView.swift
- TaskRowView.swift
- PriorityBadgeView.swift
- QuadrantBadgeView.swift

### 2. Test the Application (REQUIRED)
- [ ] Open the project in Xcode
- [ ] Build the project (Cmd+B) and verify no errors
- [ ] Run the app on a simulator
- [ ] Test creating a new task
- [ ] Test editing an existing task
- [ ] Test deleting a task
- [ ] Test marking tasks as complete/incomplete
- [ ] Test all three tabs (ABCDE, Matrix, All Tasks)
- [ ] Test filtering in All Tasks view
- [ ] Verify input validation works (try saving empty title)
- [ ] Note the iPhone model you tested on

### 3. Create Video Recording (REQUIRED - 15 points)
Create a video that includes:

**Testing Presentation (5 points):**
- [ ] Show the app running on simulator
- [ ] Demonstrate creating a new task
- [ ] Demonstrate editing a task
- [ ] Demonstrate deleting a task
- [ ] Show all three main views (ABCDE, Matrix, All Tasks)
- [ ] Show filtering and task completion features
- [ ] Mention the iPhone model being used

**Logic Code Presentation (5 points):**
- [ ] Show Task.swift model with enums
- [ ] Show TaskManager.swift with CRUD operations
- [ ] Explain how ABCDE priority works
- [ ] Explain how Covey quadrant calculation works
- [ ] Show data persistence implementation

**GUI Code Presentation (5 points):**
- [ ] Show ContentView.swift with TabView
- [ ] Show one of the main views (ABCDEListView or CoveyMatrixView)
- [ ] Show reusable components (TaskRowView, badges)
- [ ] Explain navigation structure
- [ ] Show form validation in AddTaskView

### 4. Verify Code Quality (REQUIRED)
- [ ] All files have your name and date at the top (1 point)
- [ ] All code has proper comments explaining functionality (2 points)
- [ ] All code is properly indented and formatted (1 point)
- [ ] No unnecessary commented-out code (3 points)
- [ ] No excessive blank spaces (max 1 line between sections)
- [ ] No debug print statements left in code

### 5. Verify Requirements Met
- [ ] Uses SwiftUI (not Storyboard)
- [ ] Has Structures for data models (Task struct)
- [ ] Has Subviews for reusable components (TaskRowView, badges)
- [ ] Has Navigation structure (NavigationView, NavigationLink)
- [ ] Has Tab structure (TabView)
- [ ] Passes data between views (task objects)
- [ ] Validates all input (title required, date validation)
- [ ] Uses only techniques from class materials

### 6. Prepare Submission Package
- [ ] Create a fresh zip of the project
- [ ] Test the zip by extracting it and opening in Xcode
- [ ] Verify all files are included
- [ ] Include your video recording
- [ ] Include this README.md file

### 7. Final Submission
Upload to your course platform:
- [ ] PriorityTaskManager.zip (Xcode project)
- [ ] Video recording (with voice narration)
- [ ] README.md (this file serves as documentation)

## Grading Rubric Reference

**Total: 100 points**

- **Video Recording (15 points)**
  - 5 points: Testing presentation
  - 5 points: Logic code presentation
  - 5 points: GUI code presentation

- **Structs Types Implementation (25 points)**
  - Task struct with properties
  - Priority and CoveyQuadrant enums
  - TaskManager class
  - Proper use of Identifiable and Codable

- **UI Implementation (35 points)**
  - TabView navigation
  - Three main views (ABCDE, Matrix, All Tasks)
  - Add/Edit/Delete functionality
  - Reusable subview components
  - Proper layout and design

- **Compiles and Executes (25 points)**
  - Project builds without errors
  - App runs on simulator/device
  - All features work as expected
  - No crashes or major bugs

**Deductions:**
- -15 points: Missing video or iPhone model not specified
- -10 points: Missing or improper input validation
- -5 points: Missing name, date, comments, or improper formatting
- -3 points: Unnecessary commented code or blank spaces
- -10 to -20 points: Late submission (first or second day)
- 0 points: Missing source code or doesn't compile

## Swift Techniques Used (From Student Materials)

✅ **Unit 1 & 2 - Swift Fundamentals:**
- Strings (text manipulation)
- Functions (CRUD operations)
- Structures (Task model)
- Classes (TaskManager)
- Collections (Arrays, Dictionaries)
- Loops (ForEach, filtering)

✅ **Unit 3 - Navigation and Workflows:**
- Optionals (optional properties)
- Guard statements (validation)
- Type Casting (Int parsing)
- Scope (proper variable scoping)
- Enumerations (Priority, CoveyQuadrant)

✅ **SwiftUI (Assumed from class lectures):**
- NavigationView and NavigationLink
- TabView
- List and Form
- @State and @EnvironmentObject
- Custom reusable views

## Tips for Success

1. **Test thoroughly** - Make sure every feature works before recording
2. **Practice your video** - Do a dry run before recording the final version
3. **Speak clearly** - Explain what you're showing and why
4. **Show your face or voice** - The rubric requires voice narration
5. **Time management** - Don't wait until the last minute
6. **Ask questions** - If unsure about requirements, ask your instructor

## Contact

If you have questions about the project or submission:
- Check the assignment rubric on your course platform
- Review the README.md for technical details
- Review PRODUCTIVITY_METHODS.md for background on ABCDE and Covey methods
- Contact your instructor during office hours

---

**Good luck with your submission!**

Remember: The goal is to demonstrate your understanding of Swift fundamentals, SwiftUI, and proper app architecture while creating a useful productivity tool.
