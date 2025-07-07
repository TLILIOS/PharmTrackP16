import SwiftUI

enum MessageType {
    case success
    case error
    case warning
    case info
    
    var color: Color {
        switch self {
        case .success: return Color.successColor
        case .error: return Color.errorColor
        case .warning: return Color.warningColor
        case .info: return Color.infoColor
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct MessageView: View {
    let message: String
    let type: MessageType
    let dismissAction: (() -> Void)?
    
    init(message: String, type: MessageType = .info, dismissAction: (() -> Void)? = nil) {
        self.message = message
        self.type = type
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            
            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .font(.caption.bold())
                }
            }
        }
        .padding()
        .background(type.color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        MessageView(message: "Opération réussie !", type: .success)
        MessageView(message: "Une erreur est survenue.", type: .error)
        MessageView(message: "Attention, le stock est faible.", type: .warning)
        MessageView(message: "Information importante à noter.", type: .info) {
            print("Message dismissed")
        }
    }
    .padding()
}
