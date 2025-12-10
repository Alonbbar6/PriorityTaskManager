//
//  CoveyMatrixView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  View displaying tasks in Covey's four-quadrant time management matrix
//

import SwiftUI

struct CoveyMatrixView: View {
    @EnvironmentObject var taskManager: TaskManager
    @State private var showingAddTask = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Information section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Covey Time Management Matrix")
                        .font(.headline)
                    Text("Tasks organized by urgency and importance. Focus on Q2 for long-term success.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                
                // Matrix grid
                GeometryReader { geometry in
                    VStack(spacing: 1) {
                        // Top row: Q1 and Q2
                        HStack(spacing: 1) {
                            QuadrantView(
                                quadrant: .one,
                                tasks: taskManager.tasksByQuadrant(.one),
                                width: geometry.size.width / 2,
                                height: geometry.size.height / 2
                            )
                            
                            QuadrantView(
                                quadrant: .two,
                                tasks: taskManager.tasksByQuadrant(.two),
                                width: geometry.size.width / 2,
                                height: geometry.size.height / 2
                            )
                        }
                        
                        // Bottom row: Q3 and Q4
                        HStack(spacing: 1) {
                            QuadrantView(
                                quadrant: .three,
                                tasks: taskManager.tasksByQuadrant(.three),
                                width: geometry.size.width / 2,
                                height: geometry.size.height / 2
                            )
                            
                            QuadrantView(
                                quadrant: .four,
                                tasks: taskManager.tasksByQuadrant(.four),
                                width: geometry.size.width / 2,
                                height: geometry.size.height / 2
                            )
                        }
                    }
                }
            }
            .navigationTitle("Covey Matrix")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }
}

// Individual quadrant view
struct QuadrantView: View {
    let quadrant: CoveyQuadrant
    let tasks: [Task]
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Quadrant header
            VStack(alignment: .leading, spacing: 4) {
                Text(quadrant.shortName)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(quadrant.rawValue.replacingOccurrences(of: "\(quadrant.shortName): ", with: ""))
                    .font(.caption)
                    .foregroundColor(.white)
                Text("\(tasks.count) tasks")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(quadrantColor)
            
            // Task list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(tasks.prefix(10)) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text(task.displayPriority)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            .padding(6)
                            .background(Color(.systemBackground))
                            .cornerRadius(4)
                        }
                    }
                    
                    if tasks.count > 10 {
                        Text("+\(tasks.count - 10) more")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    
                    if tasks.isEmpty {
                        Text("No tasks in this quadrant")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                            .padding()
                    }
                }
                .padding(8)
            }
        }
        .frame(width: width, height: height)
        .background(quadrantColor.opacity(0.2))
    }
    
    private var quadrantColor: Color {
        switch quadrant {
        case .one:
            return .red
        case .two:
            return .green
        case .three:
            return .orange
        case .four:
            return .gray
        }
    }
}

struct CoveyMatrixView_Previews: PreviewProvider {
    static var previews: some View {
        CoveyMatrixView()
            .environmentObject(TaskManager())
    }
}
