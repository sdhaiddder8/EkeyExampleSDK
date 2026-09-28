import Foundation

/// The result of a completed login: the decoded ID token claims, and the KYC data payload if
/// any `ekyc-bhr-*` scopes were requested and granted.
public struct EkeyIdentityData {
    public let claims: [String: Any]
    public let kycData: [String: Any]?
}

public enum EkeyTokenExchangeError: Error {
    case network(Error)
    case badResponse
    case malformedIdToken
}

/// Performs the token exchange (integration guide §2.2.5) and KYC data fetch (§6.2) directly
/// inside the SDK. This requires `EkeyLoginConfig.clientSecret`, which — unlike everywhere else
/// in this SDK — means a secret credential ships inside the compiled app binary. See the
/// comment on `clientSecret` for why that's a deliberate trade-off here, not an oversight.
enum EkeyTokenExchange {
    static func exchangeAndFetchKyc(
        code: String,
        codeVerifier: String,
        completion: @escaping (Result<EkeyIdentityData, EkeyTokenExchangeError>) -> Void
    ) {
        var request = URLRequest(url: URL(string: EkeyLoginConfig.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let params: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "client_id": EkeyLoginConfig.clientId,
            "client_secret": EkeyLoginConfig.clientSecret,
            "code_verifier": codeVerifier,
            "redirect_uri": EkeyLoginConfig.redirectUri,
        ]
        request.httpBody = formURLEncode(params).data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(.network(error)))
                return
            }
            guard let data,
                  let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let tokenResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let idToken = tokenResponse["id_token"] as? String
            else {
                completion(.failure(.badResponse))
                return
            }

            guard let claims = decodeJWTPayload(idToken) else {
                completion(.failure(.malformedIdToken))
                return
            }

            guard
                let kycDataURLString = claims["urn:oneid:ekyc:bhr:data"] as? String,
                let kycDataURL = URL(string: kycDataURLString),
                let accessToken = tokenResponse["access_token"] as? String
            else {
                // No KYC scopes granted (or no access_token) — still a successful login, just
                // without a KYC payload to fetch.
                completion(.success(EkeyIdentityData(claims: claims, kycData: nil)))
                return
            }

            fetchKycData(url: kycDataURL, accessToken: accessToken) { kycData in
                completion(.success(EkeyIdentityData(claims: claims, kycData: kycData)))
            }
        }.resume()
    }

    private static func fetchKycData(url: URL, accessToken: String, completion: @escaping ([String: Any]?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data,
                  let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let kycData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                completion(nil)
                return
            }
            completion(kycData)
        }.resume()
    }

    /// Decodes a JWT's payload segment WITHOUT verifying its signature. Fine for reading the
    /// KYC data URL claim; per integration guide §2.2.6, a production system should still
    /// verify the signature (against eKey's JWKS), `iss`, `aud`, `exp`, and `iat` before
    /// trusting any claim as authenticated user identity. Not done here — this SDK has no JWT
    /// library dependency, and adding one is a separate decision from the token-exchange
    /// trade-off this file already makes.
    private static func decodeJWTPayload(_ jwt: String) -> [String: Any]? {
        let segments = jwt.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 += "="
        }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }
        return json
    }

    private static func formURLEncode(_ params: [String: String]) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        return params
            .map { key, value in
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
                return "\(key)=\(encodedValue)"
            }
            .joined(separator: "&")
    }
}
