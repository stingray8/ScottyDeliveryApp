import SwiftUI

// MARK: - Design Tokens & shadcn/ui Inspired Palette
extension Color {
    // Primary Brand - Tartan Red (ScottyLabs / CMU signature)
    static let tartanRed      = Color(red: 0.769, green: 0.071, blue: 0.188) // #C41230
    static let tartanRedDark  = Color(red: 0.600, green: 0.040, blue: 0.130)
    static let tartanRedLight = Color(red: 0.980, green: 0.920, blue: 0.930)

    // shadcn zinc scale
    static let zinc50  = Color(red: 0.980, green: 0.980, blue: 0.980)
    static let zinc100 = Color(red: 0.957, green: 0.957, blue: 0.961)
    static let zinc200 = Color(red: 0.894, green: 0.894, blue: 0.906)
    static let zinc300 = Color(red: 0.831, green: 0.831, blue: 0.847)
    static let zinc400 = Color(red: 0.631, green: 0.631, blue: 0.667)
    static let zinc500 = Color(red: 0.443, green: 0.443, blue: 0.478)
    static let zinc600 = Color(red: 0.322, green: 0.322, blue: 0.353)
    static let zinc700 = Color(red: 0.247, green: 0.247, blue: 0.278)
    static let zinc800 = Color(red: 0.153, green: 0.153, blue: 0.165)
    static let zinc900 = Color(red: 0.094, green: 0.094, blue: 0.106)
    static let zinc950 = Color(red: 0.035, green: 0.035, blue: 0.043)

    // MARK: - Semantic shadcn tokens (light / dark adaptive via SwiftUI)
    // These are resolved at render time using the .colorScheme environment,
    // so no UIKit dependency is required.
    static let appBackground     = Color("AppBackground")
    static let appCard           = Color("AppCard")
    static let appCardBorder     = Color("AppCardBorder")
    static let appMuted          = Color("AppMuted")
    static let appMutedForeground = Color("AppMutedForeground")
    static let appForeground     = Color("AppForeground")

    static let appSuccess = Color(red: 0.086, green: 0.639, blue: 0.290) // #16A34A (Emerald)
    static let appWarning = Color(red: 0.851, green: 0.467, blue: 0.024) // #D97706 (Amber)
    static let appInfo    = Color(red: 0.098, green: 0.463, blue: 0.824)
}

