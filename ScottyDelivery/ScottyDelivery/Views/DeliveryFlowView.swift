import SwiftUI

private enum DeliveryPalette {
    static let navy = Color(red: 24 / 255, green: 44 / 255, blue: 75 / 255)
    static let red = Color(red: 148 / 255, green: 17 / 255, blue: 32 / 255)
    static let cream = Color(red: 250 / 255, green: 249 / 255, blue: 246 / 255)
    static let muted = Color(red: 105 / 255, green: 115 / 255, blue: 123 / 255)
    static let teal = Color(red: 31 / 255, green: 76 / 255, blue: 76 / 255)
    static let pale = Color(red: 241 / 255, green: 243 / 255, blue: 240 / 255)
    static let border = Color(red: 231 / 255, green: 232 / 255, blue: 230 / 255)
}

private enum DeliveryTab: Hashable {
    case home
    case tracking
    case history
    case account
}

private enum DeliveryRoute: Hashable {
    case orderNumber
    case pickup
    case destination
    case review
    case confirmation
    case tracking
    case delivered
    case receipt
}

private enum DeliveryStatus: String, Codable {
    case inTransit
    case delivered
}

private struct DeliveryRequestPayload {
    let orderNumber: String
    let pickupRestaurant: String
    let destination: String
}

private struct DeliveryRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var orderNumber: String
    var pickupRestaurant: String
    var destination: String
    var requestedAt: Date
    var deliveryFee: Double
    var status: DeliveryStatus
    var deliveredAt: Date?

    init(
        orderNumber: String,
        pickupRestaurant: String,
        destination: String
    ) {
        id = UUID()
        self.orderNumber = orderNumber
        self.pickupRestaurant = pickupRestaurant
        self.destination = destination
        requestedAt = Date()
        deliveryFee = 1.00
        status = .inTransit
        deliveredAt = nil
    }
}

private protocol DeliveryService {
    func submit(_ request: DeliveryRequestPayload) async throws -> DeliveryRecord
}

private struct LocalDeliveryService: DeliveryService {
    func submit(_ request: DeliveryRequestPayload) async throws -> DeliveryRecord {
        DeliveryRecord(
            orderNumber: request.orderNumber,
            pickupRestaurant: request.pickupRestaurant,
            destination: request.destination
        )
    }
}

private enum DeliveryRequestError: LocalizedError {
    case invalidOrderNumber

    var errorDescription: String? {
        switch self {
        case .invalidOrderNumber:
            return "Enter the 3-digit Grubhub order number before continuing."
        }
    }
}

private final class DeliveryFlowStore: ObservableObject {
    private let deliveryService: DeliveryService = LocalDeliveryService()

    @Published var orderNumber = ""
    @Published var selectedPickup = "Resnik House"
    @Published var selectedDestination = "Hunt Library"
    @Published var activeDelivery: DeliveryRecord?
    @Published var history: [DeliveryRecord] = []
    @Published var receiptRecord: DeliveryRecord?
    @Published var isSubmitting = false

    func beginNewDelivery() {
        orderNumber = ""
        selectedPickup = "Resnik House"
        selectedDestination = "Hunt Library"
        receiptRecord = nil
    }

    func requestDelivery() async throws {
        guard orderNumber.count == 3 else {
            throw DeliveryRequestError.invalidOrderNumber
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let request = DeliveryRequestPayload(
            orderNumber: orderNumber,
            pickupRestaurant: selectedPickup,
            destination: selectedDestination
        )
        let delivery = try await deliveryService.submit(request)
        activeDelivery = delivery
        receiptRecord = delivery
    }

    func completeDelivery() {
        guard var delivery = activeDelivery else { return }
        delivery.status = .delivered
        delivery.deliveredAt = Date()
        activeDelivery = delivery
        receiptRecord = delivery
        history.removeAll { $0.id == delivery.id }
        history.insert(delivery, at: 0)
    }

    func showReceipt(for delivery: DeliveryRecord) {
        receiptRecord = delivery
    }
}

struct ScottyDeliveryFlowView: View {
    @StateObject private var store = DeliveryFlowStore()
    @State private var selectedTab: DeliveryTab = .home
    @State private var path: [DeliveryRoute] = []

