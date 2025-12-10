# Priority Task Manager - Video Presentation Script
**Duration:** ~3 minutes
**Device:** iPhone 17 Simulator
**Date:** December 3, 2024

---

## INTRODUCTION (20 seconds)

"Hello! I'm [Your Name], presenting my Priority Task Manager iOS app on **iPhone 17 Simulator** using Xcode 26.1.1, iOS 17.0. This app combines Brian Tracy's ABCDE Method and Stephen Covey's Time Management Matrix for task prioritization."

---

## PART 1: TESTING PRESENTATION (1 minute)

"Let me demonstrate the functionality. We have three tabs: ABCDE, Matrix, and All Tasks.

**[Tap ABCDE tab]** Sample tasks are loaded showing priority levels A through E. **[Tap a task]** Here's the detail view with all task information. **[Tap Edit, delete title, tap Done]** Input validation works - we get an error when the title is empty. **[Cancel]**

**[Tap Matrix tab]** The Covey Matrix shows four quadrants based on urgency and importance. Tasks are automatically organized.

**[Tap All Tasks]** This view filters tasks by All, Active, or Completed. **[Swipe to delete]** Swipe-to-delete works with confirmation. **[Tap +]** Let's add a task. **[Fill form and save]** Form validation and data persistence confirmed."

---

## PART 2: LOGIC CODE PRESENTATION (1 minute)

**[Show Task.swift]** "The Task struct conforms to Identifiable and Codable. It has a Priority enum with five cases A through E, and a CoveyQuadrant enum. This computed property automatically assigns quadrants based on urgency and importance using a switch statement.

**[Show TaskManager.swift]** The TaskManager class is an ObservableObject with a Published tasks array. It handles CRUD operations using guard statements for safe unwrapping, filter and sort for organization, and UserDefaults with JSON encoding for persistence. Notice the guard statement in updateTask - this prevents crashes from invalid data."

---

## PART 3: GUI CODE PRESENTATION (50 seconds)

**[Show ContentView.swift]** "The interface uses pure SwiftUI. ContentView has a TabView with @EnvironmentObject for state sharing.

**[Show ABCDEListView.swift]** This demonstrates NavigationView, @State for sheet presentation, and ForEach loops with conditional rendering.

**[Show AddTaskView.swift]** The form uses TextField, Picker, Toggle, and DatePicker. Input validation is in the saveTask function with guard statements and alert presentation.

**[Show components]** I created three reusable components - TaskRowView, PriorityBadgeView, and QuadrantBadgeView - following the DRY principle."

---

## CONCLUSION (20 seconds)

"This app demonstrates complete CRUD functionality with validation, clean Swift code using structs, enums, classes and guard statements, and modern SwiftUI with TabView, Forms, and custom components - all using course techniques. Thank you!"

---

## FILMING TIPS

1. **Show iPhone Model:** At the start, clearly state "iPhone 17 Simulator" and/or show it in the Xcode window title bar
2. **Screen Recording:** Use QuickTime or Xcode's built-in screen recorder
3. **Code Visibility:** When showing code, zoom in so text is readable (Cmd + to zoom in Xcode)
4. **Smooth Transitions:** Practice transitions between simulator and Xcode
5. **Clear Audio:** Use a good microphone and quiet environment
6. **Pacing:** Speak clearly and not too fast - aim for ~60 words per minute

## CHECKLIST BEFORE RECORDING

- [ ] Xcode open with project
- [ ] Simulator running with app installed
- [ ] Sample tasks loaded
- [ ] Screen recording software ready
- [ ] Good lighting and quiet space
- [ ] Script reviewed and practiced
- [ ] Timer ready to keep under 4 minutes
