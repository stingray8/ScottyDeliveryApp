import SwiftUI

public struct OrderHistoryView: View {
    @ObservedObject private var cartManager = CartManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Active Orders Section
                    if !cartManager.activeOrders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Active Deliveries")
                                    .font(.headline.bold())
                                    .foregroundColor(Color.appForeground)

                                Spacer()

                                ShadcnBadge("In Progress", icon: "bolt.fill", variant: .tartan)
                            }

                            ForEach(cartManager.activeOrders) { order in
                                NavigationLink(destination: LiveTrackingView(order: order)) {
                                    ActiveOrderCard(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }

                    // MARK: - Past Orders Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past Orders")
                            .font(.headline.bold())
                            .foregroundColor(Color.appForeground)

                        if cartManager.pastOrders.isEmpty {
                            ShadcnCard(padding: 24) {
                                VStack(spacing: 12) {
                                    Image("scotty_resting")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                    Text("No previous orders")
                                        .font(.headline)
                                        .foregroundColor(Color.appForeground)
                                    Text("When you order campus meals with Scotty, receipts will appear here.")
                                        .font(.caption)
                                        .foregroundColor(Color.appMutedForeground)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else {
                            ForEach(cartManager.pastOrders) { order in
                                PastOrderCard(order: order) {
                                    for item in order.items {
                                        cartManager.addItem(
                                            item.menuItem,
                                            quantity: item.quantity,
                                            options: item.selectedOptions,
                                            restaurantName: order.restaurantName
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 60)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Orders")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

// MARK: - Active Order Card
struct ActiveOrderCard: View {
    let order: Order
    
    var body: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.restaurantName)
                            .font(.headline)
                            .foregroundColor(Color.appForeground)
                        Text(order.orderNumber)
                            .font(.caption)
                            .foregroundColor(Color.appMutedForeground)
                    }
                    
                    Spacer()
                    
                    ShadcnBadge(order.status.rawValue, variant: .tartan)
                }
                
                ShadcnSeparator()
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(Color.tartanRed)
                        Text(order.dropoffLocation.name)
                            .font(.subheadline)
                            .foregroundColor(Color.appForeground)
                    }
                    
                    Spacer()
                    
                    Text("Tap to Track Live →")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.tartanRed)
                }
            }
        }
    }
}

// MARK: - Past Order Card
struct PastOrderCard: View {
    let order: Order
    let onReorder: () -> Void
    
    var body: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.restaurantName)
                            .font(.headline)
                            .foregroundColor(Color.appForeground)
                        Text(formattedDate(order.createdAt))
                            .font(.caption)
                            .foregroundColor(Color.appMutedForeground)
                    }
                    
                    Spacer()
                    
                    Text(String(format: "$%.2f", order.total))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.appForeground)
                }
                
                Text(order.items.map { "\($0.quantity)x \($0.menuItem.name)" }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(Color.appMutedForeground)
                    .lineLimit(2)
                
                ShadcnSeparator()
                
                HStack {
                    ShadcnBadge("Delivered", icon: "checkmark", variant: .success)
                    
                    Spacer()
                    
                    Button(action: onReorder) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reorder")
                        }
                        .font(.caption.bold())
                        .foregroundColor(Color.tartanRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.tartanRed.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

