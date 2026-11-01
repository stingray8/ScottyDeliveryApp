import SwiftUI

public struct ExploreView: View {
    @ObservedObject private var cartManager = CartManager.shared
    @State private var restaurants: [Restaurant] = []
    @State private var campusHubs: [CampusLocation] = []
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"
    @State private var filterOpenOnly: Bool = false
    @State private var filterDineXtraOnly: Bool = false
    @State private var showingHubPickerSheet: Bool = false
    @State private var selectedRestaurant: Restaurant?
    
    private let categories = ["All", "Sandwiches & Coffee", "Indian & Curry Bowls", "Burgers, Tenders & Fries", "Artisan Coffee & Bowls", "Grab & Go, Snacks & Boba"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Delivery Destination Header
                    dropoffHubHeader
                    
                    // MARK: - Scotty Mascot Hero Banner
                    scottyHeroBanner
                    
                    // MARK: - Search & Filters
                    searchAndFilterSection
                    
                    // MARK: - Category Pills
                    categoryPillsRow
                    
                    // MARK: - Eateries List
                    eateriesListSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90) // Extra padding for tab bar / floating cart
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("ScottyDelivery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "dog.fill")
                        .foregroundColor(Color.tartanRed)
                        .font(.system(size: 18))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if cartManager.itemCount > 0 {
                        NavigationLink(destination: CartView()) {
                            HStack(spacing: 4) {
                                Image(systemName: "bag.fill")
                                Text("\(cartManager.itemCount)")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 13))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.tartanRed)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHubPickerSheet) {
                HubPickerSheet(selectedHub: $cartManager.selectedDropoffHub, hubs: campusHubs)
            }
            .navigationDestination(item: $selectedRestaurant) { restaurant in
                RestaurantDetailView(restaurant: restaurant)
            }
            .task {
                self.restaurants = await APIClient.shared.fetchRestaurants()
                self.campusHubs = await APIClient.shared.fetchCampusHubs()
            }
        }
    }
    
    // MARK: - Dropoff Hub Header
    private var dropoffHubHeader: some View {
        Button(action: { showingHubPickerSheet = true }) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(Color.tartanRed)
                    .font(.system(size: 14, weight: .bold))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("DELIVERY LOCATION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.appMutedForeground)
                        .tracking(0.5)
                    
                    HStack(spacing: 4) {
                        Text(cartManager.selectedDropoffHub.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.appForeground)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.appMutedForeground)
                    }
                }
                
                Spacer()
                
                ShadcnBadge(
                    "~\(cartManager.selectedDropoffHub.estimatedMinutesFromCenter) min",
                    icon: "clock.fill",
                    variant: .tartan
                )
            }
            .padding(12)
            .background(Color.appCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Scotty Mascot Hero Banner
    private var scottyHeroBanner: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [Color.tartanRed, Color(red: 0.58, green: 0.04, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(16)
            
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11))
                        Text("ON-CAMPUS DELIVERY")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                    }
                    .foregroundColor(Color.white.opacity(0.85))
                    
                    Text("Scotty Got It.\nFrom Campus to You.")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(2)
                    
                    Text("Autonomous & student courier delivery straight to your CMU hall or library.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.85))
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label("DineXtra Accepted", systemImage: "creditcard.fill")
                        Label("Live Rover GPS", systemImage: "location.fill")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 4)
                }
                .padding(.vertical, 16)
                .padding(.leading, 18)
                
                Spacer()
                
                // Mascot graphic
                Image("scotty_hello")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 95, height: 95)
                    .padding(.trailing, 12)
                    .padding(.bottom, 8)
            }
        }
        .frame(height: 150)
        .shadow(color: Color.tartanRed.opacity(0.2), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Search & Filters
    private var searchAndFilterSection: some View {
        VStack(spacing: 10) {
            ShadcnInput("Search restaurants, coffee, bowls, snacks...", text: $searchQuery, icon: "magnifyingglass")
            
            HStack(spacing: 8) {
                ToggleChip(title: "Open Now", isSelected: $filterOpenOnly, icon: "clock")
                ToggleChip(title: "DineXtra", isSelected: $filterDineXtraOnly, icon: "creditcard")
                Spacer()
            }
        }
    }
    
    // MARK: - Category Pills
    private var categoryPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button(action: { selectedCategory = cat }) {
                        Text(cat)
                            .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.tartanRed : Color.appCard)
                            .foregroundColor(isSelected ? .white : Color.appForeground)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isSelected ? Color.clear : Color.appCardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Filtered Restaurants
    private var filteredRestaurants: [Restaurant] {
        restaurants.filter { rest in
            let matchesSearch = searchQuery.isEmpty ||
                rest.name.localizedCaseInsensitiveContains(searchQuery) ||
                rest.campusBuilding.localizedCaseInsensitiveContains(searchQuery) ||
                rest.cuisineCategory.localizedCaseInsensitiveContains(searchQuery) ||
                rest.menu.contains { $0.name.localizedCaseInsensitiveContains(searchQuery) }
            
            let matchesCategory = selectedCategory == "All" || rest.cuisineCategory.contains(selectedCategory)
            let matchesOpen = !filterOpenOnly || rest.isOpen
            let matchesDineXtra = !filterDineXtraOnly || rest.acceptsDineXtra
            
            return matchesSearch && matchesCategory && matchesOpen && matchesDineXtra
        }
    }
    
    // MARK: - Eateries List Section
    private var eateriesListSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Campus Eateries")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.appForeground)
                
                Spacer()
                
                Text("\(filteredRestaurants.count) available")
                    .font(.system(size: 12))
                    .foregroundColor(Color.appMutedForeground)
            }
            
            if filteredRestaurants.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(Color.appMutedForeground)
                    Text("No eateries found matching your search")
                        .font(.subheadline)
                        .foregroundColor(Color.appMutedForeground)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(filteredRestaurants) { restaurant in
                    RestaurantCard(restaurant: restaurant) {
                        self.selectedRestaurant = restaurant
                    }
                }
            }
        }
    }
}

