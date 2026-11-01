import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import MapKit

public struct LiveTrackingView: View {
    @State public var order: Order
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPinUnlocked: Bool = false
    #if os(iOS)
    @State private var cameraPosition: MapCameraPosition
    #endif

    public init(order: Order) {
        self._order = State(initialValue: order)
        #if os(iOS)
        let midLat = (order.currentRoverLat + order.dropoffLocation.latitude) / 2
        let midLng = (order.currentRoverLng + order.dropoffLocation.longitude) / 2
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: midLat, longitude: midLng),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )))
        #endif
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 18) {
                // MARK: - Status & ETA Header
                etaStatusCard

                // MARK: - Interactive CMU Campus Delivery Map
                campusMapCard

                // MARK: - Rover Unlock Code Card
                unlockPinCard

                // MARK: - Stepper Progress
                ShadcnCard(padding: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Live Delivery Progress")
                            .font(.headline)
                            .foregroundColor(Color.appForeground)

                        DeliveryStatusStepper(currentStatus: currentLiveOrder.status)
                    }
                }

                // MARK: - Order Item Details
                orderDetailsCard

                // MARK: - Actions (Completed button)
                if currentLiveOrder.status == .arrived {
                    ShadcnButton("I Have Retrieved My Order", icon: "checkmark.circle.fill", variant: .tartan) {
                        cartManager.completeOrder(currentLiveOrder)
                        dismiss()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(order.orderNumber)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    // Live reactive order from CartManager
    private var currentLiveOrder: Order {
        cartManager.activeOrders.first(where: { $0.id == order.id }) ?? order
    }

    // Status mascot image name
    private var statusMascotName: String {
        switch currentLiveOrder.status {
        case .placed, .preparing:
            return "scotty_preparing"
        case .pickedUp, .onTheWay:
            return "scotty_on_the_way"
        case .arrived, .completed:
            return "scotty_arrived"
        case .cancelled:
            return "scotty_resting"
        }
    }

    // MARK: - ETA Card
    private var etaStatusCard: some View {
        ShadcnCard(padding: 16) {
            HStack(alignment: .center, spacing: 14) {
                Image(statusMascotName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(Color.tartanRed.opacity(0.12))
                            .frame(width: 56, height: 56)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLiveOrder.status.rawValue)
                        .font(.headline.bold())
                        .foregroundColor(Color.appForeground)

                    Text("Scotty delivering from \(currentLiveOrder.restaurantName)")
                        .font(.caption)
                        .foregroundColor(Color.appMutedForeground)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("ETA")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.appMutedForeground)

                    Text("~8 min")
                        .font(.title3.bold())
                        .foregroundColor(Color.tartanRed)
                }
            }
        }
    }

    // MARK: - Map Card
    @ViewBuilder
    private var campusMapCard: some View {
        ShadcnCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                #if os(iOS)
                Map(position: $cameraPosition) {
                    // Dropoff Hub Pin
                    Marker(
                        currentLiveOrder.dropoffLocation.name,
                        systemImage: "mappin.and.ellipse",
                        coordinate: currentLiveOrder.dropoffLocation.coordinate
                    )
                    .tint(Color.tartanRed)

                    // Scotty Rover Marker
                    Annotation("Scotty Rover", coordinate: CLLocationCoordinate2D(
                        latitude: currentLiveOrder.currentRoverLat,
                        longitude: currentLiveOrder.currentRoverLng
                    )) {
                        ZStack {
                            Circle()
                                .fill(Color.tartanRed)
                                .frame(width: 36, height: 36)
                                .shadow(radius: 4)
                            Image(systemName: "dog.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                #else
                // macOS preview fallback
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appMuted)
                        .frame(height: 220)
                    VStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.appMutedForeground)
                        Text("Live map — iPhone only")
                            .font(.caption)
                            .foregroundColor(Color.appMutedForeground)
                    }
                }
                #endif

                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color.tartanRed)
                        .font(.caption)
                    Text("Destined for \(currentLiveOrder.dropoffLocation.roomOrZone)")
                        .font(.caption)
                        .foregroundColor(Color.appMutedForeground)
                    Spacer()
                }
                .padding(12)
            }
        }
    }

    // MARK: - Unlock PIN Card
    private var unlockPinCard: some View {
        ShadcnCard(padding: 16) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ROVER COMPARTMENT PIN")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.appMutedForeground)
                            .tracking(0.6)

                        Text("Use this code to open the insulated compartment")
                            .font(.caption)
                            .foregroundColor(Color.appMutedForeground)
                    }
                    Spacer()
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(Color.tartanRed)
                        .font(.title2)
                }

                HStack(spacing: 12) {
                    ForEach(Array(currentLiveOrder.unlockPin), id: \.self) { char in
                        Text(String(char))
                            .font(.title.bold())
                            .foregroundColor(Color.appForeground)
                            .frame(width: 46, height: 54)
                            .background(Color.appMuted)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appCardBorder, lineWidth: 1))
                    }
                }
                .padding(.vertical, 6)

                if showingPinUnlocked {
                    Text("Compartment Unlocked! Enjoy your meal 🐾")
                        .font(.caption.bold())
                        .foregroundColor(Color.appSuccess)
                } else {
                    Button(action: {
                        #if canImport(UIKit)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        #endif
                        showingPinUnlocked = true
                    }) {
                        Text("Tap to Authenticate & Unlock Rover")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.tartanRed)
                    }
                }
            }
        }
    }

    // MARK: - Order Details
    private var orderDetailsCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Order Summary")
                    .font(.headline)
                    .foregroundColor(Color.appForeground)

                ForEach(currentLiveOrder.items) { item in
                    HStack {
                        Text("\(item.quantity)x \(item.menuItem.name)")
                            .font(.subheadline)
                            .foregroundColor(Color.appForeground)
                        Spacer()
                        Text(String(format: "$%.2f", item.totalPrice))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color.appForeground)
                    }
                }

                ShadcnSeparator()

                HStack {
                    Text("Total Charged (\(currentLiveOrder.paymentMethod.rawValue))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.appForeground)
                    Spacer()
                    Text(String(format: "$%.2f", currentLiveOrder.total))
                        .font(.headline.bold())
                        .foregroundColor(Color.tartanRed)
                }
            }
        }
    }
}
