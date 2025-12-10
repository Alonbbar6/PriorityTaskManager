//
//  QuadrantBadgeView.swift
//  PriorityTaskManager
//
//  Created by Alonso Bardales
//  Date: December 3, 2024
//
//  Reusable component for displaying Covey quadrant badge
//

import SwiftUI

struct QuadrantBadgeView: View {
    let quadrant: CoveyQuadrant
    
    var body: some View {
        Text(quadrant.shortName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(quadrantColor)
            .cornerRadius(4)
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

struct QuadrantBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            QuadrantBadgeView(quadrant: .one)
            QuadrantBadgeView(quadrant: .two)
            QuadrantBadgeView(quadrant: .three)
            QuadrantBadgeView(quadrant: .four)
        }
        .padding()
    }
}
