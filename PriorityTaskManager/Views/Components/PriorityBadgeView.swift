//
//  PriorityBadgeView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  Reusable component for displaying priority badge
//

import SwiftUI

struct PriorityBadgeView: View {
    let priority: Priority
    let displayText: String
    
    var body: some View {
        Text(displayText)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .cornerRadius(4)
    }
    
    private var priorityColor: Color {
        switch priority {
        case .a:
            return .red
        case .b:
            return .orange
        case .c:
            return .yellow
        case .d:
            return .blue
        case .e:
            return .gray
        }
    }
}

struct PriorityBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            PriorityBadgeView(priority: .a, displayText: "A-1")
            PriorityBadgeView(priority: .b, displayText: "B")
            PriorityBadgeView(priority: .c, displayText: "C")
        }
        .padding()
    }
}
