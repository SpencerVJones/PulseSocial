//  ImageUploader.swift
//  Pulse
//  Created by Spencer Jones on 6/11/25.

import Foundation
import UIKit

enum ImageUploaderError: LocalizedError {
    case failedToEncodeImage
    case failedToReadAudioFile
    case missingCloudinaryConfig
    case invalidUploadResponse
    case uploadFailed(statusCode: Int, message: String)
    case requestFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .failedToEncodeImage:
            return "Unable to process the selected image."
        case .failedToReadAudioFile:
            return "Unable to process the selected audio."
        case .missingCloudinaryConfig:
            return "Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in Build Settings."
        case .invalidUploadResponse:
            return "Image upload failed due to an invalid response."
        case .uploadFailed(_, let message):
            return "Image upload failed: \(message)"
        case .requestFailed(let underlying):
            return "Image upload failed: \(underlying.localizedDescription)"
        }
    }
}

struct ImageUploader {
    // Safe fallback values for local development.
    // Change these if you move to a different Cloudinary environment.
    private static let fallbackCloudinaryCloudName = "dg1jeqpuz"
    private static let fallbackCloudinaryUploadPreset = "PulseUnsigned"

    private static var cloudinaryCloudName: String {
        let infoValue = (Bundle.main.object(forInfoDictionaryKey: "CLOUDINARY_CLOUD_NAME") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return infoValue.isEmpty ? fallbackCloudinaryCloudName : infoValue
    }

    private static var cloudinaryUploadPreset: String {
        let infoValue = (Bundle.main.object(forInfoDictionaryKey: "CLOUDINARY_UPLOAD_PRESET") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return infoValue.isEmpty ? fallbackCloudinaryUploadPreset : infoValue
    }

    private static var isCloudinaryConfigured: Bool {
        !cloudinaryCloudName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !cloudinaryUploadPreset.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func uploadProfileImage(_ image: UIImage) async throws -> String {
        try await uploadImage(
            image,
            folder: "profile_images",
            compressionQuality: 0.25
        )
    }

    static func uploadThreadImage(_ image: UIImage) async throws -> String {
        try await uploadImage(
            image,
            folder: "thread_images",
            compressionQuality: 0.4
        )
    }

    static func uploadThreadVoiceClip(from fileURL: URL) async throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ImageUploaderError.failedToReadAudioFile
        }

        return try await uploadBinaryData(
            data,
            folder: "thread_voice_clips",
            filename: "\(UUID().uuidString).m4a",
            mimeType: "audio/m4a",
            resourceType: "video"
        )
    }

    static func uploadCommentVoiceClip(from fileURL: URL) async throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ImageUploaderError.failedToReadAudioFile
        }

        return try await uploadBinaryData(
            data,
            folder: "comment_voice_clips",
            filename: "\(UUID().uuidString).m4a",
            mimeType: "audio/m4a",
            resourceType: "video"
        )
    }

    static func uploadChatImage(_ image: UIImage) async throws -> String {
        try await uploadImage(
            image,
            folder: "chat_images",
            compressionQuality: 0.45
        )
    }

    static func uploadChatAudio(from fileURL: URL) async throws -> String {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ImageUploaderError.failedToReadAudioFile
        }

        return try await uploadBinaryData(
            data,
            folder: "chat_audio",
            filename: "\(UUID().uuidString).m4a",
            mimeType: "audio/m4a",
            resourceType: "video"
        )
    }

    private static func uploadImage(
        _ image: UIImage,
        folder: String,
        compressionQuality: CGFloat
    ) async throws -> String {
        guard isCloudinaryConfigured else {
            throw ImageUploaderError.missingCloudinaryConfig
        }

        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw ImageUploaderError.failedToEncodeImage
        }

        return try await uploadBinaryData(
            imageData,
            folder: folder,
            filename: "\(UUID().uuidString).jpg",
            mimeType: "image/jpeg",
            resourceType: "image"
        )
    }

    private static func uploadBinaryData(
        _ binaryData: Data,
        folder: String,
        filename: String,
        mimeType: String,
        resourceType: String
    ) async throws -> String {
        let boundary = "Boundary-\(UUID().uuidString)"
        let endpoint = "https://api.cloudinary.com/v1_1/\(cloudinaryCloudName)/\(resourceType)/upload"
        guard let url = URL(string: endpoint) else {
            throw ImageUploaderError.invalidUploadResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        request.httpBody = createMultipartBody(
            binaryData: binaryData,
            boundary: boundary,
            uploadPreset: cloudinaryUploadPreset,
            folder: folder,
            filename: filename,
            mimeType: mimeType
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ImageUploaderError.requestFailed(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ImageUploaderError.invalidUploadResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let cloudinaryError = try? JSONDecoder().decode(CloudinaryErrorResponse.self, from: data)
            let message = cloudinaryError?.error.message ?? "Unexpected status code: \(httpResponse.statusCode)"
            throw ImageUploaderError.uploadFailed(statusCode: httpResponse.statusCode, message: message)
        }

        let uploadResponse = try? JSONDecoder().decode(CloudinaryUploadResponse.self, from: data)
        if let secureURL = uploadResponse?.secureURL, !secureURL.isEmpty {
            return secureURL
        }

        if let fallbackURL = uploadResponse?.url, !fallbackURL.isEmpty {
            return fallbackURL
        }

        throw ImageUploaderError.invalidUploadResponse
    }

    private static func createMultipartBody(
        binaryData: Data,
        boundary: String,
        uploadPreset: String,
        folder: String,
        filename: String,
        mimeType: String
    ) -> Data {
        var data = Data()

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n")
        data.appendString("\(uploadPreset)\r\n")

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"folder\"\r\n\r\n")
        data.appendString("\(folder)\r\n")

        data.appendString("--\(boundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.append(binaryData)
        data.appendString("\r\n")

        data.appendString("--\(boundary)--\r\n")
        return data
    }
}

private struct CloudinaryUploadResponse: Decodable {
    let secureURL: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case secureURL = "secure_url"
        case url
    }
}

private struct CloudinaryErrorResponse: Decodable {
    struct CloudinaryErrorPayload: Decodable {
        let message: String
    }

    let error: CloudinaryErrorPayload
}

private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
