import UIKit

final class EkeyLoginViewController: UIViewController {
    let webViewController: EkeyWebViewController
    private let onCancelled: () -> Void

    init(
        onCompleted: @escaping (URL, String, EkeyIdentityData) -> Void,
        onFailed: @escaping (EkeyLoginError) -> Void,
        onCancelled: @escaping () -> Void
    ) {
        self.onCancelled = onCancelled
        webViewController = EkeyWebViewController(onCompleted: onCompleted, onFailed: onFailed)
        super.init(nibName: nil, bundle: nil)
        title = "Ekey Login"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = webViewController.webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webViewController.start()
    }

    @objc private func closeTapped() {
        onCancelled()
    }
}
