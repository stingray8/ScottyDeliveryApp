import SwiftUI

public struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @ObservedObject private var cartManager = CartManager.shared
    @State private var selectedMenuItem: MenuItem?
    @State private var selectedCategory: String = "All"
    @State private var showingAddedToast: Bool = false
    @State private var toastMessage: String = ""
    
    public init(restaurant: Restaurant) {
        self.restaurant = restaurant
    }
    
    private var menuCategories: [String] {
        var cats = ["All"]
        let unique = Array(Set(restaurant.menu.map { $0.category })).sorted()
        cats.append(contentsOf: unique)
        return cats
    }
    
    private var filteredMenu: [MenuItem] {
        if selectedCategory == "All" {
            return restaurant.menu
        }
        return restaurant.menu.filter { $0.category == selectedCategory }
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Header Hero
                    restaurantHeaderCard
                    
                    // MARK: - Menu Category Tabs
                    categoryTabs
                    
                    // MARK: - Menu Items List
                    VStack(spacing: 12) {
                        ForEach(filteredMenu) { item in
                            MenuItemRow(item: item) {
                                if item.customizationOptions.isEmpty {
                                    // Quick add
                                    cartManager.addItem(item, restaurantName: restaurant.name)
                                    showToast("Added \(item.name) to Bag")
                                } else {
                                    // Open customizer sheet
                                    selectedMenuItem = item
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, cartManager.itemCount > 0 ? 100 : 40)
            }
            .background(Color.appBackground.ignoresSafeArea())
            
            // Floating Checkout Pill
            if cartManager.itemCount > 0 {
                floatingCartBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            
            // Toast notification
            if showingAddedToast {
                toastView
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(restaurant.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(item: $selectedMenuItem) { item in
            MenuItemDetailSheet(item: item, restaurantName: restaurant.name) {
                showToast("Added \(item.name) to Bag")
            }
        }
    }
    
    // MARK: - Header Card
    private var restaurantHeaderCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appForeground)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 13))
                            Text(restaurant.campusBuilding)
                                .font(.subheadline)
                        }
                        .foregroundColor(Color.appMutedForeground)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 13))
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appForeground)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appMuted)
                    .cornerRadius(8)
                }
                
                ShadcnSeparator()
                
                HStack(spacing: 16) {
                    HStack(spacing: 5) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color.tartanRed)
                            .font(.system(size: 13))
                        Text(restaurant.deliveryTimeRange)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 5) {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(Color.appMutedForeground)
                            .font(.system(size: 13))
                        Text(restaurant.deliveryFee == 0 ? "Free Delivery" : String(format: "$%.2f Fee", restaurant.deliveryFee))
                            .font(.caption)
                    }
                    
                    if restaurant.acceptsDineXtra {
                        ShadcnBadge("DineXtra", icon: "creditcard", variant: .success)
                    }
                }
            }
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(menuCategories, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button(action: { selectedCategory = cat }) {
                        Text(cat)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isSelected ? Color.appForeground : Color.appCard)
                            .foregroundColor(isSelected ? Color.appBackground : Color.appForeground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appCardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Floating Cart Bar
    private var floatingCartBar: some View {
        NavigationLink(destination: CartView()) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 32, height: 32)
                        Text("\(cartManager.itemCount)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("View Bag")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Delivering to \(cartManager.selectedDropoffHub.name)")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.85))
                    }
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text(String(format: "$%.2f", cartManager.total))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 58)
            .background(Color.tartanRed)
            .cornerRadius(16)
            .shadow(color: Color.tartanRed.opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Toast
    private var toastView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color.appSuccess)
            Text(toastMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.appForeground)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.appCard)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.appCardBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func showToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring()) { showingAddedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut) { showingAddedToast = false }
        }
    }
}

// MARK: - Menu Item Row
struct MenuItemRow: View {
    let item: MenuItem
    let onAdd: () -> Void
    
