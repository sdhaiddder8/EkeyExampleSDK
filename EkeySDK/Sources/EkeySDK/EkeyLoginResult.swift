import Foundation

public enum EkeyLoginResult {
    /// The WebView reached the configured redirect_uri, its `state` matched the one this SDK
    /// generated for the request, and the SDK completed the token exchange (integration guide
    /// §2.2.5) and KYC data fetch (§6.2) on your behalf. `redirectURL` and `codeVerifier` are
    /// still included for reference/audit purposes, but `identity` already has everything the
    /// app needs — the decoded ID token claims, and the KYC data payload if KYC scopes were
    /// granted.
    case completed(redirectURL: URL, codeVerifier: String, identity: EkeyIdentityData)

    /// The user dismissed the login screen before completing the flow.
    case cancelled

    /// The flow reached redirect_uri but failed validation and was not treated as a
    /// successful login.
    case failed(EkeyLoginError)
}

public enum EkeyLoginError: Error {
    /// redirect_uri's `state` parameter was missing or didn't match the `state` this SDK
    /// generated for the original authorization request — a possible CSRF/session-mixup,
    /// so the result is rejected rather than treated as a successful login.
    case stateMismatch

    /// The redirect/state check passed, but the token exchange or KYC data fetch that the SDK
    /// performs internally afterward failed (network error, or eKey's server rejected the
    /// request/returned something unexpected).
    case tokenExchangeFailed(EkeyTokenExchangeError)
}
