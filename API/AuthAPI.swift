import Foundation

struct AuthAPI {
    static func login(username: String, password: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://realestate360-backend-vv8d.onrender.com/api/token-auth/") else {
            completion(.failure(NSError(domain: "URL non valida", code: -1)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "username": username,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let token = json["token"] as? String else {
                completion(.failure(NSError(domain: "Risposta non valida", code: -3)))
                return
            }

            completion(.success(token))
        }.resume()
    }
}



