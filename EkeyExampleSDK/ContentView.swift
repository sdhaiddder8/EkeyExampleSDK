//
//  ContentView.swift
//  EkeyExampleSDK
//
//  Created by Syed Danish  on 30/07/2026.
//


import SwiftUI
import UIKit
import EkeySDK

struct ContentView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, NEC testing Flow!")
                .font(.title2)
                .fontWeight(.semibold)
            Button {
                print("Initiate Ekey Flow tapped")
                initiateEkeyFlow()
            } label: {
                Text("Initiate Ekey Flow")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
            }
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.indigo],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .blue.opacity(0.4), radius: 8, y: 4)
            .padding(.horizontal, 32)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color.blue.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    private func initiateEkeyFlow() {
        guard let presenter = UIApplication.shared.topViewController else { return }
        Ekey.shared.initiateLogin(from: presenter) { result in
            switch result {
            case .completed(let redirectURL, let codeVerifier, let identity):
                print("Ekey login completed: \(redirectURL.absoluteString), codeVerifier: \(codeVerifier)")
                print("Identity claims: \(identity.claims)")
                print("KYC data: \(String(describing: identity.kycData))")
            case .cancelled:
                print("Ekey login cancelled")
            case .failed(let error):
                print("Ekey login failed: \(error)")
            }
        }
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}

#Preview {
    ContentView()
}
