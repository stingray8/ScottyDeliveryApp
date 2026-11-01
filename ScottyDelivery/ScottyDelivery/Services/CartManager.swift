import Foundation
import Combine

// MARK: - Cart & Order State Manager
public final class CartManager: ObservableObject {
    public static let shared = CartManager()
    
    @Published public var items: [CartItem] = []
    @Published public var activeRestaurantId: String?
    @Published public var activeRestaurantName: String?
    @Published public var selectedDropoffHub: CampusLocation
    @Published public var dropoffNotes: String = ""
    @Published public var selectedPaymentMethod: PaymentMethod = .dineXtra
    
    // Active orders and history
    @Published public var activeOrders: [Order] = []
    @Published public var pastOrders: [Order] = []
    @Published public var isPlacingOrder: Bool = false
    
    private var trackingTimers: [String: Timer] = [:]
    
    public init() {
        // Default to Gates 4th floor entrance
        self.selectedDropoffHub = APIClient.shared.defaultCampusHubs[0]
        setupDemoPastOrder()
    }
    
    // MARK: - Cart Calculations
    public var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    public var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    public var deliveryFee: Double {
        // Free delivery for CMU students on orders over $10 or flat $1.49
        if items.isEmpty { return 0.0 }
        return subtotal >= 10.0 ? 0.0 : 1.49
    }
    
    public var studentDiscount: Double {
        // CMU ScottyLabs Student Perk: $1.00 off
        if subtotal >= 12.0 {
            return 1.00
        }
        return 0.0
    }
    
    public var tax: Double {
        subtotal * 0.07 // 7% Allegheny County / PA meal tax
    }
    
    public var total: Double {
        max(0, subtotal + deliveryFee + tax - studentDiscount)
    }
    
    // MARK: - Cart Operations
    public func addItem(_ item: MenuItem, quantity: Int = 1, options: [String: [CustomizationItem]] = [:], notes: String = "", restaurantName: String) {
        // If adding from another restaurant, reset cart to keep single-restaurant delivery
        if let currentRestId = activeRestaurantId, currentRestId != item.restaurantId {
            items.removeAll()
        }
        
        self.activeRestaurantId = item.restaurantId
        self.activeRestaurantName = restaurantName
        
        // Check if matching item with identical options exists
        if let index = items.firstIndex(where: { $0.menuItem.id == item.id && $0.selectedOptions == options }) {
            items[index].quantity += quantity
        } else {
            let newItem = CartItem(
                menuItem: item,
                quantity: quantity,
                selectedOptions: options,
                specialNotes: notes
            )
            items.append(newItem)
        }
    }
    
    public func updateQuantity(for cartItemId: UUID, change: Int) {
        guard let index = items.firstIndex(where: { $0.id == cartItemId }) else { return }
        let newQty = items[index].quantity + change
        if newQty <= 0 {
            items.remove(at: index)
            if items.isEmpty {
                activeRestaurantId = nil
                activeRestaurantName = nil
            }
        } else {
            items[index].quantity = newQty
        }
    }
    
    public func removeItem(at indexSet: IndexSet) {
        items.remove(atOffsets: indexSet)
        if items.isEmpty {
            activeRestaurantId = nil
            activeRestaurantName = nil
        }
    }
    
    public func clearCart() {
        items.removeAll()
        activeRestaurantId = nil
        activeRestaurantName = nil
    }
    
    // MARK: - Checkout & Order Submission
    public func checkout() async -> Order? {
        guard !items.isEmpty, let restId = activeRestaurantId, let restName = activeRestaurantName else { return nil }
        
        await MainActor.run {
            self.isPlacingOrder = true
        }
        
        let orderNumber = "SD-\(Int.random(in: 1000...9999))"
        let arrivalDate = Date().addingTimeInterval(TimeInterval(selectedDropoffHub.estimatedMinutesFromCenter * 60))
        let pin = "\(Int.random(in: 1000...9999))"
        
        let newOrder = Order(
            orderNumber: orderNumber,
            restaurantId: restId,
            restaurantName: restName,
            items: items,
            dropoffLocation: selectedDropoffHub,
            dropoffNotes: dropoffNotes,
            subtotal: subtotal,
            deliveryFee: deliveryFee,
            studentDiscount: studentDiscount,
            tax: tax,
            total: total,
            paymentMethod: selectedPaymentMethod,
            status: .placed,
            createdAt: Date(),
            estimatedArrival: arrivalDate,
            unlockPin: pin,
            currentRoverLat: 40.4432,
            currentRoverLng: -79.9422
        )
        
        do {
            let verifiedOrder = try await APIClient.shared.placeOrder(newOrder)
            await MainActor.run {
                self.activeOrders.insert(verifiedOrder, at: 0)
                self.clearCart()
                self.isPlacingOrder = false
                self.startRoverSimulation(for: verifiedOrder.id)
            }
            return verifiedOrder
        } catch {
            await MainActor.run {
                self.activeOrders.insert(newOrder, at: 0)
                self.clearCart()
                self.isPlacingOrder = false
                self.startRoverSimulation(for: newOrder.id)
            }
            return newOrder
        }
    }
    
    // MARK: - Rover Status Progression Simulation
    private func startRoverSimulation(for orderId: String) {
        var elapsed = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            elapsed += 5
            guard let index = self.activeOrders.firstIndex(where: { $0.id == orderId }) else {
                timer.invalidate()
                return
            }
            
            var order = self.activeOrders[index]
            
            // Advance status smoothly over time
            if elapsed == 5 {
                order.status = .preparing
            } else if elapsed == 10 {
                order.status = .pickedUp
            } else if elapsed == 15 {
                order.status = .onTheWay
                // Interpolate rover coordinate toward dropoff
                order.currentRoverLat = (order.currentRoverLat + order.dropoffLocation.latitude) / 2
                order.currentRoverLng = (order.currentRoverLng + order.dropoffLocation.longitude) / 2
            } else if elapsed >= 25 {
                order.status = .arrived
                order.currentRoverLat = order.dropoffLocation.latitude
                order.currentRoverLng = order.dropoffLocation.longitude
                timer.invalidate()
            }
            
            self.activeOrders[index] = order
        }
        trackingTimers[orderId] = timer
    }
    
    public func completeOrder(_ order: Order) {
        if let index = activeOrders.firstIndex(where: { $0.id == order.id }) {
            var completed = activeOrders.remove(at: index)
            completed.status = .completed
            pastOrders.insert(completed, at: 0)
        }
    }
    
    private func setupDemoPastOrder() {
        let sampleHub = APIClient.shared.defaultCampusHubs[1]
        let sampleMenu = APIClient.shared.defaultRestaurants[0].menu[0]
        let sampleItem = CartItem(menuItem: sampleMenu, quantity: 1)
        
        let past = Order(
            orderNumber: "SD-8241",
            restaurantId: "exchange",
            restaurantName: "The Exchange",
            items: [sampleItem],
            dropoffLocation: sampleHub,
            dropoffNotes: "Leave at front desk",
            subtotal: 9.75,
            deliveryFee: 1.49,
            studentDiscount: 0.0,
            tax: 0.68,
            total: 11.92,
            paymentMethod: .dineXtra,
            status: .completed,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            estimatedArrival: Date().addingTimeInterval(-86400 * 2 + 1200),
            unlockPin: "1942"
        )
        self.pastOrders.append(past)
    }
}