    var body: some View {
        ShadcnCard(padding: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(item.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appForeground)
                        
                        ForEach(item.dietaryTags) { tag in
                            ShadcnBadge(tag.rawValue, icon: tag.iconName, variant: .secondary)
                        }
                    }
                    
                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(Color.appMutedForeground)
                        .lineLimit(2)
                    
                    HStack(spacing: 10) {
                        Text(String(format: "$%.2f", item.price))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.tartanRed)
                        
                        if let cal = item.calories {
                            Text("\(cal) cal")
                                .font(.caption)
                                .foregroundColor(Color.appMutedForeground)
                        }
                    }
                    .padding(.top, 2)
                }
                
                Spacer()
                
                // Add Button
                Button(action: onAdd) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.tartanRed.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.tartanRed)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Menu Item Customizer Sheet
struct MenuItemDetailSheet: View {
    let item: MenuItem
    let restaurantName: String
    let onAdded: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity: Int = 1
    @State private var selectedOptions: [String: [CustomizationItem]] = [:]
    @State private var specialNotes: String = ""
    
    private var currentTotal: Double {
        var price = item.price
        for list in selectedOptions.values {
            for opt in list {
                price += opt.priceDelta
            }
        }
        return price * Double(quantity)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appForeground)
                        
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundColor(Color.appMutedForeground)
                        
                        Text(String(format: "$%.2f", item.price))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color.tartanRed)
                    }
                    
                    ShadcnSeparator()
                    
                    // Options
                    ForEach(item.customizationOptions) { option in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(option.title)
                                    .font(.headline)
                                    .foregroundColor(Color.appForeground)
                                
                                if option.isRequired {
                                    ShadcnBadge("Required", variant: .tartan)
                                }
                            }
                            
                            ForEach(option.items) { choice in
                                let isSelected = selectedOptions[option.id]?.contains(where: { $0.id == choice.id }) ?? false
                                
                                Button(action: {
                                    toggleChoice(choice, in: option)
                                }) {
                                    HStack {
                                        Text(choice.name)
                                            .font(.subheadline)
                                            .foregroundColor(Color.appForeground)
                                        
                                        Spacer()
                                        
                                        if choice.priceDelta > 0 {
                                            Text(String(format: "+$%.2f", choice.priceDelta))
                                                .font(.caption)
                                                .foregroundColor(Color.appMutedForeground)
                                        }
                                        
                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isSelected ? Color.tartanRed : Color.appCardBorder)
                                            .font(.title3)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                        ShadcnSeparator()
                    }
                    
                    // Special Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Special Instructions")
                            .font(.headline)
                            .foregroundColor(Color.appForeground)
                        
                        TextField("e.g. Dressing on the side, extra napkins", text: $specialNotes)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Quantity Stepper
                    HStack {
                        Text("Quantity")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button(action: { if quantity > 1 { quantity -= 1 } }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(quantity > 1 ? Color.tartanRed : Color.appMutedForeground)
                            }
                            
                            Text("\(quantity)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .frame(minWidth: 24)
                            
                            Button(action: { quantity += 1 }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color.tartanRed)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Customize Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack {
                    ShadcnButton(
                        String(format: "Add to Bag • $%.2f", currentTotal),
                        icon: "bag.fill",
                        variant: .tartan
                    ) {
                        CartManager.shared.addItem(
                            item,
                            quantity: quantity,
                            options: selectedOptions,
                            notes: specialNotes,
                            restaurantName: restaurantName
                        )
                        dismiss()
                        onAdded()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.appCard)
                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.appCardBorder), alignment: .top)
            }
        }
        .onAppear {
            // Preselect required first item
            for option in item.customizationOptions where option.isRequired {
                if let first = option.items.first {
                    selectedOptions[option.id] = [first]
                }
            }
        }
    }
    
    private func toggleChoice(_ choice: CustomizationItem, in option: CustomizationOption) {
        if option.maxSelections == 1 {
            selectedOptions[option.id] = [choice]
        } else {
            var current = selectedOptions[option.id] ?? []
            if let idx = current.firstIndex(where: { $0.id == choice.id }) {
                current.remove(at: idx)
            } else {
                current.append(choice)
            }
            selectedOptions[option.id] = current
        }
    }
}

