import UIKit

struct ImageUploader {
    static func upload(image: UIImage,
                       to propertyID: Int,
                       completion: @escaping (Result<URL, Error>) -> Void) {
        
        // ✅ Validazione ID
        guard propertyID > 0 else {
            completion(.failure(NSError(domain: "InvalidPropertyID", code: -1)))
            return
        }
        
        // 🔗 URL corretto
        let urlString = "https://realestate360-backend-vv8d.onrender.com/api/properties/\(propertyID)/upload_image/"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0)))
            return
        }

        // 🔧 Crea multipart form-data
        let boundary = UUID().uuidString
        var data = Data()

        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"image\"; filename=\"panorama.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(image.jpegData(compressionQuality: 0.8)!)
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // 🔁 Upload con token
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        APIClient.authorizedRequest(url: url, method: "POST", body: data) { result in
            switch result {
            case .success(let responseData):
                guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                      let path = json["image_url"] as? String,
                      let imageURL = URL(string: "https://realestate360-backend-vv8d.onrender.com" + path) else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: 1)))
                    return
                }
                completion(.success(imageURL))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}







