import SwiftUI

struct RecurrencePatternEditor: View {
    @Binding var pattern: RecurrencePattern

    private func timeStringToDate(_ timeString: String) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else {
            return today
        }
        
        var components = calendar.dateComponents([.year, .month, .day], from: today)
        components.hour = parts[0]
        components.minute = parts[1]
        
        let date = calendar.date(from: components) ?? today
        return date
    }
    
    private func dateToTimeString(_ date: Date) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let timeString = String(format: "%02d:%02d", hour, minute)
        return timeString
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { timeStringToDate(pattern.startTime) },
            set: { pattern.startTime = dateToTimeString($0) }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { timeStringToDate(pattern.endTime) },
            set: { pattern.endTime = dateToTimeString($0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Schedule label
            TextField("Schedule Name", text: Binding(
                get: { pattern.label ?? "" },
                set: { pattern.label = $0.isEmpty ? nil : $0 }
            ))
                .font(.subheadline)
                .fontWeight(.medium)
                .autocorrectionDisabled()

            // Days of week selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Days")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ForEach(DayOfWeek.ordered, id: \.self) { day in
                        let isSelected = pattern.daysOfWeek.contains(day)
                        Button {
                            if isSelected {
                                pattern.daysOfWeek.removeAll { $0 == day }
                            } else {
                                pattern.daysOfWeek.append(day)
                            }
                        } label: {
                            Text(day.singleLetter)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(width: 36, height: 36)
                                .background(isSelected ? Color.blue : Color(.systemGray5))
                                .foregroundColor(isSelected ? .white : .primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                // Quick select buttons
                HStack(spacing: 8) {
                    Button("Weekdays") {
                        pattern.daysOfWeek = DayOfWeek.weekdays
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)

                    Button("Weekend") {
                        pattern.daysOfWeek = DayOfWeek.weekend
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)

                    Button("Every Day") {
                        pattern.daysOfWeek = DayOfWeek.ordered
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
            }

            // Time range
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: startTimeBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("End Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: endTimeBinding, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                Spacer()
            }

            // Date range
            VStack(alignment: .leading, spacing: 8) {
                Text("Date Range")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: $pattern.startDate, displayedComponents: .date)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Until (Required)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        DatePicker("", selection: Binding(
                            get: {
                                pattern.endDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
                            },
                            set: { pattern.endDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                        .onChange(of: pattern.endDate) { newValue in
                            if newValue == nil {
                                pattern.endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())
                            }
                        }
                    }
                }

                Text("Schedule will run from \(formatDate(pattern.startDate)) until \(formatDate(pattern.endDate ?? Date()))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private func formatDisplayTime(_ time: String) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return time }
        let hour = parts[0]
        let minute = parts[1]
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
