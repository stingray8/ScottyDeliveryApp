import SwiftUI

public struct CartView: View {
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var placedOrder: Order?
    @State private var showingOrderConfirmation: Bool = false
    @State private var showingLiveTracking: Bool = false
    @State private var showingHubPicker: Bool = false

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            if cartManager.items.isEmpty {
                emptyCartView
            } else {
                cartContentView
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Your Bag")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showingHubPicker) {
            HubPickerSheet(selectedHub: $cartManager.selectedDropoffHub, hubs: APIClient.shared.defaultCampusHubs)
        }
        .fullScreenCover(isPresented: $showingOrderConfirmation) {
            if let order = placedOrder {
                OrderConfirmationView(
                    order: order,
                    onTrackOrder: {
                        showingOrderConfirmation = false
                        showingLiveTracking = true
                    },
                    onDismiss: {
                        showingOrderConfirmation = false
                        dismiss()
                    }
                )
            }
        }
        .navigationDestination(isPresented: $showingLiveTracking) {
            if let order = placedOrder {
                LiveTrackingView(order: order)
            }
        }
    }

    // MARK: - Empty Cart View
    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Image("scotty_bag")
                .resizable()
                .scaledToFit()
                .frame(width: 130, height: 130)

            Text("Your Bag is Empty")
                .font(.title2.bold())
                .foregroundColor(Color.appForeground)

            Text("Explore delicious food from CMU campus eateries and have Scotty deliver it right to you.")
                .font(.subheadline)
                .foregroundColor(Color.appMutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ShadcnButton("Browse Eateries", variant: .tartan) {
                dismiss()
            }
            .frame(width: 200)
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Cart Content View
    private var cartContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Restaurant summary badge
                if let restName = cartManager.activeRestaurantName {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(Color.tartanRed)
                        Text(restName)
                            .font(.headline)
                            .foregroundColor(Color.appForeground)
                        Spacer()
                        Button(action: { cartManager.clearCart() }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                // Item list
                VStack(spacing: 10) {
                    ForEach(cartManager.items) { item in
                        CartItemRow(item: item)
                    }
                }

                // Delivery Dropoff Card
                dropoffLocationCard

                // Payment Method Selector
                paymentMethodCard

                // Price Breakdown Card
                pricingBreakdownCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 100) // Clearance for checkout bar
        }
        .safeAreaInset(edge: .bottom) {
            checkoutBottomBar
        }
    }

    // MARK: - Dropoff Hub Card
    private var dropoffLocationCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(Color.tartanRed)
                    Text("Delivery Hub")
                        .font(.headline)
                        .foregroundColor(Color.appForeground)
                    Spacer()
                    Button("Change") { showingHubPicker = true }
                        .font(.caption.bold())
                        .foregroundColor(Color.tartanRed)
                }

                ShadcnSeparator()

                VStack(alignment: .leading, spacing: 2) {
                    Text(cartManager.selectedDropoffHub.name)
                        .font(.subheadline.bold())
                        .foregroundColor(Color.appForeground)
                    Text(cartManager.selectedDropoffHub.roomOrZone)
                        .font(.caption)
                        .foregroundColor(Color.appMutedForeground)
                }

                ShadcnInput("Delivery notes (e.g. Call when near entrance)", text: $cartManager.dropoffNotes, icon: "note.text")
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Payment Method Card
    private var paymentMethodCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(Color.tartanRed)
                    Text("Payment Method")
                        .font(.headline)
                        .foregroundColor(Color.appForeground)
                    Spacer()
                }

                ShadcnSeparator()

                VStack(spacing: 8) {
                    ForEach(PaymentMethod.allCases) { method in
                        let isSelected = cartManager.selectedPaymentMethod == method
                        Button(action: { cartManager.selectedPaymentMethod = method }) {
                            HStack {
                                Image(systemName: method.iconName)
                                    .foregroundColor(isSelected ? Color.tartanRed : Color.appMutedForeground)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(method.rawValue)
                                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                            .foregroundColor(Color.appForeground)
                                        if method.isCMUAccount {
                                            ShadcnBadge("CMU Dining", variant: .tartan)
                                        }
                                    }
                                    Text(method.badgeText)
                                        .font(.caption2)
                                        .foregroundColor(Color.appMutedForeground)
                                }

                                Spacer()

                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? Color.tartanRed : Color.appMutedForeground)
                            }
                            .padding(10)
                            .background(isSelected ? Color.tartanRed.opacity(0.06) : Color.clear)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.tartanRed.opacity(0.3) : Color.clear, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - Price Breakdown Card
    private var pricingBreakdownCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(Color.appForeground)

                ShadcnSeparator()

                HStack {
                    Text("Subtotal")
                        .foregroundColor(Color.appMutedForeground)
                    Spacer()
                    Text(String(format: "$%.2f", cartManager.subtotal))
                        .foregroundColor(Color.appForeground)
                }

                if cartManager.studentDiscount > 0 {
                    HStack {
                        HStack(spacing: 4) {
                            Text("ScottyLabs Student Perk")
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(Color.appSuccess)
                        Spacer()
                        Text(String(format: "-$%.2f", cartManager.studentDiscount))
                            .fontWeight(.semibold)
                            .foregroundColor(Color.appSuccess)
                    }
                }

                HStack {
                    Text("Autonomous Delivery Fee")
                        .foregroundColor(Color.appMutedForeground)
                    Spacer()
                    Text(cartManager.deliveryFee == 0.0 ? "FREE" : String(format: "$%.2f", cartManager.deliveryFee))
                        .fontWeight(.semibold)
                        .foregroundColor(cartManager.deliveryFee == 0.0 ? Color.appSuccess : Color.appForeground)
                }

                HStack {
                    Text("Tax (7% PA Dining)")
                        .foregroundColor(Color.appMutedForeground)
                    Spacer()
                    Text(String(format: "$%.2f", cartManager.tax))
                        .foregroundColor(Color.appForeground)
                }

                ShadcnSeparator()

                HStack {
                    Text("Total")
                        .font(.headline.bold())
                        .foregroundColor(Color.appForeground)
                    Spacer()
                    Text(String(format: "$%.2f", cartManager.total))
                        .font(.title3.bold())
                        .foregroundColor(Color.tartanRed)
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Checkout Bottom Bar
    private var checkoutBottomBar: some View {
        VStack {
            ShadcnButton(
                String(format: "Place Order • $%.2f", cartManager.total),
                icon: "lock.shield.fill",
                variant: .tartan,
                isLoading: cartManager.isPlacingOrder
            ) {
                Task {
                    let order = await cartManager.checkout()
                    if let order = order {
                        self.placedOrder = order
                        self.showingOrderConfirmation = true
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.appCard)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.appCardBorder), alignment: .top)
    }
}

// MARK: - Cart Item Row Component
struct CartItemRow: View {
    let item: CartItem
    @ObservedObject private var cartManager = CartManager.shared

    var body: some View {
        ShadcnCard(padding: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.menuItem.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(Color.appForeground)

                    // Display selected options
                    ForEach(Array(item.selectedOptions.keys), id: \.self) { key in
                        if let list = item.selectedOptions[key] {
                            Text(list.map { $0.name }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(Color.appMutedForeground)
                        }
                    }

                    if !item.specialNotes.isEmpty {
                        Text("Note: \(item.specialNotes)")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(Color.appMutedForeground)
                    }

                    Text(String(format: "$%.2f", item.totalPrice))
                        .font(.subheadline.bold())
                        .foregroundColor(Color.tartanRed)
                        .padding(.top, 2)
                }

                Spacer()

                // Stepper (+ / -)
                HStack(spacing: 12) {
                    Button(action: {
                        cartManager.updateQuantity(for: item.id, change: -1)
                    }) {
                        Image(systemName: item.quantity == 1 ? "trash" : "minus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(item.quantity == 1 ? .red : Color.appForeground)
                            .frame(width: 28, height: 28)
                            .background(Color.appMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text("\(item.quantity)")
                        .font(.headline.bold())
                        .frame(minWidth: 20)

                    Button(action: {
                        cartManager.updateQuantity(for: item.id, change: 1)
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.appForeground)
                            .frame(width: 28, height: 28)
                            .background(Color.appMuted)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}