    init() {}

    public var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch selectedTab {
                case .home:
                    DeliveryHomeView(
                        onNewDelivery: startNewDelivery,
                        onTrack: { path.append(.tracking) },
                        onHistory: { selectedTab = .history },
                        onSettings: { selectedTab = .account }
                    )
                case .tracking:
                    DeliveryTrackingView(
                        store: store,
                        showsBackButton: false,
                        onBack: {},
                        onComplete: {
                            store.completeDelivery()
                            path.append(.delivered)
                        },
                        onReceipt: { path.append(.receipt) },
                        onStartDelivery: startNewDelivery
                    )
                case .history:
                    DeliveryHistoryView(store: store) { record in
                        store.showReceipt(for: record)
                        path.append(.receipt)
                    }
                case .account:
                    DeliverySettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DeliveryPalette.cream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DeliveryRoute.self, destination: destinationView)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if path.isEmpty {
                    DeliveryTabBar(selection: $selectedTab, onNewDelivery: startNewDelivery)
                }
            }
        }
        .tint(DeliveryPalette.red)
        .preferredColorScheme(.dark)
    }

    private func startNewDelivery() {
        store.beginNewDelivery()
        path.append(.orderNumber)
    }

    @ViewBuilder
    private func destinationView(for route: DeliveryRoute) -> some View {
        switch route {
        case .orderNumber:
            GrubHubOrderNumberView(store: store) {
                path.append(.pickup)
            }
        case .pickup:
            PickupRestaurantView(store: store) {
                path.append(.destination)
            }
        case .destination:
            DeliveryDestinationView(store: store) {
                path.append(.review)
            }
        case .review:
            DeliveryReviewView(store: store) {
                try await store.requestDelivery()
                path.append(.confirmation)
            }
        case .confirmation:
            DeliveryConfirmationView(
                store: store,
                onBack: { path.removeLast() },
                onTrack: { path.append(.tracking) }
            )
        case .tracking:
            DeliveryTrackingView(
                store: store,
                showsBackButton: true,
                onBack: { path.removeLast() },
                onComplete: {
                    store.completeDelivery()
                    path.append(.delivered)
                },
                onReceipt: { path.append(.receipt) },
                onStartDelivery: startNewDelivery
            )
        case .delivered:
            DeliveryArrivedView(
                store: store,
                showsBackButton: true,
                onBack: { path.removeLast() },
                onReceipt: { path.append(.receipt) }
            )
        case .receipt:
            DeliveryReceiptView(store: store) {
                path.removeAll()
                selectedTab = .history
            }
        }
    }
}

private struct DeliveryTabBar: View {
    @Binding var selection: DeliveryTab
    let onNewDelivery: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 0) {
                tabButton(.home, title: "Home", icon: "house")
                tabButton(.tracking, title: "Track", icon: "location.north")
                Color.clear
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                tabButton(.history, title: "History", icon: "doc.text")
                tabButton(.account, title: "Account", icon: "person")
            }
            .frame(height: 74)
            .offset(y: 15)
            .padding(.horizontal, 12)

            Button(action: onNewDelivery) {
                Image(systemName: "plus")
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: [DeliveryPalette.red, DeliveryPalette.navy, Color(red: 46 / 255, green: 145 / 255, blue: 164 / 255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: DeliveryPalette.navy.opacity(0.28), radius: 8, x: 0, y: 4)
            }
            .frame(maxWidth: .infinity)
            .zIndex(1)
            .accessibilityLabel("Start a delivery")
        }
        .frame(height: 89)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(.white)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(DeliveryPalette.border.opacity(0.6))
                        .frame(height: 1)
                }
        }
    }

    private func tabButton(_ tab: DeliveryTab, title: String, icon: String) -> some View {
        Button {
            selection = tab
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selection == tab ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 11, weight: selection == tab ? .semibold : .regular))
            }
            .foregroundStyle(selection == tab ? DeliveryPalette.red : Color(red: 153 / 255, green: 176 / 255, blue: 205 / 255))
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct DeliveryHeader: View {
    let title: String
    var subtitle: String? = nil
    var step: Int? = nil
    var showsBackButton = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                if showsBackButton {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 19, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 34, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                }

                Text(title)
                    .font(.system(size: 23, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 4)

                if let step {
                    Text("\(step)/4")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .frame(height: 34)

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 228 / 255, green: 218 / 255, blue: 196 / 255))
                    .padding(.top, 5)
            }

            if let step {
                HStack(spacing: 7) {
                    ForEach(1...4, id: \.self) { segment in
                        Capsule()
                            .fill(segment <= step ? DeliveryPalette.red : DeliveryPalette.border)
                            .frame(height: 6)
                    }
                }
                .padding(.top, 28)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 14)
        .background {
            ZStack(alignment: .topTrailing) {
                DeliveryPalette.navy
                Image("CMUTartanWave")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 185, height: 142)
                    .clipped()
                    .mask {
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .opacity(0.66)
                    .offset(x: 18, y: -7)
            }
            .ignoresSafeArea(edges: .top)
        }
    }
}

