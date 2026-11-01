import Foundation
import CoreLocation

// MARK: - Campus Delivery Location (Dropoff Hub)
public struct CampusLocation: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let building: String
    public let roomOrZone: String
    public let latitude: Double
    public let longitude: Double
    public let estimatedMinutesFromCenter: Int
    public let isPopular: Bool
    
    public init(id: String, name: String, building: String, roomOrZone: String, latitude: Double, longitude: Double, estimatedMinutesFromCenter: Int, isPopular: Bool = false) {
        self.id = id
        self.name = name
        self.building = building
        self.roomOrZone = roomOrZone
        self.latitude = latitude
        self.longitude = longitude
        self.estimatedMinutesFromCenter = estimatedMinutesFromCenter
        self.isPopular = isPopular
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Dietary Tags
public enum DietaryTag: String, Codable, CaseIterable, Identifiable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case halal = "Halal"
    case glutenFree = "Gluten-Free"
    case dairyFree = "Dairy-Free"
    case nutFree = "Nut-Free"
    case spicy = "Spicy"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .vegetarian: return "leaf.fill"
        case .vegan: return "sparkles"
        case .halal: return "moon.stars.fill"
        case .glutenFree: return "cross.case.fill"
        case .dairyFree: return "drop.triangle.fill"
        case .nutFree: return "shield.fill"
        case .spicy: return "flame.fill"
        }
    }
}

// MARK: - Menu Customization
public struct CustomizationItem: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let priceDelta: Double
    
    public init(id: String, name: String, priceDelta: Double = 0.0) {
        self.id = id
        self.name = name
        self.priceDelta = priceDelta
    }
}

public struct CustomizationOption: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let isRequired: Bool
    public let maxSelections: Int
    public let items: [CustomizationItem]
    
    public init(id: String, title: String, isRequired: Bool, maxSelections: Int = 1, items: [CustomizationItem]) {
        self.id = id
        self.title = title
        self.isRequired = isRequired
        self.maxSelections = maxSelections
        self.items = items
    }
}

// MARK: - Menu Item
public struct MenuItem: Identifiable, Codable, Hashable {
    public let id: String
    public let restaurantId: String
    public let name: String
    public let description: String
    public let price: Double
    public let category: String
    public let calories: Int?
    public let isAvailable: Bool
    public let dietaryTags: [DietaryTag]
    public let customizationOptions: [CustomizationOption]
    public let imageName: String?
    
    public init(id: String, restaurantId: String, name: String, description: String, price: Double, category: String, calories: Int? = nil, isAvailable: Bool = true, dietaryTags: [DietaryTag] = [], customizationOptions: [CustomizationOption] = [], imageName: String? = nil) {
        self.id = id
        self.restaurantId = restaurantId
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.calories = calories
        self.isAvailable = isAvailable
        self.dietaryTags = dietaryTags
        self.customizationOptions = customizationOptions
        self.imageName = imageName
    }
}

// MARK: - Restaurant / Campus Eatery
public struct Restaurant: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let campusBuilding: String
    public let cuisineCategory: String
    public let rating: Double
    public let reviewCount: Int
    public let deliveryTimeRange: String
    public let deliveryFee: Double
    public let minOrderAmount: Double
    public let isOpen: Bool
    public let hoursDescription: String
    public let acceptsDineXtra: Bool
    public let iconSystemName: String
    public let menu: [MenuItem]
    
    public init(id: String, name: String, campusBuilding: String, cuisineCategory: String, rating: Double, reviewCount: Int, deliveryTimeRange: String, deliveryFee: Double, minOrderAmount: Double, isOpen: Bool, hoursDescription: String, acceptsDineXtra: Bool = true, iconSystemName: String = "fork.knife", menu: [MenuItem] = []) {
        self.id = id
        self.name = name
        self.campusBuilding = campusBuilding
        self.cuisineCategory = cuisineCategory
        self.rating = rating
        self.reviewCount = reviewCount
        self.deliveryTimeRange = deliveryTimeRange
        self.deliveryFee = deliveryFee
        self.minOrderAmount = minOrderAmount
        self.isOpen = isOpen
        self.hoursDescription = hoursDescription
        self.acceptsDineXtra = acceptsDineXtra
        self.iconSystemName = iconSystemName
        self.menu = menu
    }
}

// MARK: - Cart Item
public struct CartItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public let menuItem: MenuItem
    public var quantity: Int
    public var selectedOptions: [String: [CustomizationItem]] // OptionID -> Selected items
    public var specialNotes: String
    
    public init(id: UUID = UUID(), menuItem: MenuItem, quantity: Int = 1, selectedOptions: [String: [CustomizationItem]] = [:], specialNotes: String = "") {
        self.id = id
        self.menuItem = menuItem
        self.quantity = quantity
        self.selectedOptions = selectedOptions
        self.specialNotes = specialNotes
    }
    
    public var unitPrice: Double {
        var total = menuItem.price
        for items in selectedOptions.values {
            for item in items {
                total += item.priceDelta
            }
        }
        return total
    }
    
    public var totalPrice: Double {
        unitPrice * Double(quantity)
    }
}

