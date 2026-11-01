import SwiftUI

public struct OrderConfirmationView: View {
    let order: Order
    let onTrackOrder: () -> Void
    let onDismiss: () -> Void

    public init(order: Order, onTrackOrder: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.order = order
        self.onTrackOrder = onTrackOrder
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // MARK: - Animated Scotty Success Mascot
                ZStack {
                    Circle()
                        .fill(Color.tartanRed.opacity(0.1))
                        .frame(width: 150, height: 150)

                    Image("scotty_success")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                }

                VStack(spacing: 8) {
                    ShadcnBadge("Order Confirmed", icon: "checkmark.circle.fill", variant: .success)

                    Text("Scotty is on it!")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.appForeground)

                    Text("Your order has been sent to \(order.restaurantName). Scotty rover is being prepped for dispatch.")
                        .font(.subheadline)
                        .foregroundColor(Color.appMutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // MARK: - Key Order Details Card
                ShadcnCard(padding: 16) {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ORDER NUMBER")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.appMutedForeground)
                                    .tracking(0.5)
                                Text(order.orderNumber)
                                    .font(.headline)
                                    .foregroundColor(Color.appForeground)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("ESTIMATED ARRIVAL")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.appMutedForeground)
                                    .tracking(0.5)
                                Text("~15-20 min")
                                    .font(.headline)
                                    .foregroundColor(Color.tartanRed)
                            }
                        }

                        ShadcnSeparator()

                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(Color.tartanRed)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("DELIVERING TO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.appMutedForeground)
                                Text(order.dropoffLocation.name)
                                    .font(.subheadline)
                                    .foregroundColor(Color.appForeground)
                            }
                            Spacer()
                        }

                        ShadcnSeparator()

                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(Color.tartanRed)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ROVER UNLOCK PIN")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.appMutedForeground)
                                Text(order.unlockPin)
                                    .font(.headline.bold())
                                    .tracking(4)
                                    .foregroundColor(Color.tartanRed)
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()

                // MARK: - Navigation Actions
                VStack(spacing: 12) {
                    ShadcnButton(
                        "Track Scotty Rover Live",
                        icon: "map.fill",
                        variant: .tartan
                    ) {
                        onTrackOrder()
                    }

                    Button(action: onDismiss) {
                        Text("Return to Explore")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appMutedForeground)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
    }
}