private struct HomeHeader: View {
    var body: some View {
        ZStack(alignment: .topTrailing) {
            DeliveryPalette.navy

            Image("CMUTartanWave")
                .resizable()
                .scaledToFill()
                .frame(width: 230, height: 220)
                .clipped()
                .mask {
                    LinearGradient(
                        colors: [.clear, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .opacity(0.72)
                .offset(x: 24, y: -10)
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Good evening!")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                Text("Need something delivered across campus?")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.92))
            }
            .padding(.horizontal, 32)
            .padding(.top, 85)
        }
        .frame(height: 300)
        .background(DeliveryPalette.navy.ignoresSafeArea(edges: .top))
    }
}

private struct DeliveryHeroCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomTrailing) {
                Color(red: 255 / 255, green: 252 / 255, blue: 247 / 255)

                Image("FigmaHomeCampusBackdrop")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 185)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .opacity(0.3)
                    .clipped()

                Image("FigmaHomeScotty")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 72)
                    .padding(.trailing, 58)
                    .padding(.bottom, 8)

                HStack(alignment: .bottom, spacing: 8) {
                    Text("Deliver\nNow")
                        .font(.system(size: 35, weight: .heavy))
                        .lineSpacing(-3)
                        .foregroundStyle(DeliveryPalette.navy)
                        .fixedSize()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(DeliveryPalette.red)
                        .clipShape(Circle())
                        .padding(.bottom, 4)

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 32)
                .padding(.top, 48)
            }
            .frame(height: 221)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: DeliveryPalette.navy.opacity(0.08), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Deliver now")
    }
}

private struct DeliveryHomeView: View {
    let onNewDelivery: () -> Void
    let onTrack: () -> Void
    let onHistory: () -> Void
    let onSettings: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    HomeHeader()
                    DeliveryHeroCard(action: onNewDelivery)
                        .padding(.horizontal, 24)
                        .padding(.top, 177)
                }
                .frame(height: 400)

                HStack(spacing: 14) {
                    DeliveryActionCard(
                        title: "Track Order",
                        imageName: "FigmaHomeTrackArtwork",
                        action: onTrack
                    )
                    DeliveryActionCard(
                        title: "Order History",
                        imageName: "FigmaHomeHistoryArtwork",
                        action: onHistory
                    )
                }
                .padding(.horizontal, 27)
                .padding(.top, 37)

                Button(action: onSettings) {
                    HStack(spacing: 12) {
                        Text("Setting")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(DeliveryPalette.navy)

                        Image("FigmaSettingsArtwork")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 62)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 27, height: 27)
                            .background(DeliveryPalette.red)
                            .clipShape(Circle())
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 70)
                    .background(Color(red: 255 / 255, green: 252 / 255, blue: 247 / 255))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 30)
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
        }
        .background(DeliveryPalette.navy)
        .ignoresSafeArea(edges: .top)
    }

}

private struct DeliveryActionCard: View {
    let title: String
    let imageName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 125)
                    .frame(maxWidth: .infinity)

                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DeliveryPalette.navy)

                Spacer(minLength: 4)

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 27, height: 27)
                        .background(DeliveryPalette.red)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 2)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 214, alignment: .topLeading)
            .background(Color(red: 255 / 255, green: 252 / 255, blue: 247 / 255))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