// MARK: - Payment Method
public enum PaymentMethod: String, Codable, CaseIterable, Identifiable, Equatable {
    case dineXtra = "CMU DineXtra"
    case plaidCash = "CMU Plaid Cash"
    case applePay = "Apple Pay"
    case creditCard = "Credit / Debit Card"
    
    public var id: String { rawValue }
    
    public var iconSystemName: String {
        switch self {
        case .dineXtra: return "creditcard.fill"
        case .plaidCash: return "banknote.fill"
        case .applePay: return "apple.logo"
        case .creditCard: return "creditcard"
        }
    }

    public var iconName: String { iconSystemName }

    public var isCMUAccount: Bool {
        self == .dineXtra || self == .plaidCash
    }

    public var badgeText: String {
        switch self {
        case .dineXtra, .plaidCash:
            return "Campus account"
        case .applePay:
            return "Secure payment"
        case .creditCard:
            return "Debit or credit card"
        }
    }
}

// MARK: - Order Status
public enum OrderStatus: String, Codable, CaseIterable {
    case placed = "Order Placed"
    case preparing = "Kitchen Preparing"
    case pickedUp = "Scotty Rover Picked Up"
    case onTheWay = "On The Way to Hub"
    case arrived = "Arrived at Drop-off Hub"
    case completed = "Delivered & Picked Up"
    case cancelled = "Cancelled"
    
    public var stepIndex: Int {
        switch self {
        case .placed: return 0
        case .preparing: return 1
        case .pickedUp: return 2
        case .onTheWay: return 3
        case .arrived: return 4
        case .completed: return 5
        case .cancelled: return -1
        }
    }
    
    public var badgeColor: String {
        switch self {
        case .placed: return "blue"
        case .preparing: return "amber"
        case .pickedUp, .onTheWay: return "tartanRed"
        case .arrived, .completed: return "green"
        case .cancelled: return "gray"
        }
    }
}

// MARK: - Order
public struct Order: Identifiable, Codable {
    public let id: String
    public let orderNumber: String
    public let restaurantId: String
    public let restaurantName: String
    public let items: [CartItem]
    public let dropoffLocation: CampusLocation
    public let dropoffNotes: String
    public let subtotal: Double
    public let deliveryFee: Double
    public let studentDiscount: Double
    public let tax: Double
    public let total: Double
    public let paymentMethod: PaymentMethod
    public var status: OrderStatus
    public let createdAt: Date
    public var estimatedArrival: Date
    public let unlockPin: String
    public var currentRoverLat: Double
    public var currentRoverLng: Double
    
    public init(id: String = UUID().uuidString, orderNumber: String, restaurantId: String, restaurantName: String, items: [CartItem], dropoffLocation: CampusLocation, dropoffNotes: String, subtotal: Double, deliveryFee: Double, studentDiscount: Double, tax: Double, total: Double, paymentMethod: PaymentMethod, status: OrderStatus = .placed, createdAt: Date = Date(), estimatedArrival: Date, unlockPin: String = "4821", currentRoverLat: Double = 40.4432, currentRoverLng: Double = -79.9428) {
        self.id = id
        self.orderNumber = orderNumber
        self.restaurantId = restaurantId
        self.restaurantName = restaurantName
        self.items = items
        self.dropoffLocation = dropoffLocation
        self.dropoffNotes = dropoffNotes
        self.subtotal = subtotal
        self.deliveryFee = deliveryFee
        self.studentDiscount = studentDiscount
        self.tax = tax
        self.total = total
        self.paymentMethod = paymentMethod
        self.status = status
        self.createdAt = createdAt
        self.estimatedArrival = estimatedArrival
        self.unlockPin = unlockPin
        self.currentRoverLat = currentRoverLat
        self.currentRoverLng = currentRoverLng
    }
}

// MARK: - Student Profile
public struct StudentProfile: Codable {
    public var andrewId: String
    public var fullName: String
    public var email: String
    public var dineXtraBalance: Double
    public var plaidCashBalance: Double
    public var mealBlocksRemaining: Int
    public var favoriteDropoffId: String
    public var isAuthenticatedWithOIDC: Bool
    
    public static let sample = StudentProfile(
        andrewId: "scotty_tartan",
        fullName: "Scotty Tartan",
        email: "scotty@andrew.cmu.edu",
        dineXtraBalance: 245.50,
        plaidCashBalance: 82.00,
        mealBlocksRemaining: 14,
        favoriteDropoffId: "gates-4th",
        isAuthenticatedWithOIDC: true
    )
}