// MARK: - Toggle Chip Component
struct ToggleChip: View {
    let title: String
    @Binding var isSelected: Bool
    let icon: String
    
    var body: some View {
        Button(action: { isSelected.toggle() }) {
            HStack(spacing: 5) {
                Image(systemName: isSelected ? "checkmark" : icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.tartanRed.opacity(0.12) : Color.appCard)
            .foregroundColor(isSelected ? Color.tartanRed : Color.appMutedForeground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.tartanRed : Color.appCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Restaurant Card Component
struct RestaurantCard: View {
    let restaurant: Restaurant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ShadcnCard(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        // Icon circle
                        ZStack {
                            Circle()
                                .fill(Color.tartanRed.opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: restaurant.iconSystemName)
                                .font(.system(size: 22))
                                .foregroundColor(Color.tartanRed)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(restaurant.name)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.appForeground)
                                
                                Spacer()
                                
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 11))
                                    Text(String(format: "%.1f", restaurant.rating))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.appForeground)
                                    Text("(\(restaurant.reviewCount))")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.appMutedForeground)
                                }
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 11))
                                Text(restaurant.campusBuilding)
                                    .font(.subheadline)
                            }
                            .foregroundColor(Color.appMutedForeground)
                            
                            Text(restaurant.cuisineCategory)
                                .font(.caption)
                                .foregroundColor(Color.appMutedForeground)
                        }
                    }
                    
                    ShadcnSeparator()
                    
                    // Metadata bar
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                            Text(restaurant.deliveryTimeRange)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color.appForeground)
                        
                        Text("•")
                            .foregroundColor(Color.appCardBorder)
                        
                        Text(restaurant.deliveryFee == 0 ? "Free Delivery" : String(format: "$%.2f delivery", restaurant.deliveryFee))
                            .font(.system(size: 12))
                            .foregroundColor(Color.appMutedForeground)
                        
                        Spacer()
                        
                        if restaurant.acceptsDineXtra {
                            ShadcnBadge("DineXtra", icon: "creditcard", variant: .success)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Campus Hub Picker Sheet
struct HubPickerSheet: View {
    @Binding var selectedHub: CampusLocation
    let hubs: [CampusLocation]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("CMU Campus Drop-off Hubs")) {
                    ForEach(hubs) { hub in
                        Button(action: {
                            selectedHub = hub
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(hub.name)
                                            .font(.headline)
                                            .foregroundColor(Color.appForeground)
                                        if hub.isPopular {
                                            ShadcnBadge("Popular", variant: .tartan)
                                        }
                                    }
                                    Text("\(hub.building) — \(hub.roomOrZone)")
                                        .font(.caption)
                                        .foregroundColor(Color.appMutedForeground)
                                }
                                
                                Spacer()
                                
                                if selectedHub.id == hub.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.tartanRed)
                                        .font(.title3)
                                } else {
                                    Text("~\(hub.estimatedMinutesFromCenter) min")
                                        .font(.caption)
                                        .foregroundColor(Color.appMutedForeground)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Select Delivery Hub")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