private struct GrubHubOrderNumberView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(title: "GrubHub Order number", step: 1, showsBackButton: true) {
                dismiss()
            }

            Text("Enter order number from GrubHub")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.top, 32)

            HStack(spacing: 18) {
                ForEach(0..<3, id: \.self) { index in
                    Text(index < store.orderNumber.count ? String(Array(store.orderNumber)[index]) : "")
                        .font(.system(size: 27, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 62, height: 62)
                        .overlay {
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color.black, lineWidth: 1.5)
                        }
                }
            }
            .padding(.top, 74)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("GrubHub order number, \(store.orderNumber.count) of 3 digits entered")

            Spacer(minLength: 32)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...9, id: \.self) { number in
                    keypadButton("\(number)") {
                        guard store.orderNumber.count < 3 else { return }
                        store.orderNumber.append(String(number))
                    }
                }
                Color.clear
                    .frame(height: 46)
                    .accessibilityHidden(true)
                keypadButton("0") {
                    guard store.orderNumber.count < 3 else { return }
                    store.orderNumber.append("0")
                }
                Button {
                    if !store.orderNumber.isEmpty {
                        store.orderNumber.removeLast()
                    }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.system(size: 21))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete last digit")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)

            FlowFooter(
                onBack: { dismiss() },
                onContinue: onContinue,
                isDisabled: store.orderNumber.count != 3
            )
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }

    private func keypadButton(_ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(value)
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .shadow(color: .black.opacity(0.22), radius: 0, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(value)
    }
}

