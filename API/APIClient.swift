import Foundation
import UIKit

enum APIClient {
    static func authorizedRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = method

        // Se il body è JSON, setta Content-Type
        if body != nil && request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body

        // ✅ Se esiste un token, usalo. Altrimenti fai la richiesta senza.
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Token \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ Nessun token trovato → procedo senza Authorization (modalità test)")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                    logoutAndReturnToLogin()
                    return
                }

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data else {
                    completion(.failure(NSError(domain: "Nessun dato ricevuto", code: -1)))
                    return
                }

                completion(.success(data))
            }
        }.resume()
    }
}

// MARK: - Logout automatico in caso di token scaduto
func logoutAndReturnToLogin() {
    UserDefaults.standard.removeObject(forKey: "authToken")

    guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else { return }

    let loginVC = LoginViewController()

    DispatchQueue.main.async {
        sceneDelegate.window?.rootViewController = loginVC
        sceneDelegate.window?.makeKeyAndVisible()

        let alert = UIAlertController(
            title: "Sessione scaduta",
            message: "La sessione è terminata. Effettua di nuovo l’accesso.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            loginVC.present(alert, animated: true)
        }
    }
}




