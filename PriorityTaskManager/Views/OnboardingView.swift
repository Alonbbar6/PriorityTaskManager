import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "list.number",
            iconColor: .blue,
            title: "ABCDE Priority Method",
            subtitle: "Know What Matters Most",
            description: "Assign every task a priority from A (must do) to E (eliminate). Stop guessing what to work on — your highest-impact tasks always rise to the top."
        ),
        OnboardingPage(
            icon: "square.grid.2x2",
            iconColor: .purple,
            title: "Covey's Matrix",
            subtitle: "Urgent vs. Important",
            description: "Visualize your tasks on the Urgent/Important grid. Spend more time in Quadrant 2 — important but not urgent — where real progress happens."
        ),
        OnboardingPage(
            icon: "calendar",
            iconColor: .orange,
            title: "Schedule & Groups",
            subtitle: "Structure Your Day",
            description: "Organize tasks into groups with recurring schedules. See your day laid out on a timeline so nothing falls through the cracks."
        ),
        OnboardingPage(
            icon: "wind",
            iconColor: .teal,
            title: "Breathing Exercises",
            subtitle: "Stay Calm Under Pressure",
            description: "Built-in guided breathing helps you reset when stress builds up. Take a moment to recenter, then get back to what matters."
        ),
        OnboardingPage(
            icon: "gift.fill",
            iconColor: .green,
            title: "30 Days Free",
            subtitle: "Full Access, No Credit Card",
            description: "Everything in Priority Task Manager is yours free for 30 days. After your trial, unlock full access forever for just $4.99 — a one-time payment, no subscription."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Page indicators + button
            VStack(spacing: 24) {
                // Custom page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                    }
                }

                // Action button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        hasSeenOnboarding = true
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 32)

                // Skip button (hidden on last page)
                if currentPage < pages.count - 1 {
                    Button("Skip") {
                        hasSeenOnboarding = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else {
                    // Spacer to keep layout stable
                    Text(" ")
                        .font(.subheadline)
                }
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 70))
                .foregroundColor(page.iconColor)
                .padding(.bottom, 8)

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
}
