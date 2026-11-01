import SwiftUI

public struct WelcomeView: View {
    let onContinue: () -> Void
    @State private var showingSSOSheet: Bool = false
    @ObservedObject private var authService = AuthService.shared

    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // MARK: - Scotty Mascot Hero
                VStack(spacing: 16) {
                    Image("scotty_hello")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .background(
                            Circle()
                                .fill(Color.tartanRed.opacity(0.1))
                                .frame(width: 170, height: 170)
                        )

                    VStack(spacing: 6) {
                        Text("Scotty Delivery")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.appForeground)

                        Text("Scotty Got It. From Campus to You.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color.tartanRed)
                    }

                    Text("Autonomous campus dining delivery connecting Carnegie Mellon eateries directly to your academic building or residence hall.")
                        .font(.subheadline)
                        .foregroundColor(Color.appMutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(3)
                }

                // MARK: - Highlights Grid
                VStack(spacing: 12) {
                    FeatureHighlightRow(
                        icon: "creditcard.fill",
                        title: "CMU Dining Integrated",
                        description: "Pay tax-free using your DineXtra, Plaid Cash, or student debit."
                    )
                    FeatureHighlightRow(
                        icon: "mappin.and.ellipse",
                        title: "10+ Campus Hubs",
                        description: "Delivering to Gates, Cohon Center, Tepper, Resnik, and libraries."
                    )
                    FeatureHighlightRow(
                        icon: "lock.shield.fill",
                        title: "PIN-Protected Rovers",
                        description: "Your food stays hot in insulated compartments unlocked only by your phone."
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // MARK: - Actions
                VStack(spacing: 12) {
                    ShadcnButton(
                        "Sign In with Andrew ID SSO",
                        icon: "key.fill",
                        variant: .tartan
                    ) {
                        showingSSOSheet = true
                    }

                    Button(action: onContinue) {
                        Text("Continue as Campus Guest")
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
        .sheet(isPresented: $showingSSOSheet) {
            AndrewIDSignInSheet()
                .onDisappear {
                    if authService.isAuthenticated {
                        onContinue()
                    }
                }
        }
    }
}

struct FeatureHighlightRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.tartanRed.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.tartanRed)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.appForeground)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appMutedForeground)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.appCard)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appCardBorder, lineWidth: 1))
    }
}

