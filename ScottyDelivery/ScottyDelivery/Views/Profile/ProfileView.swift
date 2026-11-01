import SwiftUI

public struct ProfileView: View {
    @ObservedObject private var authService = AuthService.shared
    @State private var showingSignInSheet: Bool = false
    @State private var showingAboutSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Student Identity Card
                    studentProfileCard
                    
                    // MARK: - CMU Dining Account Balances
                    cmuDiningFundsCard
                    
                    // MARK: - Delivery Preferences
                    deliveryPreferencesCard
                    
                    // MARK: - ScottyLabs & Open Source Info
                    scottyLabsInfoCard
                    
                    // MARK: - Account Actions
                    accountActionsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 60)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showingSignInSheet) {
                AndrewIDSignInSheet()
            }
            .sheet(isPresented: $showingAboutSheet) {
                AboutScottyLabsSheet()
            }
        }
    }
    
    // MARK: - Student Profile Card
    private var studentProfileCard: some View {
        ShadcnCard(padding: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.tartanRed)
                        .frame(width: 58, height: 58)
                    
                    Text("ST")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(authService.currentUser?.fullName ?? "CMU Tartan")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.appForeground)
                        
                        ShadcnBadge("CMU Student", variant: .tartan)
                    }
                    
                    Text(authService.currentUser?.email ?? "scotty@andrew.cmu.edu")
                        .font(.caption)
                        .foregroundColor(Color.appMutedForeground)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color.appSuccess)
                        Text("Verified Andrew ID SSO")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.appSuccess)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - CMU Dining Funds Card
    private var cmuDiningFundsCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(Color.tartanRed)
                    Text("CMU Campus Dining Funds")
                        .font(.headline)
                        .foregroundColor(Color.appForeground)
                    Spacer()
                }
                
                ShadcnSeparator()
                
                HStack(spacing: 12) {
                    FundCell(
                        title: "DineXtra",
                        amount: String(format: "$%.2f", authService.currentUser?.dineXtraBalance ?? 0.0),
                        subtitle: "Tax-free campus dining"
                    )
                    
                    Divider().frame(height: 40)
                    
                    FundCell(
                        title: "Plaid Cash",
                        amount: String(format: "$%.2f", authService.currentUser?.plaidCashBalance ?? 0.0),
                        subtitle: "General debit"
                    )
                    
                    Divider().frame(height: 40)
                    
                    FundCell(
                        title: "Meal Blocks",
                        amount: "\(authService.currentUser?.mealBlocksRemaining ?? 0)",
                        subtitle: "Remaining this week"
                    )
                }
            }
        }
    }
    
    // MARK: - Preferences Card
    private var deliveryPreferencesCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Delivery Preferences")
                    .font(.headline)
                    .foregroundColor(Color.appForeground)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Default Drop-off Hub")
                            .font(.subheadline)
                            .foregroundColor(Color.appForeground)
                        Text("Gates-Hillman Center (4th Fl)")
                            .font(.caption)
                            .foregroundColor(Color.appMutedForeground)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.appMutedForeground)
                }
                
                ShadcnSeparator()
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dietary Filters & Allergies")
                            .font(.subheadline)
                            .foregroundColor(Color.appForeground)
                        Text("Halal, Vegetarian, Nut-Free options highlighted")
                            .font(.caption)
                            .foregroundColor(Color.appMutedForeground)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(Color.appMutedForeground)
                }
            }
        }
    }
    
    // MARK: - ScottyLabs Info Card
    private var scottyLabsInfoCard: some View {
        ShadcnCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(Color.tartanRed)
                    Text("ScottyLabs Labrador")
                        .font(.headline)
                        .foregroundColor(Color.appForeground)
                    Spacer()
                    ShadcnBadge("CMU 0->1", variant: .secondary)
                }
                
                Text("Scotty Delivery is an on-campus food delivery initiative built by ScottyLabs Labrador developers, serving students, faculty, and staff of Carnegie Mellon University.")
                    .font(.caption)
                    .foregroundColor(Color.appMutedForeground)
                    .lineSpacing(2)
                
                Button(action: { showingAboutSheet = true }) {
                    Text("View Architecture & Documentation →")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color.tartanRed)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Account Actions
    private var accountActionsSection: some View {
        VStack(spacing: 8) {
            Button(action: { showingSignInSheet = true }) {
                Text("Switch Andrew ID Account")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.tartanRed)
            }
            .padding(.top, 4)
            
            Text("ScottyDelivery for iOS • Version 1.0 (Build 1)")
                .font(.system(size: 11))
                .foregroundColor(Color.appMutedForeground)
                .padding(.top, 4)
        }
    }
}

// MARK: - Fund Cell Subview
struct FundCell: View {
    let title: String
    let amount: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.appMutedForeground)
            Text(amount)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color.appForeground)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(Color.appMutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Andrew ID Sign In Sheet
struct AndrewIDSignInSheet: View {
    @ObservedObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var andrewId: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.tartanRed)
                    
                    Text("CMU Andrew ID SSO")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Log in with your official Carnegie Mellon credentials via Keycloak OIDC.")
                        .font(.subheadline)
                        .foregroundColor(Color.appMutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                VStack(spacing: 12) {
                    ShadcnInput("Andrew ID (e.g. jdoe)", text: $andrewId, icon: "person.fill")
                    
                    SecureField("Password", text: $password)
                        .padding(.horizontal, 14)
                        .frame(height: 44)
                        .background(Color.appCard)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appCardBorder, lineWidth: 1))
                }
                .padding(.horizontal, 20)
                
                ShadcnButton(
                    "Sign In with OIDC",
                    icon: "arrow.right.circle.fill",
                    variant: .tartan,
                    isLoading: authService.isLoading
                ) {
                    Task {
                        _ = await authService.signInWithAndrewID(andrewId: andrewId, password: password)
                        dismiss()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("CMU Authentication")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - About ScottyLabs Sheet
struct AboutScottyLabsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("About ScottyDelivery")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Scotty Delivery is developed under the ScottyLabs Labrador incubator at Carnegie Mellon University. It provides on-campus automated and student courier delivery directly connecting campus dining halls with academic centers and dormitories.")
                        .font(.subheadline)
                        .foregroundColor(Color.appMutedForeground)
                        .lineSpacing(3)
                    
                    ShadcnSeparator()
                    
                    Text("Technical Architecture")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TechSpecRow(title: "Platform", detail: "Native iOS (SwiftUI, iPhone 17 Optimized)")
                        TechSpecRow(title: "Design System", detail: "shadcn/ui zinc aesthetic + CMU Tartan Red")
                        TechSpecRow(title: "Authentication", detail: "OpenID Connect + Keycloak (idp.scottylabs.org)")
                        TechSpecRow(title: "API Backend", detail: "ScottyStack Express + TSOA OpenAPI Specs")
                        TechSpecRow(title: "Maps & Telemetry", detail: "MapKit GPS route interpolation")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Technical Overview")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TechSpecRow: View {
    let title: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.appMutedForeground)
            Text(detail)
                .font(.subheadline)
                .foregroundColor(Color.appForeground)
        }
        .padding(.vertical, 2)
    }
}

