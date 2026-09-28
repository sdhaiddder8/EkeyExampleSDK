import Foundation

/// All eKey 2.0 integration config lives here, inside the SDK. Consuming apps only ever call
/// `EkeySDK.shared.initiateLogin(from:completion:)` and `EkeySDK.shared.handleOpenURL(_:)` —
/// nothing to configure from the app side.
enum EkeyLoginConfig {
    static let authorizationBaseURL = "https://login.ekey.bh/oidc/auth"
    static let tokenURL = "https://login.ekey.bh/oidc/token"
    static let clientId = "ugiTHWoHreu2j8nACiBQV"
    // Embedding this in the SDK means it ships inside the compiled app binary and can be
    // extracted by anyone with the .ipa (e.g. via `strings` on the framework, same as this
    // SDK's own client_id/config values are trivially readable today). This is a deliberate,
    // explicitly-requested trade-off, not an oversight — see EkeyTokenExchange.swift for what
    // it's used for.
    static let clientSecret = "xbYcRWjAuWpWuyc1N7hhrXycGolrgA1xFbAykNuMkUyCjWQdEHWd0OMTucYUZjKvqnf9upvdzksB-fZf8mFoBw"
    static let redirectUri = "https://mobileapp.necremit.com/beyon/WS_MobileAPICALLS.asmx"
    static let scope = "openid id-* id-*-additional id-*-photo ekyc-bhr-name ekyc-bhr-address " +
        "ekyc-bhr-birth ekyc-bhr-nationality ekyc-bhr-contact ekyc-bhr-employment " +
        "ekyc-bhr-passport ekyc-bhr-resident ekyc-bhr-photo ekyc-bhr-disability " +
        "liveness_proof liveness_photo"
    static let customURLScheme = "necekey"
    static let focusUri = "\(customURLScheme)://callback"

    // Per the integration guide's Environments section: production's App-to-App launch
    // domain is app.ekey.bh, while the test/UAT environment (used here) hands the
    // mobileLogin URL back on tools.test.ekey-b.com instead.
    static let appToAppDomains = ["app.ekey.bh", "tools.ekey-b.com"]
}
