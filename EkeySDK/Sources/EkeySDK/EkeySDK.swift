import UIKit

/// Entry point for the eKey 2.0 app-to-app login SDK. All integration config (client_id,
/// redirect_uri, scope, endpoints, custom URL scheme) lives inside the SDK — the app only
/// calls these two entry points.
///
/// Usage:
/// ```swift
/// // Forward every URL open (SwiftUI's .onOpenURL, or UIKit's application(_:open:options:)):
/// Ekey.shared.handleOpenURL(url)
///
/// // Start the flow from any UIViewController:
/// Ekey.shared.initiateLogin(from: viewController) { result in
///     switch result {
///     case .completed(let redirectURL, let codeVerifier, let identity):
///         // identity.claims / identity.kycData already have the login's identity data —
///         // the SDK completed the token exchange and KYC fetch internally.
///     case .cancelled:
///         break
///     case .failed(let error):
///         // e.g. .stateMismatch — reject the login, do not treat as success.
///     }
/// }
/// ```
public final class Ekey {
    public static let shared = Ekey()

    private weak var activeWebViewController: EkeyWebViewController?
    private weak var presentedViewController: UIViewController?

    private init() {}

    /// Presents the eKey login flow modally from `viewController`.
    public func initiateLogin(
        from viewController: UIViewController,
        completion: @escaping (EkeyLoginResult) -> Void
    ) {
        let loginViewController = EkeyLoginViewController(
            onCompleted: { [weak self] url, codeVerifier, identity in
                self?.finish {
                    completion(.completed(redirectURL: url, codeVerifier: codeVerifier, identity: identity))
                }
            },
            onFailed: { [weak self] error in
                self?.finish { completion(.failed(error)) }
            },
            onCancelled: { [weak self] in
                self?.finish { completion(.cancelled) }
            }
        )

        activeWebViewController = loginViewController.webViewController
        let navigationController = UINavigationController(rootViewController: loginViewController)
        navigationController.modalPresentationStyle = .fullScreen
        presentedViewController = navigationController
        viewController.present(navigationController, animated: true)
    }

    /// Forward every `onOpenURL` (SwiftUI) / `application(_:open:options:)` (UIKit) call here.
    /// Returns true if the URL was this SDK's `focus_uri` callback and was handled.
    @discardableResult
    public func handleOpenURL(_ url: URL) -> Bool {
        guard url.scheme == EkeyLoginConfig.customURLScheme else {
            return false
        }
        activeWebViewController?.resume()
        return true
    }

    private func finish(_ completion: @escaping () -> Void) {
        presentedViewController?.dismiss(animated: true, completion: completion)
        presentedViewController = nil
        activeWebViewController = nil
    }
}
