import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - shadcn/ui Inspired Button
public enum ShadcnButtonVariant {
    case tartan
    case primary
    case secondary
    case outline
    case ghost
    case destructive
}

public enum ShadcnButtonSize {
    case sm
    case `default`
    case lg
    case icon
}

public struct ShadcnButton: View {
    private let title: String
    private let icon: String?
    private let variant: ShadcnButtonVariant
    private let size: ShadcnButtonSize
    private let isLoading: Bool
    private let action: () -> Void
    
    public init(
        _ title: String = "",
        icon: String? = nil,
        variant: ShadcnButtonVariant = .tartan,
        size: ShadcnButtonSize = .default,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            #if canImport(UIKit)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            #endif
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(iconFont)
                }
                
                if !title.isEmpty {
                    Text(title)
                        .font(textFont)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: size == .icon ? height : .infinity)
            .frame(height: height)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: variant == .outline ? 1 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
    
    private var height: CGFloat {
        switch size {
        case .sm: return 36
        case .default: return 46
        case .lg: return 54
        case .icon: return 42
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .sm: return 8
        case .default: return 10
        case .lg: return 12
        case .icon: return 8
        }
    }
    
    private var textFont: Font {
        switch size {
        case .sm: return .subheadline
        case .default: return .body
        case .lg: return .headline
        case .icon: return .body
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .sm: return .caption
        case .default: return .subheadline
        case .lg: return .body
        case .icon: return .headline
        }
    }
    
    private var backgroundView: some View {
        Group {
            switch variant {
            case .tartan:
                Color.tartanRed
            case .primary:
                Color.appForeground
            case .secondary:
                Color.appMuted
            case .outline:
                Color.clear
            case .ghost:
                Color.clear
            case .destructive:
                Color.red
            }
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .tartan, .primary, .destructive:
            return .white
        case .secondary, .outline:
            return .appForeground
        case .ghost:
            return .appForeground
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .outline:
            return Color.appCardBorder
        default:
            return Color.clear
        }
    }
}

// MARK: - shadcn/ui Inspired Badge
public enum ShadcnBadgeVariant {
    case `default`
    case secondary
    case outline
    case success
    case tartan
    case warning
}

public struct ShadcnBadge: View {
    private let text: String
    private let icon: String?
    private let variant: ShadcnBadgeVariant
    
    public init(_ text: String, icon: String? = nil, variant: ShadcnBadgeVariant = .default) {
        self.text = text
        self.icon = icon
        self.variant = variant
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(background)
        .foregroundColor(foreground)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: variant == .outline ? 1 : 0)
        )
    }
    
    private var background: Color {
        switch variant {
        case .default: return Color.appForeground
        case .secondary: return Color.appMuted
        case .outline: return Color.clear
        case .success: return Color.appSuccess.opacity(0.15)
        case .tartan: return Color.tartanRed.opacity(0.12)
        case .warning: return Color.appWarning.opacity(0.15)
        }
    }
    
    private var foreground: Color {
        switch variant {
        case .default: return Color.appBackground
        case .secondary: return Color.appForeground
        case .outline: return Color.appForeground
        case .success: return Color.appSuccess
        case .tartan: return Color.tartanRed
        case .warning: return Color.appWarning
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .outline: return Color.appCardBorder
        default: return Color.clear
        }
    }
}

// MARK: - shadcn/ui Card Container
public struct ShadcnCard<Content: View>: View {
    private let content: Content
    private let padding: CGFloat
    
    public init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(padding)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - shadcn/ui Input Field
public struct ShadcnInput: View {
    private let placeholder: String
    @Binding private var text: String
    private let icon: String?
    
    public init(_ placeholder: String, text: Binding<String>, icon: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
    }
    
    public var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Color.appMutedForeground)
                    .font(.system(size: 15))
            }
            
            TextField(placeholder, text: $text)
                .font(.subheadline)
                .foregroundColor(Color.appForeground)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.appMutedForeground)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appCardBorder, lineWidth: 1)
        )
    }
}

// MARK: - shadcn/ui Hairline Separator
public struct ShadcnSeparator: View {
    public init() {}
    
    public var body: some View {
        Rectangle()
            .fill(Color.appCardBorder)
            .frame(height: 1)
    }
}

// MARK: - Delivery Status Stepper
public struct DeliveryStatusStepper: View {
    let currentStatus: OrderStatus
    
    private let steps: [(OrderStatus, String, String)] = [
        (.placed, "Placed", "checkmark"),
        (.preparing, "Kitchen", "flame.fill"),
        (.pickedUp, "Picked Up", "box.truck.badge.clock.fill"),
        (.onTheWay, "On The Way", "location.north.circle.fill"),
        (.arrived, "At Hub", "lock.open.fill")
    ]
    
    public init(currentStatus: OrderStatus) {
        self.currentStatus = currentStatus
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                ForEach(0..<steps.count, id: \.self) { index in
                    let step = steps[index]
                    let isCompleted = currentStatus.stepIndex >= step.0.stepIndex
                    let isCurrent = currentStatus.stepIndex == step.0.stepIndex
                    
                    // Circle indicator
                    ZStack {
                        Circle()
                            .fill(isCompleted ? Color.tartanRed : Color.appMuted)
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: step.2)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isCompleted ? .white : Color.appMutedForeground)
                    }
                    .scaleEffect(isCurrent ? 1.15 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isCurrent)
                    
                    // Connecting line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(currentStatus.stepIndex > step.0.stepIndex ? Color.tartanRed : Color.appCardBorder)
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    let step = steps[index]
                    let isCurrent = currentStatus.stepIndex == step.0.stepIndex
                    
                    Text(step.1)
                        .font(.system(size: 10, weight: isCurrent ? .bold : .medium))
                        .foregroundColor(isCurrent ? Color.tartanRed : Color.appMutedForeground)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