private struct PickupRestaurantView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let restaurants: [(name: String, subtitle: String)] = [
        ("Resnik House", "Campus dining"),
        ("Manna", "Morewood Gardens"),
        ("De Fer", "Wean Hall"),
        ("Schatz Dining Room", "University Center")
    ]

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(title: "Pickup Restaurant", step: 2, showsBackButton: true) {
                dismiss()
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Available campus locations")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DeliveryPalette.navy)
                        .padding(.bottom, 36)

                    ForEach(restaurants, id: \.name) { restaurant in
                        SelectionRow(
                            title: restaurant.name,
                            subtitle: restaurant.subtitle,
                            icon: "house",
                            isSelected: store.selectedPickup == restaurant.name
                        ) {
                            store.selectedPickup = restaurant.name
                        }
                    }
                }
                .padding(.horizontal, 27)
                .padding(.top, 56)
                .padding(.bottom, 24)
            }

            FlowFooter(onBack: { dismiss() }, onContinue: onContinue)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct DeliveryDestinationView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onContinue: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let destinations: [(name: String, subtitle: String)] = [
        ("Hunt Library", "Selected drop-off"),
        ("Morewood Gardens", "Campus residence")
    ]

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(title: "Delivery destination", step: 3, showsBackButton: true) {
                dismiss()
            }

            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select a drop-off point")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DeliveryPalette.navy)
                            .padding(.bottom, 14)

                        Image("FigmaCampusMap")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(329, geometry.size.width - 62), height: 244)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .padding(.bottom, 32)
                            .accessibilityLabel("Map of Carnegie Mellon campus")

                        ForEach(destinations, id: \.name) { destination in
                            SelectionRow(
                                title: destination.name,
                                subtitle: store.selectedDestination == destination.name ? "Selected drop-off" : destination.subtitle,
                                icon: nil,
                                isSelected: store.selectedDestination == destination.name
                            ) {
                                store.selectedDestination = destination.name
                            }
                        }
                    }
                    .padding(.horizontal, 31)
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                }
            }

            FlowFooter(onBack: { dismiss() }, onContinue: onContinue)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct SelectionRow: View {
    let title: String
    let subtitle: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 21))
                        .foregroundStyle(DeliveryPalette.red)
                        .frame(width: 47, height: 47)
                        .background(isSelected ? Color(red: 248 / 255, green: 237 / 255, blue: 238 / 255) : DeliveryPalette.pale)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DeliveryPalette.navy)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(DeliveryPalette.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(isSelected ? DeliveryPalette.red : DeliveryPalette.border)
            }
            .padding(.horizontal, 15)
            .frame(height: icon == nil ? 57 : 78)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct DeliveryReviewView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onConfirm: () async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var submissionError: String?

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(title: "Review Delivery", step: 4, showsBackButton: true) {
                dismiss()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Image("scotty_rover")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 175, height: 88)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Scotty delivery rover")

                    VStack(alignment: .leading, spacing: 14) {
                        Text("ORDER DETAILS")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DeliveryPalette.muted)

                        ReviewDetailRow(label: "Grubhub order", value: "#\(store.orderNumber)")
                        Divider().overlay(DeliveryPalette.border)
                        ReviewDetailRow(label: "Pickup", value: store.selectedPickup)
                        Divider().overlay(DeliveryPalette.border)
                        ReviewDetailRow(label: "Drop-off", value: store.selectedDestination)
                        Divider().overlay(DeliveryPalette.border)
                    }
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Delivery fee")
                                .font(.system(size: 14))
                                .foregroundStyle(DeliveryPalette.muted)
                            Spacer()
                            Text("$1.00")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(DeliveryPalette.navy)
                        }
                    }
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if let submissionError {
                        Text(submissionError)
                            .font(.system(size: 13))
                            .foregroundStyle(DeliveryPalette.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 18)
            }

            Button {
                Task {
                    submissionError = nil
                    do {
                        try await onConfirm()
                    } catch {
                        submissionError = error.localizedDescription
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if store.isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(store.isSubmitting ? "Submitting…" : "Continue · $1.00")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(DeliveryPalette.red)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .disabled(store.isSubmitting)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct ReviewDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(DeliveryPalette.muted)
            Spacer(minLength: 14)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DeliveryPalette.navy)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct FlowFooter: View {
    let onBack: () -> Void
    let onContinue: () -> Void
    var isDisabled = false

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 43, height: 43)
                    .background(DeliveryPalette.red)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Go back")

            Spacer()

            Button(action: onContinue) {
                HStack(spacing: 9) {
                    Text("Next")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 126, height: 54)
                .background(isDisabled ? DeliveryPalette.red.opacity(0.45) : DeliveryPalette.red)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

private struct DeliveryConfirmationView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onBack: () -> Void
    let onTrack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(
                title: "Delivery request",
                subtitle: "Your request details",
                showsBackButton: true
            ) {
                onBack()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Image("scotty_rover")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 205)
                        .padding(.horizontal, 32)
                        .padding(.top, 14)

                    Text("Request details")
                        .font(.system(size: 15))
                        .foregroundStyle(DeliveryPalette.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order #\(store.activeDelivery?.orderNumber ?? store.orderNumber)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DeliveryPalette.navy)

                        Divider().overlay(DeliveryPalette.border)

                        Text("\(store.selectedPickup)  →  \(store.selectedDestination)")
                            .font(.system(size: 14))
                            .foregroundStyle(DeliveryPalette.muted)

                        Text("Delivery fee  ·  $1.00")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(DeliveryPalette.navy)
                        Divider().overlay(DeliveryPalette.border)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)

                }
                .padding(.bottom, 16)
            }

            Button(action: onTrack) {
                Text("View delivery status  →")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(DeliveryPalette.red)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct DeliveryTrackingView: View {
    @ObservedObject var store: DeliveryFlowStore
    let showsBackButton: Bool
    let onBack: () -> Void
    let onComplete: () -> Void
    let onReceipt: () -> Void
    let onStartDelivery: () -> Void

    private var delivery: DeliveryRecord? {
        store.activeDelivery
    }

    var body: some View {
        if let delivery {
            if delivery.status == .delivered {
                DeliveryArrivedView(
                    store: store,
                    showsBackButton: showsBackButton,
                    onBack: onBack,
                    onReceipt: onReceipt
                )
            } else {
                trackingContent(delivery)
            }
        } else {
            emptyTrackingContent
        }
    }

    private func trackingContent(_ delivery: DeliveryRecord) -> some View {
        VStack(spacing: 0) {
            DeliveryHeader(
                title: "Delivery status",
                subtitle: "Updates for your delivery",
                step: 3,
                showsBackButton: showsBackButton,
                onBack: onBack
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("Waiting for delivery updates")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DeliveryPalette.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image("FigmaHomeTrackArtwork")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 210)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Order #\(delivery.orderNumber)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DeliveryPalette.navy)
                        Divider().overlay(DeliveryPalette.border)
                        ReviewDetailRow(label: "Pickup", value: delivery.pickupRestaurant)
                        ReviewDetailRow(label: "Drop-off", value: delivery.destination)
                        ReviewDetailRow(label: "Delivery fee", value: "$1.00")
                    }
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("When you have your order, confirm delivery below.")
                        .font(.system(size: 13))
                        .foregroundStyle(DeliveryPalette.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }

            Button(action: onComplete) {
                Text("Confirm delivery received")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(DeliveryPalette.red)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }

    private var emptyTrackingContent: some View {
        VStack(spacing: 0) {
            DeliveryHeader(
                title: "Track order",
                subtitle: "Follow your Scotty delivery",
                showsBackButton: showsBackButton,
                onBack: onBack
            )

            Spacer()

            Image("scotty_resting")
                .resizable()
                .scaledToFit()
                .frame(width: 145, height: 145)

            Text("No active delivery")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(DeliveryPalette.navy)
                .padding(.top, 14)

            Text("Start a delivery request to see updates here.")
                .font(.system(size: 14))
                .foregroundStyle(DeliveryPalette.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 7)

            Button(action: onStartDelivery) {
                Text("Start a delivery")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 52)
                    .background(DeliveryPalette.red)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .padding(.top, 24)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct DeliveryArrivedView: View {
    @ObservedObject var store: DeliveryFlowStore
    let showsBackButton: Bool
    let onBack: () -> Void
    let onReceipt: () -> Void

    private var delivery: DeliveryRecord? {
        store.activeDelivery ?? store.receiptRecord
    }

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(
                title: "Delivered",
                subtitle: "Your delivery is ready for pickup",
                step: 4,
                showsBackButton: showsBackButton,
                onBack: onBack
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Image("scotty_arrived")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 223, height: 182)
                        .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your delivery has arrived")
                            .font(.system(size: 23, weight: .bold))
                            .foregroundStyle(DeliveryPalette.navy)
                        Text("Collect your meal at the \(delivery?.destination ?? "campus") drop-off point.")
                            .font(.system(size: 15))
                            .foregroundStyle(DeliveryPalette.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Delivered at \(delivery?.deliveredAt?.formatted(date: .omitted, time: .shortened) ?? Date().formatted(date: .omitted, time: .shortened))")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DeliveryPalette.navy)
                        Text("Order #\(delivery?.orderNumber ?? store.orderNumber)")
                            .font(.system(size: 12))
                            .foregroundStyle(DeliveryPalette.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Button(action: onReceipt) {
                Text("View delivery receipt")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(DeliveryPalette.red)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct DeliveryHistoryView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onOpenReceipt: (DeliveryRecord) -> Void

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(title: "Order history", subtitle: "Your previous Scotty deliveries")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent deliveries")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DeliveryPalette.navy)

                    if store.history.isEmpty {
                        VStack(spacing: 14) {
                            Image("FigmaHomeHistoryArtwork")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 170, height: 145)
                            Text("No previous deliveries")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(DeliveryPalette.navy)
                            Text("Your completed Scotty deliveries will show up here.")
                                .font(.system(size: 13))
                                .foregroundStyle(DeliveryPalette.muted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 42)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        ForEach(store.history) { record in
                            Button {
                                onOpenReceipt(record)
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Delivered")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(DeliveryPalette.teal)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(DeliveryPalette.pale)
                                        .clipShape(Capsule())

                                    Text(record.requestedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(DeliveryPalette.navy)

                                    Text("\(record.pickupRestaurant) → \(record.destination)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(DeliveryPalette.muted)

                                    Text("Order #\(record.orderNumber)")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DeliveryPalette.muted)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }
}

private struct DeliveryReceiptView: View {
    @ObservedObject var store: DeliveryFlowStore
    let onBackToHistory: () -> Void

    private var delivery: DeliveryRecord? {
        store.receiptRecord ?? store.activeDelivery
    }

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(
                title: "Delivery receipt",
                subtitle: delivery.map { "Order #\($0.orderNumber)" },
                showsBackButton: true,
                onBack: onBackToHistory
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 17) {
                        Text("Delivery complete")
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(DeliveryPalette.teal)

                        Text("Order #\(delivery?.orderNumber ?? "—")")
                            .font(.system(size: 14))
                            .foregroundStyle(DeliveryPalette.muted)

                        Image("FigmaHomeHistoryArtwork")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)

                        Divider().overlay(DeliveryPalette.border)
                        receiptRow("Ordered at", value: delivery?.requestedAt.formatted(date: .abbreviated, time: .shortened) ?? "—")
                        receiptRow("Pickup restaurant", value: delivery?.pickupRestaurant ?? "—")
                        receiptRow("Delivered to", value: delivery?.destination ?? "—")
                        receiptRow("Marked delivered at", value: delivery?.deliveredAt?.formatted(date: .omitted, time: .shortened) ?? "—")
                        receiptRow("Delivery status", value: delivery?.status == .delivered ? "Delivered" : "In progress")
                        Divider().overlay(DeliveryPalette.border)

                        HStack {
                            Text("Delivery fee")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(DeliveryPalette.navy)
                            Spacer()
                            Text(String(format: "$%.2f", delivery?.deliveryFee ?? 1.00))
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(DeliveryPalette.red)
                        }
                    }
                    .padding(19)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }

            Button(action: onBackToHistory) {
                Text("Back to order history")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(DeliveryPalette.red)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
    }

    private func receiptRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(DeliveryPalette.muted)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DeliveryPalette.navy)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct DeliverySettingsView: View {
    @AppStorage("delivery_notifications_enabled") private var notificationsEnabled = true
    @State private var showingLocations = false
    @State private var alertMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            DeliveryHeader(title: "Settings", subtitle: "Manage your Scotty experience")

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DeliveryPalette.navy)

                    HStack(spacing: 14) {
                        Text("S")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(DeliveryPalette.teal)
                            .frame(width: 47, height: 47)
                            .background(DeliveryPalette.pale)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ScottyDelivery")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(DeliveryPalette.navy)
                            Text("Profile not connected")
                                .font(.system(size: 12))
                                .foregroundStyle(DeliveryPalette.muted)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Text("Preferences")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DeliveryPalette.navy)
                        .padding(.top, 10)

                    Toggle(isOn: $notificationsEnabled) {
                        SettingsRowLabel(title: "Notifications", subtitle: "Delivery status alerts")
                    }
                    .tint(DeliveryPalette.red)
                    .padding(.horizontal, 18)
                    .frame(height: 74)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button {
                        showingLocations = true
                    } label: {
                        SettingsRowLabel(title: "Delivery locations", subtitle: "Saved drop-off points", showsChevron: true)
                    }
                    .buttonStyle(.plain)

                    Button {
                        alertMessage = "For help with a Scotty delivery, contact ScottyLabs support."
                    } label: {
                        SettingsRowLabel(title: "Help & support", subtitle: "Get assistance", showsChevron: true)
                    }
                    .buttonStyle(.plain)

                    Button {
                        alertMessage = "ScottyDelivery · Carnegie Mellon University"
                    } label: {
                        SettingsRowLabel(title: "Privacy & terms", subtitle: "App information", showsChevron: true)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
        }
        .background(DeliveryPalette.cream.ignoresSafeArea())
        .sheet(isPresented: $showingLocations) {
            NavigationStack {
                List {
                    Label("Hunt Library", systemImage: "mappin")
                    Label("Morewood Gardens", systemImage: "mappin")
                }
                .navigationTitle("Delivery locations")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingLocations = false }
                    }
                }
            }
            .presentationDetents([.medium])
            .preferredColorScheme(.light)
        }
        .alert("ScottyDelivery", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

private struct SettingsRowLabel: View {
    let title: String
    let subtitle: String
    var showsChevron = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DeliveryPalette.navy)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(DeliveryPalette.muted)
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DeliveryPalette.muted)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 74)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}
