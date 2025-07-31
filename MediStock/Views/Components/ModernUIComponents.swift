import SwiftUI

// MARK: - Modern Empty State Component

struct ModernEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.right")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(25)
                }
            }
        }
        .padding()
    }
}

// MARK: - Loading State Component

struct LoadingStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.accentColor)
            
            Text(message)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Error State Component

struct ErrorStateView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Une erreur est survenue")
                    .font(.headline)
                
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
            
            Button(action: retry) {
                Label("Réessayer", systemImage: "arrow.clockwise")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let duration: Double = 0.3
    
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: duration)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    @State private var isAnimating = false
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray5),
                                Color(.systemGray4),
                                Color(.systemGray5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 300 : -300)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Custom Search Bar

struct ModernSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Rechercher..."
    var onSubmit: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var showClearButton = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.body)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onSubmit?()
                }
            
            if !text.isEmpty {
                Button(action: { 
                    text = ""
                    isFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.body)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        )
        .animation(.spring(response: 0.3), value: isFocused)
        .animation(.spring(response: 0.3), value: text.isEmpty)
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(isPressed ? 0.9 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            withAnimation(.spring(response: 0.3)) {
                isPressed = true
            }
        } onPressingChanged: { pressing in
            if !pressing {
                withAnimation(.spring(response: 0.3)) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let count: Int
    var color: Color = .red
    
    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(color)
                )
                .transition(.scale.combined(with: .opacity))
        }
    }
}

// MARK: - Gradient Card

struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    let colors: [Color]
    let content: () -> Content
    
    init(
        colors: [Color],
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.colors = colors
        self.gradient = LinearGradient(
            colors: colors,
            startPoint: startPoint,
            endPoint: endPoint
        )
        self.content = content
    }
    
    var body: some View {
        content()
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(gradient)
                    .shadow(color: colors.first?.opacity(0.3) ?? .clear, radius: 8, y: 4)
            )
    }
}

// MARK: - Animated Progress Ring

struct ProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat = 8
    let size: CGFloat = 60
    var color: Color = .accentColor
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: animatedProgress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = newValue
        }
    }
}

// MARK: - Haptic Feedback Helper

struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animated Tab Indicator

struct AnimatedTabIndicator: View {
    let tabCount: Int
    @Binding var selectedTab: Int
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabCount, id: \.self) { index in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 3)
                    .overlay(
                        Group {
                            if selectedTab == index {
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .matchedGeometryEffect(id: "indicator", in: namespace)
                            }
                        }
                    )
            }
        }
    }
}

// MARK: - Pull to Refresh

struct PullToRefreshModifier: ViewModifier {
    let action: () async -> Void
    @State private var isRefreshing = false
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                await action()
            }
    }
}

extension View {
    func pullToRefresh(action: @escaping () async -> Void) -> some View {
        modifier(PullToRefreshModifier(action: action))
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}