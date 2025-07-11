import Foundation

struct PropertyAPI {
    static func createProperty(title: String,
                               description: String,
                               category: String,
                               completion: @escaping (Result<Int, Error>) -> Void) {
        
        guard let url = URL(string: "https://realestate360-backend.onrender.com/api/properties/") else {
            completion(.failure(NSError(domain: "URL non valida", code: -1)))
            return
        }

        let bodyDict: [String: Any] = [
            "title": title,
            "description": description,
            "category": category
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: bodyDict, options: []) else {
            completion(.failure(NSError(domain: "Errore serializzazione", code: -2)))
            return
        }

        APIClient.authorizedRequest(url: url, method: "POST", body: body) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let propertyID = json["id"] as? Int {
                        completion(.success(propertyID))
                    } else {
                        completion(.failure(NSError(domain: "Risposta non valida", code: -3)))
                    }
                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // ✅ NUOVA FUNZIONE: Recupero immagini della proprietà
    static func getImages(for propertyID: Int,
                          completion: @escaping (Result<[URL], Error>) -> Void) {

        let urlString = "https://realestate360-backend.onrender.com/api/property/\(propertyID)/images/"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URL non valida", code: -1)))
            return
        }

        APIClient.authorizedRequest(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                        let urls: [URL] = jsonArray.compactMap { dict in
                            if let path = dict["image_url"] as? String {
                                return URL(string: "http://127.0.0.1:8000" + path)
                            }
                            return nil
                        }
                        completion(.success(urls))
                    } else {
                        completion(.failure(NSError(domain: "Formato JSON non valido", code: -3)))
                    }
                } catch {
                    completion(.failure(error))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}



